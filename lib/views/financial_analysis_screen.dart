import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../models/system_sizing_params.dart';
import '../services/solar_calculation_service.dart';
import '../services/solar_radiation_service.dart';
import '../services/tariff_config_service.dart';
import '../widgets/theme_toggle_button.dart';

class FinancialAnalysisScreen extends StatefulWidget {
  final bool isBangla;
  final VoidCallback? onToggleLanguage;

  const FinancialAnalysisScreen({
    super.key,
    this.isBangla = true,
    this.onToggleLanguage,
  });

  @override
  State<FinancialAnalysisScreen> createState() =>
      _FinancialAnalysisScreenState();
}

class _FinancialAnalysisScreenState extends State<FinancialAnalysisScreen> {
  late bool _isBangla;

  TariffConfig _tariffConfig = TariffConfig.defaultConfig();

  // ইনপুট কন্ট্রোলার ও ভ্যারিয়েবলসমূহ
  final TextEditingController _billController = TextEditingController(
    text: '5000',
  );
  final TextEditingController _sanctionedLoadController = TextEditingController(
    text: '10',
  );
  final TextEditingController _customTariffController = TextEditingController(
    text: '8.50',
  );

  double _systemCapacityKw = 5.0; // কিলোওয়াট পিক (kWp)
  SolarSystemType _selectedSystemType = SolarSystemType.gridTied;
  String _selectedCategory =
      'residential'; // residential, commercial, institutional, custom
  double _costPerWatt = 70.0; // টাকা/ওয়াট

  bool _isLoadingNasa = false;
  SolarRadiationResult? _climateData;

  static const double _defaultLat = 23.8103;
  static const double _defaultLon = 90.4125;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _initTariffAndSync();
    _fetchClimateData();
  }

  Future<void> _initTariffAndSync() async {
    final config = await TariffConfigService.getActiveConfig();
    if (mounted) {
      setState(() {
        _tariffConfig = config;
        _costPerWatt = config.costPerWatt;
      });
    }
    await TariffConfigService.syncRemoteConfig();
  }

  @override
  void dispose() {
    _billController.dispose();
    _sanctionedLoadController.dispose();
    _customTariffController.dispose();
    super.dispose();
  }

  Future<void> _fetchClimateData() async {
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

  double _getEffectiveTariff() {
    switch (_selectedCategory) {
      case 'residential':
        return _tariffConfig.residential;
      case 'commercial':
        return _tariffConfig.commercial;
      case 'institutional':
        return _tariffConfig.institutional;
      case 'custom':
        return double.tryParse(_customTariffController.text) ??
            _tariffConfig.residential;
      default:
        return _tariffConfig.residential;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double currentMonthlyBill =
        double.tryParse(_billController.text.replaceAll(',', '')) ?? 0.0;
    final double sanctionedLoad =
        double.tryParse(_sanctionedLoadController.text.replaceAll(',', '')) ??
        0.0;
    final double gridTariff = _getEffectiveTariff();

    // ডিপিডিসি অনুমোদিত লোড ক্যাপ (৭০%)
    final double maxAllowedSolarKw = sanctionedLoad * 0.70;
    final bool isExceedingSanctionedCap =
        sanctionedLoad > 0 && _systemCapacityKw > maxAllowedSolarKw;

    // নাসা ও ক্লাইমেট প্যারামিটার
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

    // ১. মাসিক ও বাৎসরিক উৎপাদন হিসাব
    final double dailyGenKwh = _systemCapacityKw * psh * effectivePR;
    final double monthlyGenKwh = dailyGenKwh * 30.0;
    final double annualGenKwh = dailyGenKwh * 365.0;

    // ২. আর্থিক সাশ্রয়
    final double grossMonthlySolarVal = monthlyGenKwh * gridTariff;
    final double monthlySavings = math.min(
      grossMonthlySolarVal,
      math.max(currentMonthlyBill, 1.0),
    );
    final double annualSavings = monthlySavings * 12.0;
    final double savingsPercentage = currentMonthlyBill > 0
        ? ((monthlySavings / currentMonthlyBill) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    // ৩. মোট মূলধনী খরচ (CAPEX)
    final double totalCapex = _systemCapacityKw * 1000.0 * _costPerWatt;

    // ৪. পে-ব্যাক সময়কাল
    final double paybackYears = annualSavings > 0
        ? (totalCapex / annualSavings)
        : 0.0;

    // ৫. ২৫ বছরের লাইফসাইকেল নেট প্রফিট
    double lifecycleTotalSolarRevenue = 0.0;
    double currentYearSavings = annualSavings;
    for (int y = 1; y <= 25; y++) {
      lifecycleTotalSolarRevenue += currentYearSavings;
      currentYearSavings *= 0.995; // বার্ষিক ০.৫% অবক্ষয়
    }
    final double inverterReplacement = totalCapex * 0.20;
    final double lifecycleNetProfit =
        lifecycleTotalSolarRevenue - totalCapex - inverterReplacement;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isBangla ? 'আর্থিক বিশ্লেষণ' : 'Financial Analysis',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          ThemeToggleButton(isBangla: _isBangla),
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // [১] নাসা ও আবহাওয়া হেডার
              _buildClimateHeader(psh, ambTemp, effectivePR, isDark),
              const SizedBox(height: 14),

              // [২] ইনপুট কনসোল
              _buildInputConsoleCard(
                currentMonthlyBill,
                sanctionedLoad,
                gridTariff,
                isExceedingSanctionedCap,
                maxAllowedSolarKw,
                isDark,
              ),
              const SizedBox(height: 18),

              // [৩] মূল ফলাফল কেপিআই ড্যাশবোর্ড
              Text(
                _isBangla
                    ? 'আর্থিক লাভ-ক্ষতি পর্যালোচনা'
                    : 'Financial Feasibility Metrics',
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
                  _buildKpiCard(
                    title: _isBangla ? 'মাসিক সাশ্রয়' : 'Monthly Savings',
                    value: '৳ ${monthlySavings.toStringAsFixed(0)}',
                    subtitle: _isBangla
                        ? 'বাৎসরিক: ৳ ${(annualSavings / 1000).toStringAsFixed(1)}k'
                        : 'Annual: ৳ ${(annualSavings / 1000).toStringAsFixed(1)}k',
                    icon: Icons.savings_rounded,
                    color: AppColors.energyGreen,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    title: _isBangla ? 'বিদ্যুৎ বিল সাশ্রয়' : 'Bill Offset',
                    value: '${savingsPercentage.toStringAsFixed(0)}%',
                    subtitle: _isBangla
                        ? '${monthlyGenKwh.toStringAsFixed(0)} ইউনিট উৎপাদিত'
                        : '${monthlyGenKwh.toStringAsFixed(0)} Units Gen',
                    icon: Icons.pie_chart_rounded,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildKpiCard(
                    title: _isBangla
                        ? 'বিনিয়োগ পরিশোধ (Payback)'
                        : 'Est. Payback Time',
                    value: paybackYears > 0
                        ? '${paybackYears.toStringAsFixed(1)} ${_isBangla ? "বছর" : "Years"}'
                        : 'N/A',
                    subtitle: _isBangla
                        ? 'মোট খরচ: ৳ ${(totalCapex / 1000).toStringAsFixed(0)}k'
                        : 'Total Cost: ৳ ${(totalCapex / 1000).toStringAsFixed(0)}k',
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.solarGold,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    title: _isBangla ? '২৫ বছরের নিট লাভ' : '25-Yr Net Profit',
                    value: lifecycleNetProfit > 0
                        ? '৳ ${(lifecycleNetProfit / 100000).toStringAsFixed(1)} লাখ'
                        : '৳ 0.0',
                    subtitle: _isBangla
                        ? 'রক্ষণাবেক্ষণ সমন্বিত'
                        : 'Degradation adjusted',
                    icon: Icons.monetization_on_rounded,
                    color: isDark ? Colors.tealAccent : const Color(0xFF0D9488),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // [৪] ২৫ বছরের লাইফসাইকেল রিটার্ন টাইমলাইন বার
              if (paybackYears > 0 && paybackYears <= 25)
                _buildPaybackTimelineCard(paybackYears, isDark),
              const SizedBox(height: 16),

              // [৫] প্রাক্কলিত সরঞ্জাম তালিকা ও খরচ বণ্টন
              _buildEquipmentAndBOMCard(totalCapex, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClimateHeader(
    double psh,
    double ambTemp,
    double effectivePR,
    bool isDark,
  ) {
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
            Icons.solar_power_rounded,
            color: isDark ? AppColors.accentCyan : AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBangla
                      ? 'নাসা সোলার ও ক্লাইমেট প্যারামিটার'
                      : 'NASA Solar Climate Data',
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
                      ? 'PSH: ${psh.toStringAsFixed(2)} ঘণ্টা | তাপমাত্রা: ${ambTemp.toStringAsFixed(1)}°C | PR: ${(effectivePR * 100).toStringAsFixed(0)}%'
                      : 'PSH: ${psh.toStringAsFixed(2)} hrs | Temp: ${ambTemp.toStringAsFixed(1)}°C | PR: ${(effectivePR * 100).toStringAsFixed(0)}%',
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
              onPressed: _fetchClimateData,
            ),
        ],
      ),
    );
  }

  Widget _buildInputConsoleCard(
    double currentBill,
    double sanctionedLoad,
    double gridTariff,
    bool isExceedingCap,
    double maxAllowedKw,
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
          Text(
            _isBangla
                ? 'গ্রাহক শ্রেণি ও বিদ্যুৎ ট্যারিফ'
                : 'Consumer Category & Tariff',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildCategoryChip(
                'residential',
                _isBangla ? 'আবাসিক' : 'Home',
                isDark,
              ),
              const SizedBox(width: 6),
              _buildCategoryChip(
                'commercial',
                _isBangla ? 'বাণিজ্যিক' : 'Commercial',
                isDark,
              ),
              const SizedBox(width: 6),
              _buildCategoryChip(
                'institutional',
                _isBangla ? 'প্রতিষ্ঠান' : 'Institute',
                isDark,
              ),
              const SizedBox(width: 6),
              _buildCategoryChip(
                'custom',
                _isBangla ? 'কাস্টম' : 'Custom',
                isDark,
              ),
            ],
          ),
          if (_selectedCategory == 'custom') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customTariffController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: _isBangla
                    ? 'ট্যারিফ রেট (টাকা/kWh)'
                    : 'Tariff Rate (BDT/kWh)',
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? AppColors.darkInputBg
                    : AppColors.lightInputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              _isBangla
                  ? 'বর্তমান গড় গ্রিড ট্যারিফ: ৳ ${gridTariff.toStringAsFixed(2)} / ইউনিট (kWh)'
                  : 'Effective Grid Tariff: ৳ ${gridTariff.toStringAsFixed(2)} / Unit (kWh)',
              style: TextStyle(
                color: isDark ? AppColors.accentCyan : const Color(0xFF0284C7),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          Divider(height: 22, color: isDark ? Colors.white12 : Colors.black12),

          // বর্তমান মাসিক বিল ও অনুমোদিত লোড
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isBangla ? 'মাসিক বিদ্যুৎ বিল' : 'Monthly Bill',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _billController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightInputBg,
                        prefixText: '৳ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isBangla ? 'অনুমোদিত লোড' : 'Sanctioned Load',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _sanctionedLoadController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightInputBg,
                        suffixText: 'kW',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 22, color: isDark ? Colors.white12 : Colors.black12),

          // সোলার সিস্টেমের সাইজ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'প্রস্তাবিত সোলার ক্ষমতা'
                    : 'Proposed Solar Capacity',
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
                  color: AppColors.energyGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_systemCapacityKw.toStringAsFixed(1)} kWp',
                  style: const TextStyle(
                    color: AppColors.energyGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.energyGreen,
              thumbColor: AppColors.energyGreen,
              trackHeight: 4,
            ),
            child: Slider(
              value: _systemCapacityKw,
              min: 1.0,
              max: 50.0,
              divisions: 98,
              onChanged: (v) => setState(() => _systemCapacityKw = v),
            ),
          ),

          // ডিপিডিসি নির্দেশিকা সংক্রান্ত সতর্কবার্তা
          if (isExceedingCap) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.solarGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.solarGold.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.solarGold,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isBangla
                          ? 'ডিপিডিসি নেট-মিটারিং নীতিমালা অনুযায়ী সোলার ক্যাপাসিটি অনুমোদিত লোডের সর্বোচ্চ ৭০% (অর্থাৎ ${maxAllowedKw.toStringAsFixed(1)} kW) হওয়া বাঞ্ছনীয়।'
                          : 'Per Net-Metering rules, solar capacity should not exceed 70% of sanctioned load (${maxAllowedKw.toStringAsFixed(1)} kW).',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark
                            ? AppColors.solarGold
                            : const Color(0xFFB45309),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String catKey, String label, bool isDark) {
    final bool isSelected = _selectedCategory == catKey;
    final Color activeColor = isDark
        ? AppColors.accentCyan
        : AppColors.primaryGreen;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = catKey),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.18)
                : (isDark ? AppColors.darkInputBg : AppColors.lightInputBg),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : activeColor)
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

  Widget _buildKpiCard({
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
                _isBangla ? 'মোট আয়ুষ্কাল: ২৫ বছর' : 'Total Lifecycle: 25 yrs',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
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
                _isBangla
                    ? '${freeYears.toStringAsFixed(1)} বছর বিনামূল্যে বিদ্যুৎ'
                    : '${freeYears.toStringAsFixed(1)} Yrs Free Power',
                style: const TextStyle(
                  color: AppColors.energyGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentAndBOMCard(double totalCapex, bool isDark) {
    final double panelCost = totalCapex * 0.48;
    final double inverterCost = totalCapex * 0.22;
    final double structureAndBosCost = totalCapex * 0.30;

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
                ? 'প্রাক্কলিত সরঞ্জাম ও খরচ বিভাজন (DPDC স্ট্যান্ডার্ড)'
                : 'Estimated Equipment & Cost Distribution',
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
            _isBangla ? 'সোলার পিভি মডিউল' : 'Solar PV Modules',
            panelCost,
            Colors.amberAccent,
            isDark,
          ),
          _buildBreakdownRow(
            _isBangla
                ? 'গ্রিড-টাই ইনভার্টার ও সুরক্ষা'
                : 'Grid-Tie Inverter & Protection',
            inverterCost,
            Colors.cyanAccent,
            isDark,
          ),
          _buildBreakdownRow(
            _isBangla
                ? 'মাউন্টিং স্ট্রাকচার, কেবলিং ও নেট-মিটারিং'
                : 'Mounting, Cabling & Net-Meter',
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
            '৳ ${amount.toStringAsFixed(0)}',
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
}
