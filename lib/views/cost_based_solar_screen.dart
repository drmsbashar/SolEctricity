import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../services/solar_radiation_service.dart';

enum SystemType { onGrid, hybrid, offGrid }

// =========================================================================
// 🌐 ১. ডাইনামিক কারেন্সি এক্সচেঞ্জ সার্ভিস
// =========================================================================
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

// =========================================================================
// 🔤 ২. পিওর ডার্ট কমা ফরম্যাটার (intl প্যাকেজ ছাড়াই)
// =========================================================================
class CurrencyFormatter {
  // 🇧🇩 বাংলাদেশী ফরম্যাট (শেষ ৩ ঘর, এরপর প্রতি ২ ঘর পর পর কমা)
  static String formatBdt(num amount, {bool showSymbol = true}) {
    final int rounded = amount.round();
    final String str = rounded.toString();

    String formatted;
    if (str.length <= 3) {
      formatted = str;
    } else {
      final String lastThree = str.substring(str.length - 3);
      final String remaining = str.substring(0, str.length - 3);

      // শেষ তিন ঘরের আগের অংশকে প্রতি ২ ঘর পর পর কমা দিয়ে সাজানো
      final String formattedRemaining = remaining.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      formatted = '$formattedRemaining,$lastThree';
    }

    return showSymbol ? '৳ $formatted' : formatted;
  }

  // 🌐 আন্তর্জাতিক ফরম্যাট (ডানদিক থেকে প্রতি ৩ ঘর পর পর কমা)
  static String formatUsd(
    num amount, {
    bool showSymbol = true,
    int decimals = 0,
  }) {
    final String fixedStr = amount.toStringAsFixed(decimals);
    final List<String> parts = fixedStr.split('.');

    // পূর্ণসংখ্যার অংশে প্রতি ৩ ঘর পর পর কমা বসানো
    final String integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    final String formatted = parts.length > 1
        ? '$integerPart.${parts[1]}'
        : integerPart;
    return showSymbol ? '\$ $formatted' : formatted;
  }

  // 🔄 ভাষা (বাংলা/ইংরেজি) অনুযায়ী স্বয়ংক্রিয়ভাবে নির্ধারণ
  static String format(num amount, bool isBangla, {int decimals = 0}) {
    if (isBangla) {
      return formatBdt(amount);
    } else {
      return formatUsd(amount, decimals: decimals);
    }
  }
}

// =========================================================================
// 📱 ৩. মূল কস্ট-বেসড সোলার সাইজিং স্ক্রিন
// =========================================================================
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

  SystemType _selectedSystemType = SystemType.onGrid;
  double _costPerWatt = 75.0;

  final double _selectedModuleEfficiency = 0.215;
  final int _selectedModuleWatt = 550;

  bool _isLoadingNasa = false;
  SolarRadiationResult? _climateData;

  final double _latitude = 23.8103;
  final double _longitude = 90.4125;

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

  double _getDefaultRateForType(SystemType type, {required bool isBangla}) {
    if (isBangla) {
      switch (type) {
        case SystemType.onGrid:
          return 75.0;
        case SystemType.hybrid:
          return 105.0;
        case SystemType.offGrid:
          return 120.0;
      }
    } else {
      switch (type) {
        case SystemType.onGrid:
          return 0.65;
        case SystemType.hybrid:
          return 0.90;
        case SystemType.offGrid:
          return 1.05;
      }
    }
  }

  void _onLanguageChanged() {
    setState(() {
      _isBangla = !_isBangla;
      final double currentBudget =
          double.tryParse(_budgetController.text) ?? 0.0;
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
        _latitude,
        _longitude,
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

  double _calculateDynamicPackingFactor(double latitude) {
    final double absLat = latitude.abs();
    if (absLat <= 15.0) return 0.75;
    if (absLat <= 25.0) return 0.75 - ((absLat - 15.0) / 10.0) * 0.07;
    if (absLat <= 35.0) return 0.68 - ((absLat - 25.0) / 10.0) * 0.08;
    return 0.58;
  }

  double _calculateTempDerateFactor(double ambientTemp) {
    const double noct = 45.0;
    const double tempCoeff = 0.0035;
    final double cellTemp = ambientTemp + (noct - 20.0);
    if (cellTemp <= 25.0) return 1.0;
    final double loss = (cellTemp - 25.0) * tempCoeff;
    return (1.0 - loss).clamp(0.75, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final String currencySymbol = _isBangla ? '৳' : '\$';
    final double totalBudget = double.tryParse(_budgetController.text) ?? 0.0;

    // ১. বাজেট থেকে ইনস্টলযোগ্য ক্ষমতা (kWp)
    final double installableCapacityKwp = (_costPerWatt > 0 && totalBudget > 0)
        ? (totalBudget / _costPerWatt) / 1000.0
        : 0.0;

    final int totalPanels = installableCapacityKwp > 0
        ? ((installableCapacityKwp * 1000) / _selectedModuleWatt).floor()
        : 0;

    // ২. সৌর বিকিরণ ও উৎপাদন হিসাব (সম্পূর্ণ নাল-সেফ)
    final double psh =
        _climateData?.peakSunHours ?? SolarRadiationService.defaultPsh;
    final double ambTemp = _climateData?.ambientTemp ?? 26.0;
    final double tempDerate = _calculateTempDerateFactor(ambTemp);
    final double basePR = _selectedSystemType == SystemType.onGrid
        ? 0.80
        : 0.72;
    final double effectivePR = basePR * tempDerate;

    final double dailyGenerationKwh =
        installableCapacityKwp * psh * effectivePR;
    final double monthlyGenerationKwh = dailyGenerationKwh * 30;
    final double annualGenerationKwh = dailyGenerationKwh * 365;

    // ৩. প্রয়োজনীয় নেট জায়গা
    final double dynamicPF = _calculateDynamicPackingFactor(_latitude);
    final double netAreaSqM = installableCapacityKwp > 0
        ? (installableCapacityKwp / (_selectedModuleEfficiency * dynamicPF))
        : 0.0;
    final double netAreaSqFt = netAreaSqM * 10.7639;

    // ৪. আর্থিক সাশ্রয় ও পে-ব্যাক সময়কাল
    final double electricityTariff = _isBangla ? 9.50 : 0.12;
    final double annualSavings = annualGenerationKwh * electricityTariff;
    final double paybackYears = annualSavings > 0
        ? (totalBudget / annualSavings)
        : 0.0;

    // ৫. পরিবেশগত প্রভাব
    final double co2OffsetKg = annualGenerationKwh * 0.62;
    final int equivalentTrees = (co2OffsetKg / 20.0).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isBangla ? 'বাজেটভিত্তিক সোলার সাইজিং' : 'Budget-Based Solar Sizing',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _onLanguageChanged,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isBangla ? 'ENG (\$)' : 'বাংলা (৳)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClimateHeader(psh, ambTemp),
            const SizedBox(height: 14),

            _buildBudgetInputCard(currencySymbol),
            const SizedBox(height: 14),

            _buildRateAndTypeCard(currencySymbol),
            const SizedBox(height: 18),

            Text(
              _isBangla
                  ? 'বাজেট অনুযায়ী সম্ভাব্য সিস্টেম'
                  : 'Affordable Solar System',
              style: const TextStyle(
                color: Colors.white,
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
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 10),
                _buildResultStatCard(
                  title: _isBangla ? 'প্রয়োজনীয় ছাদ/জমি' : 'Required Area',
                  value: '${netAreaSqFt.toStringAsFixed(0)} sq.ft',
                  subtitle: '≈ ${netAreaSqM.toStringAsFixed(1)} m²',
                  icon: Icons.roofing_rounded,
                  color: Colors.cyanAccent,
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
                  color: Colors.amberAccent,
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
                  color: Colors.tealAccent,
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (paybackYears > 0 && paybackYears <= 25)
              _buildPaybackTimelineCard(paybackYears),
            const SizedBox(height: 14),

            _buildCostBreakdownCard(totalBudget, currencySymbol),
            const SizedBox(height: 14),

            _buildEnvironmentalImpactCard(co2OffsetKg, equivalentTrees),
          ],
        ),
      ),
    );
  }

  // 📍 ক্লাইমেট ও লাইভ রেট হেডার
  Widget _buildClimateHeader(double psh, double ambTemp) {
    final String locationText =
        (_climateData != null && _climateData!.placeName.isNotEmpty)
        ? '📍 ${_climateData!.placeName}'
        : (_isBangla ? 'নাসা ক্লাইমেট ডেটা' : 'NASA Climate Data');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.satellite_alt_rounded,
            color: Colors.cyanAccent,
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
                        style: const TextStyle(
                          color: Colors.white,
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
                        color: Colors.cyanAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isLoadingRate
                            ? 'Syncing...'
                            : '1 USD ≈ ${_usdToBdtRate.toStringAsFixed(1)} BDT',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
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
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          if (_isLoadingNasa)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.cyanAccent,
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white54,
                size: 18,
              ),
              onPressed: _fetchDynamicRateAndData,
              tooltip: _isBangla ? 'রিফ্রেশ' : 'Refresh',
            ),
        ],
      ),
    );
  }

  // 💰 বাজেট ইনপুট কার্ড
  Widget _buildBudgetInputCard(String currencySymbol) {
    final double currentVal = double.tryParse(_budgetController.text) ?? 0.0;
    final double maxSliderVal = _isBangla ? 2500000.0 : 20000.0;
    final double minSliderVal = _isBangla ? 30000.0 : 300.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla ? 'আপনার মোট বাজেট' : 'Total Investment Budget',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  CurrencyFormatter.format(currentVal, _isBangla),
                  style: const TextStyle(
                    color: Colors.greenAccent,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Center(
                  widthFactor: 0.0,
                  child: Text(
                    currencySymbol,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
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
              activeTrackColor: Colors.greenAccent,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.greenAccent,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(minSliderVal, _isBangla),
                  style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                ),
                Text(
                  CurrencyFormatter.format(maxSliderVal / 2, _isBangla),
                  style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                ),
                Text(
                  CurrencyFormatter.format(maxSliderVal, _isBangla),
                  style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ বাজারদর ও সিস্টেম টাইপ কার্ড
  Widget _buildRateAndTypeCard(String currencySymbol) {
    final double minRate = _isBangla ? 50.0 : 0.40;
    final double maxRate = _isBangla ? 160.0 : 1.50;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isBangla
                ? 'সিস্টেমের ধরন ও বাজারদর'
                : 'System Architecture & Market Rate',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTypeRadio(
                SystemType.onGrid,
                _isBangla ? 'অন-গ্রিড' : 'On-Grid',
              ),
              const SizedBox(width: 8),
              _buildTypeRadio(
                SystemType.hybrid,
                _isBangla ? 'হাইব্রিড' : 'Hybrid',
              ),
              const SizedBox(width: 8),
              _buildTypeRadio(
                SystemType.offGrid,
                _isBangla ? 'অফ-গ্রিড' : 'Off-Grid',
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
                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
              Text(
                _isBangla
                    ? '${CurrencyFormatter.formatBdt(_costPerWatt)} / W'
                    : '${CurrencyFormatter.formatUsd(_costPerWatt, decimals: 2)} / W',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.cyanAccent,
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

  // ⏱️ ২৫ বছরের রিটার্ন টাইমলাইন
  Widget _buildPaybackTimelineCard(double paybackYears) {
    final double paybackRatio = (paybackYears / 25.0).clamp(0.05, 0.95);
    final double freeYears = 25.0 - paybackYears;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isBangla
                    ? '${freeYears.toStringAsFixed(1)} বছর বিনামূল্যে বিদ্যুৎ'
                    : '${freeYears.toStringAsFixed(1)} Yrs Free Power',
                style: const TextStyle(
                  color: Colors.greenAccent,
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
                    child: Container(color: Colors.greenAccent),
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
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📊 খরচের উপাদানভিত্তিক বিভাজন
  Widget _buildCostBreakdownCard(double totalBudget, String currencySymbol) {
    final double panelCost =
        totalBudget * (_selectedSystemType == SystemType.onGrid ? 0.48 : 0.38);
    final double inverterCost = totalBudget * 0.22;
    final double batteryCost = _selectedSystemType == SystemType.onGrid
        ? 0.0
        : totalBudget * 0.25;
    final double structureAndBosCost =
        totalBudget - (panelCost + inverterCost + batteryCost);

    final double safeBudget = totalBudget <= 0 ? 1.0 : totalBudget;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isBangla
                ? 'বাজেট খরচের আনুমানিক বিভাজন'
                : 'Estimated Cost Distribution',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: math.max(1, (panelCost * 100 / safeBudget).round()),
                    child: Container(color: Colors.amberAccent),
                  ),
                  Expanded(
                    flex: math.max(
                      1,
                      (inverterCost * 100 / safeBudget).round(),
                    ),
                    child: Container(color: Colors.cyanAccent),
                  ),
                  if (_selectedSystemType != SystemType.onGrid)
                    Expanded(
                      flex: math.max(
                        1,
                        (batteryCost * 100 / safeBudget).round(),
                      ),
                      child: Container(color: Colors.purpleAccent),
                    ),
                  Expanded(
                    flex: math.max(
                      1,
                      (structureAndBosCost * 100 / safeBudget).round(),
                    ),
                    child: Container(color: Colors.tealAccent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            _isBangla ? 'সোলার প্যানেল' : 'Solar Modules',
            panelCost,
            Colors.amberAccent,
          ),
          _buildBreakdownRow(
            _isBangla ? 'ইনভার্টার ও প্রটেকশন' : 'Inverter & Protection',
            inverterCost,
            Colors.cyanAccent,
          ),
          if (_selectedSystemType != SystemType.onGrid)
            _buildBreakdownRow(
              _isBangla ? 'ব্যাটারি ব্যাংক' : 'Battery Bank',
              batteryCost,
              Colors.purpleAccent,
            ),
          _buildBreakdownRow(
            _isBangla
                ? 'মাউন্টিং স্ট্রাকচার, ওয়্যারিং ও লেবার'
                : 'Mounting, BOS & Labor',
            structureAndBosCost,
            Colors.tealAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color color) {
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
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          Text(
            CurrencyFormatter.format(amount, _isBangla),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 🌿 পরিবেশগত প্রভাব কার্ড
  Widget _buildEnvironmentalImpactCard(double co2Kg, int trees) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Colors.greenAccent,
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
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isBangla
                      ? 'কার্বন হ্রাস: ${co2Kg.toStringAsFixed(0)} kg CO₂ | $trees টি বৃক্ষরোপণের সমতুল্য'
                      : 'CO₂ Offset: ${co2Kg.toStringAsFixed(0)} kg CO₂ | Equivalent to planting $trees trees',
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRadio(SystemType type, String title) {
    final bool isSelected = _selectedSystemType == type;
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
                ? Colors.cyanAccent.withValues(alpha: 0.15)
                : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.cyanAccent : Colors.white12,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.cyanAccent : Colors.white70,
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
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
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
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
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
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
