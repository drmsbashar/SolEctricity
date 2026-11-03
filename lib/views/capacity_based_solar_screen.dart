import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../models/system_sizing_params.dart';
import '../services/solar_calculation_service.dart';
import '../services/solar_radiation_service.dart';
import '../widgets/theme_toggle_button.dart';

class CapacityBasedSolarScreen extends StatefulWidget {
  final bool isBangla;
  final VoidCallback? onToggleLanguage;

  const CapacityBasedSolarScreen({
    super.key,
    this.isBangla = true,
    this.onToggleLanguage,
  });

  @override
  State<CapacityBasedSolarScreen> createState() =>
      _CapacityBasedSolarScreenState();
}

class _CapacityBasedSolarScreenState extends State<CapacityBasedSolarScreen> {
  late bool _isBangla;

  final TextEditingController _demandController = TextEditingController(
    text: '20',
  );
  SolarSystemType _selectedSystemType = SolarSystemType.gridTied;

  double _selectedModuleEfficiency = 0.215;
  int _selectedModuleWatt = 550;
  int _backupHours = 4;
  double _dayLoadPercentage = 60.0;

  bool _isLoadingNasa = false;
  SolarRadiationResult? _climateData;

  static const double _defaultLat = 23.8103;
  static const double _defaultLon = 90.4125;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _fetchLocationClimateData();
  }

  @override
  void dispose() {
    _demandController.dispose();
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

  Map<String, int> _calculateStringConfiguration(int totalPanels) {
    if (totalPanels <= 0) return {'strings': 0, 'panelsPerString': 0};
    if (totalPanels <= 8) return {'strings': 1, 'panelsPerString': totalPanels};

    int bestStrings = 1;
    int bestPanelsPerString = totalPanels;

    for (int s = 2; s <= 6; s++) {
      if (totalPanels % s == 0) {
        final p = totalPanels ~/ s;
        if (p >= 8 && p <= 24) {
          bestStrings = s;
          bestPanelsPerString = p;
          break;
        }
      }
    }
    return {'strings': bestStrings, 'panelsPerString': bestPanelsPerString};
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double dailyDemandKwh =
        double.tryParse(_demandController.text.replaceAll(',', '')) ?? 0.0;

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

    final double requiredCapacityKwp = (psh > 0 && effectivePR > 0)
        ? (dailyDemandKwh / (psh * effectivePR))
        : 0.0;

    final int totalPanels = (requiredCapacityKwp > 0)
        ? ((requiredCapacityKwp * 1000) / _selectedModuleWatt).ceil()
        : 0;
    final stringConfig = _calculateStringConfiguration(totalPanels);

    final double dynamicPF =
        SolarCalculationService.calculateDynamicPackingFactor(_defaultLat);
    final double netRoofAreaSqM = (requiredCapacityKwp > 0)
        ? (requiredCapacityKwp / (_selectedModuleEfficiency * dynamicPF))
        : 0.0;
    final double netRoofAreaSqFt = netRoofAreaSqM * 10.7639;

    final double dayEnergyKwh = dailyDemandKwh * (_dayLoadPercentage / 100.0);
    final double nightEnergyKwh = dailyDemandKwh - dayEnergyKwh;

    final double batteryBankKwh =
        (_selectedSystemType != SolarSystemType.gridTied && dailyDemandKwh > 0)
        ? ((nightEnergyKwh * (_backupHours / 12.0).clamp(0.2, 1.0)) /
              (0.80 * 0.85))
        : 0.0;

    final double inverterKw = requiredCapacityKwp > 0
        ? (requiredCapacityKwp / 1.15).clamp(1.0, 500.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isBangla
              ? 'চাহিদাভিত্তিক সোলার সাইজিং'
              : 'Demand-Based Solar Sizing',
        ),
        actions: [
          IconButton(
            tooltip: _isBangla ? 'প্রপোজাল সারাংশ' : 'Proposal Summary',
            icon: Icon(
              Icons.description_rounded,
              color: isDark ? AppColors.accentCyan : const Color(0xFF0284C7),
            ),
            onPressed: () => _showProposalSummaryDialog(
              dailyDemandKwh: dailyDemandKwh,
              capacityKwp: requiredCapacityKwp,
              totalPanels: totalPanels,
              roofAreaSqFt: netRoofAreaSqFt,
              inverterKw: inverterKw,
              batteryBankKwh: batteryBankKwh,
              strings: stringConfig['strings']!,
              panelsPerString: stringConfig['panelsPerString']!,
              isDark: isDark,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _isBangla = !_isBangla);
              widget.onToggleLanguage?.call();
            },
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isBangla ? 'ENG' : 'বাংলা',
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
              _buildDemandInputCard(isDark),
              const SizedBox(height: 14),
              _buildDayNightSplitCard(dayEnergyKwh, nightEnergyKwh, isDark),
              const SizedBox(height: 14),
              _buildConfigurationCard(isDark),
              const SizedBox(height: 18),
              Text(
                _isBangla
                    ? 'প্রকৌশল সাইজিং ফলাফল'
                    : 'Engineering Sizing Results',
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
                    title: _isBangla ? 'সিস্টেম ক্ষমতা' : 'DC Capacity',
                    value: '${requiredCapacityKwp.toStringAsFixed(2)} kWp',
                    subtitle: _isBangla
                        ? 'বাৎসরিক: ${(dailyDemandKwh * 365).toStringAsFixed(0)} kWh'
                        : 'Annual: ${(dailyDemandKwh * 365).toStringAsFixed(0)} kWh',
                    icon: Icons.flash_on_rounded,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildResultStatCard(
                    title: _isBangla ? 'প্যানেল সংখ্যা' : 'Total Panels',
                    value: _isBangla ? '$totalPanels টি' : '$totalPanels pcs',
                    subtitle: '$_selectedModuleWatt Watt Modules',
                    icon: Icons.grid_view_rounded,
                    color: AppColors.solarGold,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildResultStatCard(
                    title: _isBangla ? 'প্রয়োজনীয় ছাদ/জমি' : 'Required Space',
                    value: '${netRoofAreaSqFt.toStringAsFixed(0)} sq.ft',
                    subtitle: '≈ ${netRoofAreaSqM.toStringAsFixed(1)} m²',
                    icon: Icons.roofing_rounded,
                    color: isDark
                        ? AppColors.energyGreen
                        : const Color(0xFF059669),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildResultStatCard(
                    title: _isBangla
                        ? 'প্রস্তাবিত ইনভার্টার'
                        : 'Recommended Inverter',
                    value: '${inverterKw.toStringAsFixed(1)} kW',
                    subtitle: 'DC/AC Ratio ≈ 1.15',
                    icon: Icons.developer_board_rounded,
                    color: isDark ? Colors.tealAccent : const Color(0xFF0D9488),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildStringConfigCard(stringConfig, isDark),
              if (_selectedSystemType != SolarSystemType.gridTied) ...[
                const SizedBox(height: 10),
                _buildBatteryStorageCard(batteryBankKwh, isDark),
              ],
              const SizedBox(height: 16),
              if (_climateData != null && _climateData!.monthlyPsh.isNotEmpty)
                _buildSeasonalGenerationChart(
                  requiredCapacityKwp,
                  effectivePR,
                  dailyDemandKwh,
                  isDark,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStringConfigCard(Map<String, int> config, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            Icons.cable_rounded,
            color: isDark ? AppColors.accentCyan : const Color(0xFF0284C7),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBangla
                      ? 'স্ট্রিং কনফিগারেশন সুপারিশ'
                      : 'Recommended Stringing',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isBangla
                      ? '${config['strings']} টি স্ট্রিং × ${config['panelsPerString']} টি প্যানেল'
                      : '${config['strings']} Strings × ${config['panelsPerString']} Panels',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.energyGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Voc Safe',
              style: TextStyle(
                color: AppColors.energyGreen,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryStorageCard(double batteryBankKwh, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.purpleAccent.withValues(alpha: isDark ? 0.3 : 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.battery_charging_full_rounded,
              color: Colors.purpleAccent,
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
                      ? 'প্রস্তাবিত ব্যাটারি ব্যাংক'
                      : 'Battery Storage Bank',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${batteryBankKwh.toStringAsFixed(1)} kWh (48V ≈ ${(batteryBankKwh * 1000 / 48).toStringAsFixed(0)} Ah)',
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$_backupHours ${_isBangla ? "ঘণ্টা ব্যাকআপ" : "hrs backup"}',
            style: TextStyle(
              color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalGenerationChart(
    double capacityKwp,
    double effectivePR,
    double dailyDemandKwh,
    bool isDark,
  ) {
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
                    ? 'মাসভিত্তিক উৎপাদন বনাম চাহিদা'
                    : 'Monthly Generation vs Target',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isBangla ? 'উৎপাদন' : 'Gen',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 8, height: 2, color: AppColors.alertRed),
                  const SizedBox(width: 4),
                  Text(
                    _isBangla ? 'চাহিদা' : 'Target',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: SeasonalComparisonChart(
              monthlyPsh: _climateData!.monthlyPsh,
              capacityKwp: capacityKwp,
              effectivePR: effectivePR,
              targetDailyKwh: dailyDemandKwh,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayNightSplitCard(double dayKwh, double nightKwh, bool isDark) {
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
                _isBangla ? 'দিন ও রাতের লোড বণ্টন' : 'Day vs Night Load Split',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_dayLoadPercentage.toStringAsFixed(0)}% : ${(100 - _dayLoadPercentage).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: isDark
                      ? AppColors.accentCyan
                      : const Color(0xFF0284C7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.solarGold,
              inactiveTrackColor: Colors.indigoAccent.withValues(alpha: 0.4),
              thumbColor: AppColors.solarGold,
              trackHeight: 4,
            ),
            child: Slider(
              value: _dayLoadPercentage,
              min: 20,
              max: 90,
              divisions: 14,
              onChanged: (v) => setState(() => _dayLoadPercentage = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    size: 14,
                    color: AppColors.solarGold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isBangla
                        ? 'দিনের লোড: ${dayKwh.toStringAsFixed(1)} kWh'
                        : 'Day Load: ${dayKwh.toStringAsFixed(1)} kWh',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.nightlight_outlined,
                    size: 14,
                    color: Colors.indigoAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isBangla
                        ? 'রাতের লোড: ${nightKwh.toStringAsFixed(1)} kWh'
                        : 'Night Load: ${nightKwh.toStringAsFixed(1)} kWh',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClimateHeader(double psh, double ambTemp, bool isDark) {
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
                Text(
                  _climateData?.placeName.isNotEmpty == true
                      ? '📍 ${_climateData!.placeName}'
                      : (_isBangla
                            ? 'নাসা ক্লাইমেট ডেটা'
                            : 'NASA Climate Data'),
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
              onPressed: _fetchLocationClimateData,
              tooltip: _isBangla ? 'রিফ্রেশ' : 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildDemandInputCard(bool isDark) {
    final double currentVal =
        double.tryParse(_demandController.text.replaceAll(',', '')) ?? 20.0;
    final double sliderMax = math.max(
      200.0,
      ((currentVal / 50).ceil() * 50).toDouble(),
    );

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
                _isBangla ? 'দৈনিক বিদ্যুৎ চাহিদা' : 'Daily Energy Target',
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
                  _isBangla ? 'ইউনিট বা kWh' : 'Units or kWh',
                  style: const TextStyle(
                    color: AppColors.energyGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _demandController,
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
              prefixIcon: const Icon(
                Icons.bolt_rounded,
                color: AppColors.solarGold,
                size: 24,
              ),
              suffixText: _isBangla ? 'kWh / দিন' : 'kWh / Day',
              suffixStyle: TextStyle(
                color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                fontSize: 13,
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
              activeTrackColor: AppColors.solarGold,
              inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
              thumbColor: AppColors.solarGold,
              overlayColor: AppColors.solarGold.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: currentVal.clamp(1.0, sliderMax),
              min: 1.0,
              max: sliderMax,
              onChanged: (v) {
                setState(() {
                  _demandController.text = v.toStringAsFixed(0);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationCard(bool isDark) {
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
                ? 'সিস্টেম ও প্যানেল কনফিগারেশন'
                : 'System & Module Configuration',
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isBangla ? 'প্যানেল দক্ষতা' : 'Efficiency',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightInputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: DropdownButton<double>(
                        value: _selectedModuleEfficiency,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightCardBg,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.accentCyan
                              : const Color(0xFF0284C7),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 0.170,
                            child: Text('17.0% (Poly)'),
                          ),
                          DropdownMenuItem(
                            value: 0.190,
                            child: Text('19.0% (Mono)'),
                          ),
                          DropdownMenuItem(
                            value: 0.215,
                            child: Text('21.5% (PERC)'),
                          ),
                          DropdownMenuItem(
                            value: 0.225,
                            child: Text('22.5% (TOPCon)'),
                          ),
                          DropdownMenuItem(
                            value: 0.235,
                            child: Text('23.5% (HJT)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedModuleEfficiency = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isBangla ? 'মডিউল ক্ষমতা' : 'Rating',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightInputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: DropdownButton<int>(
                        value: _selectedModuleWatt,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightCardBg,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.accentCyan
                              : const Color(0xFF0284C7),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                        items: const [
                          DropdownMenuItem(value: 150, child: Text('150 W')),
                          DropdownMenuItem(value: 250, child: Text('250 W')),
                          DropdownMenuItem(value: 330, child: Text('330 W')),
                          DropdownMenuItem(value: 400, child: Text('400 W')),
                          DropdownMenuItem(value: 450, child: Text('450 W')),
                          DropdownMenuItem(value: 550, child: Text('550 W')),
                          DropdownMenuItem(value: 620, child: Text('620 W')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedModuleWatt = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedSystemType != SolarSystemType.gridTied) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isBangla ? 'কাঙ্ক্ষিত ব্যাটারি ব্যাকআপ' : 'Required Backup',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '$_backupHours ${_isBangla ? "ঘণ্টা" : "Hours"}',
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.purpleAccent,
                thumbColor: Colors.purpleAccent,
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _backupHours.toDouble(),
                min: 2,
                max: 12,
                divisions: 10,
                onChanged: (v) => setState(() => _backupHours = v.round()),
              ),
            ),
          ],
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
        onTap: () => setState(() => _selectedSystemType = type),
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

  void _showProposalSummaryDialog({
    required double dailyDemandKwh,
    required double capacityKwp,
    required int totalPanels,
    required double roofAreaSqFt,
    required double inverterKw,
    required double batteryBankKwh,
    required int strings,
    required int panelsPerString,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.solar_power_rounded,
              color: isDark ? AppColors.accentCyan : AppColors.energyGreen,
            ),
            const SizedBox(width: 8),
            Text(
              _isBangla ? 'সিস্টেম ডিজাইন প্রপোজাল' : 'System Design Proposal',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow(
                _isBangla ? 'দৈনিক লক্ষ্যমাত্রা' : 'Daily Target',
                '${dailyDemandKwh.toStringAsFixed(1)} kWh/day',
                isDark: isDark,
              ),
              _buildSummaryRow(
                _isBangla ? 'ডিসি ক্যাপাসিটি' : 'DC Solar Capacity',
                '${capacityKwp.toStringAsFixed(2)} kWp',
                isDark: isDark,
              ),
              _buildSummaryRow(
                _isBangla ? 'মডিউল স্পেসিফিকেশন' : 'Module Rating',
                '$totalPanels pcs × $_selectedModuleWatt W',
                isDark: isDark,
              ),
              _buildSummaryRow(
                _isBangla ? 'স্ট্রিং কনফিগারেশন' : 'String Setup',
                '$strings Strings × $panelsPerString Panels',
                isDark: isDark,
              ),
              _buildSummaryRow(
                _isBangla ? 'প্রস্তাবিত ইনভার্টার' : 'Inverter Capacity',
                '${inverterKw.toStringAsFixed(1)} kW',
                isDark: isDark,
              ),
              _buildSummaryRow(
                _isBangla ? 'প্রয়োজনীয় নেট জায়গা' : 'Required Net Area',
                '${roofAreaSqFt.toStringAsFixed(0)} sq.ft',
                isDark: isDark,
              ),
              if (_selectedSystemType != SolarSystemType.gridTied)
                _buildSummaryRow(
                  _isBangla ? 'ব্যাটারি ব্যাংক' : 'Battery Bank',
                  '${batteryBankKwh.toStringAsFixed(1)} kWh',
                  isDark: isDark,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _isBangla ? 'বন্ধ করুন' : 'Close',
              style: TextStyle(
                color: isDark ? AppColors.accentCyan : AppColors.energyGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class SeasonalComparisonChart extends StatelessWidget {
  final Map<String, double> monthlyPsh;
  final double capacityKwp;
  final double effectivePR;
  final double targetDailyKwh;
  final bool isDark;

  const SeasonalComparisonChart({
    super.key,
    required this.monthlyPsh,
    required this.capacityKwp,
    required this.effectivePR,
    required this.targetDailyKwh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, double> monthlyGen = {};
    for (var entry in monthlyPsh.entries) {
      monthlyGen[entry.key] = capacityKwp * entry.value * effectivePR;
    }

    final double maxVal = math.max(
      targetDailyKwh * 1.3,
      monthlyGen.values.isNotEmpty
          ? monthlyGen.values.reduce(math.max) * 1.15
          : 10.0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double targetY =
            constraints.maxHeight -
            18 -
            (targetDailyKwh / maxVal) * (constraints.maxHeight - 18);

        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: targetY.clamp(0.0, constraints.maxHeight - 20),
              child: CustomPaint(
                size: Size(constraints.maxWidth, 2),
                painter: DashedLinePainter(color: AppColors.alertRed),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: monthlyGen.entries.map((entry) {
                      final double barRatio = (entry.value / maxVal).clamp(
                        0.05,
                        1.0,
                      );
                      final bool isSurplus = entry.value >= targetDailyKwh;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                entry.value.toStringAsFixed(0),
                                style: TextStyle(
                                  color: isSurplus
                                      ? AppColors.energyGreen
                                      : AppColors.solarGold,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                height: (constraints.maxHeight - 32) * barRatio,
                                decoration: BoxDecoration(
                                  color: isSurplus
                                      ? (isDark
                                            ? AppColors.accentCyan
                                            : const Color(0xFF0284C7))
                                      : AppColors.solarGold.withValues(
                                          alpha: 0.8,
                                        ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: monthlyGen.keys.map((m) {
                    return Expanded(
                      child: Text(
                        m.substring(0, 1),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : AppColors.lightTextSecondary,
                          fontSize: 9,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    const double dashWidth = 4.0;
    const double dashSpace = 3.0;
    double startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
