import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../constants/app_colors.dart';
import '../models/system_sizing_params.dart';
import '../services/solar_calculation_service.dart';
import '../services/solar_radiation_service.dart';
import '../widgets/theme_toggle_button.dart';

class CurrencyService {
  static double _cachedUsdToBdt = 120.0;
  static DateTime? _lastFetchTime;

  static Future<double> getUsdToBdtRate() async {
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inHours < 12) {
      return _cachedUsdToBdt;
    }

    try {
      final url = Uri.parse('https://open.er-api.com/v6/latest/USD');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = data['rates']?['BDT'];
        if (rate != null) {
          _cachedUsdToBdt = (rate as num).toDouble();
          _lastFetchTime = DateTime.now();
        }
      }
    } catch (_) {}
    return _cachedUsdToBdt;
  }
}

class CurrencyFormatter {
  static String formatBdt(num amount, {bool showSymbol = true}) {
    final int rounded = amount.round();
    final String str = rounded.toString();

    String formatted;
    if (str.length <= 3) {
      formatted = str;
    } else {
      final String lastThree = str.substring(str.length - 3);
      final String remaining = str.substring(0, str.length - 3);

      final String formattedRemaining = remaining.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      formatted = '$formattedRemaining,$lastThree';
    }

    return showSymbol ? '৳ $formatted' : formatted;
  }

  static String formatUsd(
    num amount, {
    bool showSymbol = true,
    int decimals = 0,
  }) {
    final String fixedStr = amount.toStringAsFixed(decimals);
    final List<String> parts = fixedStr.split('.');

    final String integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    final String formatted = parts.length > 1
        ? '$integerPart.${parts[1]}'
        : integerPart;
    return showSymbol ? '\$ $formatted' : formatted;
  }

  static String format(num amount, bool isBangla, {int decimals = 0}) {
    return isBangla ? formatBdt(amount) : formatUsd(amount, decimals: decimals);
  }
}

class CostBasedSolarScreen extends StatefulWidget {
  final bool isBangla;
  final VoidCallback? onToggleLanguage;

  const CostBasedSolarScreen({
    super.key,
    this.isBangla = true,
    this.onToggleLanguage,
  });

  @override
  State<CostBasedSolarScreen> createState() => _CostBasedSolarScreenState();
}

class _CostBasedSolarScreenState extends State<CostBasedSolarScreen> {
  late bool _isBangla;

  double _usdToBdtRate = 120.0;
  bool _isLoadingRate = false;

  final TextEditingController _budgetController = TextEditingController();

  SolarSystemType _selectedSystemType = SolarSystemType.gridTied;
  double _costPerWatt = 75.0;

  final double _selectedModuleEfficiency = 0.215;
  final int _selectedModuleWatt = 550;

  bool _isLoadingNasa = false;
  SolarRadiationResult? _climateData;

  static const double _defaultLat = 23.8103;
  static const double _defaultLon = 90.4125;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _initDefaultValues();
    _fetchDynamicRateAndData();
  }

  void _initDefaultValues() {
    if (_isBangla) {
      _budgetController.text = '250000';
      _costPerWatt = _getDefaultRateForType(
        _selectedSystemType,
        isBangla: true,
      );
    } else {
      _budgetController.text = '2000';
      _costPerWatt = _getDefaultRateForType(
        _selectedSystemType,
        isBangla: false,
      );
    }
  }

  Future<void> _fetchDynamicRateAndData() async {
    setState(() => _isLoadingRate = true);
    final rate = await CurrencyService.getUsdToBdtRate();
    if (mounted) {
      setState(() {
        _usdToBdtRate = rate;
        _isLoadingRate = false;
      });
    }
    _fetchLocationClimateData();
  }

  double _getDefaultRateForType(
    SolarSystemType type, {
    required bool isBangla,
  }) {
    if (isBangla) {
      switch (type) {
        case SolarSystemType.gridTied:
          return 75.0;
        case SolarSystemType.hybrid:
          return 105.0;
        case SolarSystemType.offGrid:
          return 120.0;
      }
    } else {
      switch (type) {
        case SolarSystemType.gridTied:
          return 0.65;
        case SolarSystemType.hybrid:
          return 0.90;
        case SolarSystemType.offGrid:
          return 1.05;
      }
    }
  }

  void _onLanguageChanged() {
    setState(() {
      _isBangla = !_isBangla;
      final double currentBudget =
          double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0.0;
      if (_isBangla) {
        _budgetController.text = (currentBudget * _usdToBdtRate)
            .toStringAsFixed(0);
        _costPerWatt = _costPerWatt * _usdToBdtRate;
      } else {
        _budgetController.text = (currentBudget / _usdToBdtRate)
            .toStringAsFixed(0);
        _costPerWatt = _costPerWatt / _usdToBdtRate;
      }
    });
    widget.onToggleLanguage?.call();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationClimateData() async {
    setState(() => _isLoadingNasa = true);
    try {
      final result = await SolarRadiationService.fetchPshByCoordinates(
        _defaultLat,
        _defaultLon,
      );
      if (mounted) setState(() => _climateData = result);
    } catch (_) {
      if (mounted) {
        setState(() {
          _climateData = SolarRadiationResult(
            peakSunHours: SolarRadiationService.defaultPsh,
            messageBn: 'ডিফল্ট সৌর বিকিরণ ব্যবহৃত হচ্ছে',
            messageEn: 'Using default solar radiation',
            isSuccess: false,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingNasa = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String currencySymbol = _isBangla ? '৳' : '\$';
    final double totalBudget =
        double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0.0;

    final double installableCapacityKwp = (_costPerWatt > 0 && totalBudget > 0)
        ? (totalBudget / _costPerWatt) / 1000.0
        : 0.0;

    final int totalPanels = installableCapacityKwp > 0
        ? ((installableCapacityKwp * 1000) / _selectedModuleWatt).floor()
        : 0;

    final double psh =
        _climateData?.peakSunHours ?? SolarRadiationService.defaultPsh;
    final double ambTemp = _climateData?.ambientTemp ?? 26.0;
    final double tempDerate = SolarCalculationService.calculateTempDerateFactor(
      ambTemp,
    );
    final double basePR = _selectedSystemType == SolarSystemType.gridTied
        ? 0.80
        : 0.72;
    final double effectivePR = basePR * tempDerate;

    final double dailyGenerationKwh =
        installableCapacityKwp * psh * effectivePR;
    final double monthlyGenerationKwh = dailyGenerationKwh * 30;
    final double annualGenerationKwh = dailyGenerationKwh * 365;

    final double dynamicPF =
        SolarCalculationService.calculateDynamicPackingFactor(_defaultLat);
    final double netAreaSqM = installableCapacityKwp > 0
        ? (installableCapacityKwp / (_selectedModuleEfficiency * dynamicPF))
        : 0.0;
    final double netAreaSqFt = netAreaSqM * 10.7639;

    final double electricityTariff = _isBangla ? 9.50 : 0.12;
    final double annualSavings = annualGenerationKwh * electricityTariff;
    final double paybackYears = annualSavings > 0
        ? (totalBudget / annualSavings)
        : 0.0;

    final double co2OffsetKg = annualGenerationKwh * 0.62;
    final int equivalentTrees = (co2OffsetKg / 20.0).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isBangla ? 'বাজেটভিত্তিক সোলার সাইজিং' : 'Budget-Based Solar Sizing',
        ),
        actions: [
          IconButton(
            onPressed: _onLanguageChanged,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isBangla ? 'ENG (\$)' : 'বাংলা (৳)',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkBgTop, AppColors.darkBgBottom]
                : [AppColors.lightBgTop, AppColors.lightBgBottom],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClimateHeader(psh, ambTemp, isDark),
              const SizedBox(height: 14),
              _buildBudgetInputCard(currencySymbol, isDark),
              const SizedBox(height: 14),
              _buildRateAndTypeCard(currencySymbol, isDark),
              const SizedBox(height: 18),
              Text(
                _isBangla
                    ? 'বাজেট অনুযায়ী সম্ভাব্য সিস্টেম'
                    : 'Affordable Solar System',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildResultStatCard(
                    title: _isBangla ? 'ইনস্টলযোগ্য ক্ষমতা' : 'System Capacity',
                    value: '${installableCapacityKwp.toStringAsFixed(2)} kWp',
                    subtitle: _isBangla
                        ? 'প্যানেল: $totalPanels টি ($_selectedModuleWatt W)'
                        : 'Panels: $totalPanels pcs ($_selectedModuleWatt W)',
                    icon: Icons.flash_on_rounded,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildResultStatCard(
                    title: _isBangla ? 'প্রয়োজনীয় ছাদ/জমি' : 'Required Area',
                    value: '${netAreaSqFt.toStringAsFixed(0)} sq.ft',
                    subtitle: '≈ ${netAreaSqM.toStringAsFixed(1)} m²',
                    icon: Icons.roofing_rounded,
                    color: isDark
                        ? AppColors.energyGreen
                        : const Color(0xFF059669),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildResultStatCard(
                    title: _isBangla ? 'দৈনিক উৎপাদন' : 'Daily Output',
                    value: '${dailyGenerationKwh.toStringAsFixed(1)} kWh',
                    subtitle: _isBangla
                        ? 'মাসিক: ${monthlyGenerationKwh.toStringAsFixed(0)} ইউনিট'
                        : 'Monthly: ${monthlyGenerationKwh.toStringAsFixed(0)} Units',
                    icon: Icons.wb_sunny_rounded,
                    color: AppColors.solarGold,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildResultStatCard(
                    title: _isBangla
                        ? 'বিনিয়োগ ফেরত (Payback)'
                        : 'Est. Payback Time',
                    value: paybackYears > 0
                        ? '${paybackYears.toStringAsFixed(1)} ${_isBangla ? "বছর" : "Years"}'
                        : 'N/A',
                    subtitle: _isBangla
                        ? 'বাৎসরিক সাশ্রয়: ${CurrencyFormatter.format(annualSavings, _isBangla)}'
                        : 'Annual Savings: ${CurrencyFormatter.format(annualSavings, _isBangla)}',
                    icon: Icons.savings_rounded,
                    color: isDark ? Colors.tealAccent : const Color(0xFF0D9488),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (paybackYears > 0 && paybackYears <= 25)
                _buildPaybackTimelineCard(paybackYears, isDark),
              const SizedBox(height: 14),
              _buildCostBreakdownCard(totalBudget, isDark),
              const SizedBox(height: 14),
              _buildEnvironmentalImpactCard(
                co2OffsetKg,
                equivalentTrees,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClimateHeader(double psh, double ambTemp, bool isDark) {
    final String locationText =
        (_climateData != null && _climateData!.placeName.isNotEmpty)
        ? '📍 ${_climateData!.placeName}'
        : (_isBangla ? 'নাসা ক্লাইমেট ডেটা' : 'NASA Climate Data');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.satellite_alt_rounded,
            color: isDark ? AppColors.accentCyan : const Color(0xFF0284C7),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.accentCyan
                                    : AppColors.energyGreen)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isLoadingRate
                            ? 'Syncing...'
                            : '1 USD ≈ ${_usdToBdtRate.toStringAsFixed(1)} BDT',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.accentCyan
                              : AppColors.energyGreen,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _isBangla
                      ? 'PSH: ${psh.toStringAsFixed(2)} ঘণ্টা | গড় তাপমাত্রা: ${ambTemp.toStringAsFixed(1)}°C'
                      : 'PSH: ${psh.toStringAsFixed(2)} hrs | Avg Temp: ${ambTemp.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoadingNasa)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? AppColors.accentCyan : AppColors.energyGreen,
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                size: 18,
              ),
              onPressed: _fetchDynamicRateAndData,
              tooltip: _isBangla ? 'রিফ্রেশ' : 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetInputCard(String currencySymbol, bool isDark) {
    final double currentVal =
        double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0.0;
    final double maxSliderVal = _isBangla ? 2500000.0 : 20000.0;
    final double minSliderVal = _isBangla ? 30000.0 : 300.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla ? 'আপনার মোট বাজেট' : 'Total Investment Budget',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.energyGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  CurrencyFormatter.format(currentVal, _isBangla),
                  style: const TextStyle(
                    color: AppColors.energyGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? AppColors.darkInputBg
                  : AppColors.lightInputBg,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Center(
                  widthFactor: 0.0,
                  child: Text(
                    currencySymbol,
                    style: const TextStyle(
                      color: AppColors.energyGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.energyGreen,
              inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
              thumbColor: AppColors.energyGreen,
              trackHeight: 4,
            ),
            child: Slider(
              value: currentVal.clamp(minSliderVal, maxSliderVal),
              min: minSliderVal,
              max: maxSliderVal,
              onChanged: (v) {
                setState(() {
                  _budgetController.text = v.toStringAsFixed(0);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateAndTypeCard(String currencySymbol, bool isDark) {
    final double minRate = _isBangla ? 50.0 : 0.40;
    final double maxRate = _isBangla ? 160.0 : 1.50;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isBangla
                ? 'সিস্টেমের ধরন ও বাজারদর'
                : 'System Architecture & Market Rate',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTypeRadio(
                SolarSystemType.gridTied,
                _isBangla ? 'অন-গ্রিড' : 'On-Grid',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildTypeRadio(
                SolarSystemType.hybrid,
                _isBangla ? 'হাইব্রিড' : 'Hybrid',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildTypeRadio(
                SolarSystemType.offGrid,
                _isBangla ? 'অফ-গ্রিড' : 'Off-Grid',
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'প্রতি ওয়াট সিস্টেম খরচ'
                    : 'Estimated Cost per Watt',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 11.5,
                ),
              ),
              Text(
                _isBangla
                    ? '${CurrencyFormatter.formatBdt(_costPerWatt)} / W'
                    : '${CurrencyFormatter.formatUsd(_costPerWatt, decimals: 2)} / W',
                style: TextStyle(
                  color: isDark
                      ? AppColors.accentCyan
                      : const Color(0xFF0284C7),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isDark
                  ? AppColors.accentCyan
                  : const Color(0xFF0284C7),
              inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
              thumbColor: isDark
                  ? AppColors.accentCyan
                  : const Color(0xFF0284C7),
              trackHeight: 3,
            ),
            child: Slider(
              value: _costPerWatt.clamp(minRate, maxRate),
              min: minRate,
              max: maxRate,
              onChanged: (v) => setState(() => _costPerWatt = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaybackTimelineCard(double paybackYears, bool isDark) {
    final double paybackRatio = (paybackYears / 25.0).clamp(0.05, 0.95);
    final double freeYears = 25.0 - paybackYears;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? '২৫ বছরের রিটার্ন টাইমলাইন'
                    : '25-Year Lifecycle Return',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isBangla
                    ? '${freeYears.toStringAsFixed(1)} বছর বিনামূল্যে বিদ্যুৎ'
                    : '${freeYears.toStringAsFixed(1)} Yrs Free Power',
                style: const TextStyle(
                  color: AppColors.energyGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (paybackRatio * 100).round(),
                    child: Container(color: Colors.orangeAccent),
                  ),
                  Expanded(
                    flex: ((1.0 - paybackRatio) * 100).round(),
                    child: Container(color: AppColors.energyGreen),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'বিনিয়োগ রিকভারি: ${paybackYears.toStringAsFixed(1)} বছর'
                    : 'Investment Recovery: ${paybackYears.toStringAsFixed(1)} yrs',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 10,
                ),
              ),
              Text(
                _isBangla ? 'মোট আয়ুষ্কাল: ২৫ বছর' : 'Total Lifecycle: 25 yrs',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdownCard(double totalBudget, bool isDark) {
    final double panelCost =
        totalBudget *
        (_selectedSystemType == SolarSystemType.gridTied ? 0.48 : 0.38);
    final double inverterCost = totalBudget * 0.22;
    final double batteryCost = _selectedSystemType == SolarSystemType.gridTied
        ? 0.0
        : totalBudget * 0.25;
    final double structureAndBosCost =
        totalBudget - (panelCost + inverterCost + batteryCost);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isBangla
                ? 'বাজেট খরচের আনুমানিক বিভাজন'
                : 'Estimated Cost Distribution',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            _isBangla ? 'সোলার প্যানেল' : 'Solar Modules',
            panelCost,
            Colors.amberAccent,
            isDark,
          ),
          _buildBreakdownRow(
            _isBangla ? 'ইনভার্টার ও প্রটেকশন' : 'Inverter & Protection',
            inverterCost,
            Colors.cyanAccent,
            isDark,
          ),
          if (_selectedSystemType != SolarSystemType.gridTied)
            _buildBreakdownRow(
              _isBangla ? 'ব্যাটারি ব্যাংক' : 'Battery Bank',
              batteryCost,
              Colors.purpleAccent,
              isDark,
            ),
          _buildBreakdownRow(
            _isBangla
                ? 'মাউন্টিং স্ট্রাকচার, ওয়্যারিং ও লেবার'
                : 'Mounting, BOS & Labor',
            structureAndBosCost,
            Colors.tealAccent,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double amount,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Text(
            CurrencyFormatter.format(amount, _isBangla),
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentalImpactCard(double co2Kg, int trees, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.energyGreen.withValues(alpha: isDark ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.energyGreen.withValues(alpha: isDark ? 0.2 : 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.energyGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.energyGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBangla
                      ? 'পরিবেশগত অবদান (বাৎসরিক)'
                      : 'Annual Environmental Impact',
                  style: const TextStyle(
                    color: AppColors.energyGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isBangla
                      ? 'কার্বন হ্রাস: ${co2Kg.toStringAsFixed(0)} kg CO₂ | $trees টি বৃক্ষরোপণের সমতুল্য'
                      : 'CO₂ Offset: ${co2Kg.toStringAsFixed(0)} kg CO₂ | Planting $trees trees',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : AppColors.lightTextSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRadio(SolarSystemType type, String title, bool isDark) {
    final bool isSelected = _selectedSystemType == type;
    final Color activeColor = isDark
        ? AppColors.accentCyan
        : AppColors.energyGreen;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSystemType = type;
            _costPerWatt = _getDefaultRateForType(type, isBangla: _isBangla);
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : (isDark ? AppColors.darkInputBg : AppColors.lightInputBg),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkInputBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
