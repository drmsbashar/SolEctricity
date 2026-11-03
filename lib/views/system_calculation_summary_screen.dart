import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/solar_calculation_result.dart';
import '../models/system_sizing_params.dart';
import '../services/pdf_report_service.dart';
import '../widgets/theme_toggle_button.dart';
import 'system_diagram_screen.dart';

class SystemCalculationSummaryScreen extends StatefulWidget {
  final SolarCalculationResult result;
  final SystemSizingParams params;
  final bool isBangla;
  final VoidCallback onProceedToDiagram;

  const SystemCalculationSummaryScreen({
    super.key,
    required this.result,
    required this.params,
    this.isBangla = true,
    required this.onProceedToDiagram,
  });

  @override
  State<SystemCalculationSummaryScreen> createState() =>
      _SystemCalculationSummaryScreenState();
}

class _SystemCalculationSummaryScreenState
    extends State<SystemCalculationSummaryScreen> {
  late bool _isBangla;
  bool _showPvDetails = false;
  bool _showBatteryDetails = false;
  bool _showProtectionDetails = false;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
  }

  void _toggleLanguage() {
    setState(() {
      _isBangla = !_isBangla;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final result = widget.result;
    final params = widget.params;
    final isGridTied = params.systemType == SolarSystemType.gridTied;
    final isHybrid = params.systemType == SolarSystemType.hybrid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isBangla ? 'সিস্টেম ক্যালকুলেশন সামারি' : 'System Sizing Summary',
        ),
        actions: [
          // 📄 পিডিএফ রিপোর্ট শেয়ার বাটন
          IconButton(
            tooltip: _isBangla ? 'রিপোর্ট শেয়ার করুন' : 'Share PDF Report',
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              PdfReportService.shareOrPrintReport(result, params, _isBangla);
            },
          ),
          // ভাষা পরিবর্তন বাটন
          IconButton(
            onPressed: _toggleLanguage,
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
          // হোম বাটন
          IconButton(
            tooltip: _isBangla ? 'হোম / ড্যাশবোর্ড' : 'Dashboard / Home',
            icon: const Icon(Icons.home_rounded),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ১. মোট চাহিদা কার্ড
                    _buildDarkDemandHeaderCard(result, params, isDark),
                    const SizedBox(height: 14),

                    // ২. সোলার পিভি অ্যারে কার্ড
                    _buildPvArrayCard(result, params, isDark),
                    const SizedBox(height: 14),

                    // ৩. ব্যাটারি ব্যাংক কার্ড (অন-গ্রিড হলে সম্পূর্ণ বাদ)
                    if (!isGridTied) ...[
                      _buildBatteryBankCard(result, params, isDark),
                      const SizedBox(height: 14),
                    ],

                    // ৪. পাওয়ার ইলেকট্রনিক্স কার্ড
                    _buildPowerElectronicsCard(result, params, isDark),
                    const SizedBox(height: 14),

                    // ৫. সুরক্ষাব্যবস্থা ও তারের সাইজ কার্ড
                    _buildProtectionAndCablesCard(result, params, isDark),
                    const SizedBox(height: 14),

                    // ৬. সিস্টেম রিক্যাপ কার্ড
                    _buildSystemSpecsRecapCard(result, params, isDark),
                  ],
                ),
              ),
            ),

            // নিচে ওয়্যারিং ডায়াগ্রামের অ্যাকশন বাটন
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.energyGreen
                          : AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: widget.onProceedToDiagram,
                    icon: const Icon(
                      Icons.account_tree_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isBangla
                          ? 'সংযোগ ডায়াগ্রাম দেখুন'
                          : 'View Wiring Diagram',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkDemandHeaderCard(
    SolarCalculationResult result,
    SystemSizingParams params,
    bool isDark,
  ) {
    String archLabel;
    switch (params.systemType) {
      case SolarSystemType.gridTied:
        archLabel = _isBangla ? 'অন-গ্রিড নেট মিটার' : 'On-Grid Net Meter';
        break;
      case SolarSystemType.hybrid:
        archLabel = _isBangla ? 'হাইব্রিড সিস্টেম' : 'Hybrid System';
        break;
      case SolarSystemType.offGrid:
        archLabel = '${params.systemVoltage.toInt()}V DC Bus';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF0F3822), const Color(0xFF1B6A3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.green.shade900,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'দৈনিক মোট শক্তি চাহিদা'
                    : 'Total Daily Energy Load',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.solarGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  archLabel,
                  style: const TextStyle(
                    color: AppColors.solarGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                result.totalDailyWh.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Wh/day',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (params.systemType != SolarSystemType.gridTied)
                Text(
                  '≈ ${result.energyDemandAh.toStringAsFixed(1)} Ah/day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          if (result.hasAcLoad &&
              result.hasDcLoad &&
              params.systemType != SolarSystemType.gridTied) ...[
            const SizedBox(height: 10),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AC: ${result.dailyAcWh.toStringAsFixed(0)} Wh',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  'DC: ${result.dailyDcWh.toStringAsFixed(0)} Wh',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPvArrayCard(
    SolarCalculationResult result,
    SystemSizingParams params,
    bool isDark,
  ) {
    return _buildSectionCard(
      title: _isBangla ? 'সোলার পিভি অ্যারে' : 'Solar PV Array',
      icon: Icons.solar_power_rounded,
      highlightText: '${result.totalArrayWatt.toInt()} Wp',
      isDark: isDark,
      children: [
        _buildHighlightBadge(
          title: _isBangla ? 'প্রয়োজনীয় মোট প্যানেল' : 'Required Solar Panels',
          value:
              '${result.totalPanels} ${_isBangla ? "টি" : "pcs"} (${params.panelPmax.toInt()} Wp)',
          icon: Icons.view_module_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildSimpleConnectionBadge(
          text: _isBangla
              ? 'সংযোগ বিন্যাস: প্রতি সারিতে ${result.panelsSeries}টি করে মোট ${result.panelsParallel}টি সারি'
              : 'Wiring: ${result.panelsSeries} in Series × ${result.panelsParallel} Strings Parallel',
          isDark: isDark,
        ),
        _buildDisclosureToggle(
          isExpanded: _showPvDetails,
          isDark: isDark,
          onTap: () => setState(() => _showPvDetails = !_showPvDetails),
        ),
        if (_showPvDetails) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla ? 'সিরিজ সংযোগ (PVs)' : 'Series (PVs)',
                  value: '${result.panelsSeries} ${_isBangla ? "টি" : "Units"}',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla
                      ? 'প্যারালাল স্ট্রিং (PVp)'
                      : 'Parallel (PVp)',
                  value:
                      '${result.panelsParallel} ${_isBangla ? "স্ট্রিং" : "Strings"}',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: 'Array Vmp / Voc',
                  value:
                      '${result.arrayVmp.toStringAsFixed(1)}V / ${result.arrayVoc.toStringAsFixed(1)}V',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailMetric(
                  label: 'Array Imp / Isc',
                  value:
                      '${result.arrayImp.toStringAsFixed(1)}A / ${result.arrayIsc.toStringAsFixed(1)}A',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBatteryBankCard(
    SolarCalculationResult result,
    SystemSizingParams params,
    bool isDark,
  ) {
    return _buildSectionCard(
      title: _isBangla ? 'ব্যাটারি স্টোরেজ ব্যাংক' : 'Battery Storage Bank',
      icon: Icons.battery_charging_full_rounded,
      highlightText:
          '${result.batteryCapacityAh.toStringAsFixed(0)} Ah (${params.systemVoltage.toInt()}V)',
      isDark: isDark,
      children: [
        _buildHighlightBadge(
          title: _isBangla ? 'প্রয়োজনীয় ব্যাটারি' : 'Total Batteries Required',
          value:
              '${result.totalBatteries} ${_isBangla ? "টি" : "pcs"} (${params.batteryCapacityAh.toInt()} Ah @ 12V)',
          icon: Icons.layers_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildSimpleConnectionBadge(
          text: _isBangla
              ? 'ব্যাকআপ স্থায়িত্ব: ${params.autonomyDays} দিন (মেঘলা আকাশ)'
              : 'Backup Autonomy: ${params.autonomyDays} Day(s) (Cloudy weather)',
          isDark: isDark,
        ),
        _buildDisclosureToggle(
          isExpanded: _showBatteryDetails,
          isDark: isDark,
          onTap: () =>
              setState(() => _showBatteryDetails = !_showBatteryDetails),
        ),
        if (_showBatteryDetails) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla ? 'সিরিজে ব্যাটারি (Bs)' : 'Series (Bs)',
                  value:
                      '${result.batteriesSeries} ${_isBangla ? "টি" : "Units"}',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla
                      ? 'প্যারালালে স্ট্রিং (Bp)'
                      : 'Parallel (Bp)',
                  value:
                      '${result.batteriesParallel} ${_isBangla ? "স্ট্রিং" : "Strings"}',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: 'Depth of Discharge (DoD)',
                  value: '${params.batteryDod.toInt()}%',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla
                      ? 'ব্যাটারি এফিসিয়েন্সি'
                      : 'Battery Efficiency',
                  value: '${params.batteryEfficiency.toInt()}%',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPowerElectronicsCard(
    SolarCalculationResult result,
    SystemSizingParams params,
    bool isDark,
  ) {
    final isGridTied = params.systemType == SolarSystemType.gridTied;
    final isHybrid = params.systemType == SolarSystemType.hybrid;

    return _buildSectionCard(
      title: _isBangla
          ? 'পাওয়ার ইলেকট্রনিক্স রেটিং'
          : 'Power Electronics Specs',
      icon: Icons.settings_input_component_rounded,
      isDark: isDark,
      children: [
        if (!isGridTied && !isHybrid) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        (isDark ? AppColors.accentCyan : AppColors.primaryGreen)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: isDark
                        ? AppColors.accentCyan
                        : AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isBangla
                            ? 'সোলার চার্জ কন্ট্রোলার'
                            : 'Solar Charge Controller',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${result.controllerVoltage.toInt()}V, ≥ ${result.controllerAmpere.toInt()}A (${result.controllerType.toUpperCase()})',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (isDark ? AppColors.accentCyan : AppColors.primaryGreen)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isGridTied
                      ? Icons.solar_power_rounded
                      : (isHybrid
                            ? Icons.sync_alt_rounded
                            : Icons.power_rounded),
                  color: isDark ? AppColors.accentCyan : AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isGridTied
                              ? (_isBangla
                                    ? 'অন-গ্রিড স্ট্রিং ইনভার্টার'
                                    : 'Grid-Tied String Inverter')
                              : (isHybrid
                                    ? (_isBangla
                                          ? 'সোলার হাইব্রিড ইনভার্টার'
                                          : 'Solar Hybrid Inverter')
                                    : (_isBangla
                                          ? 'অফ-গ্রিড ইনভার্টার'
                                          : 'Off-Grid Inverter')),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppColors.accentCyan
                                        : AppColors.primaryGreen)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isGridTied
                                ? 'Net Metering'
                                : (isHybrid
                                      ? 'Built-in MPPT'
                                      : 'Pure Sine Wave'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.accentCyan
                                  : AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGridTied
                          ? '${(result.inverterCapacityVa / 1000).toStringAsFixed(1)} kW (220V/50Hz On-Grid)'
                          : '${result.inverterVoltage.toInt()}V DC ➔ 220V AC, ≥ ${result.inverterCapacityVa.toInt()} VA',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProtectionAndCablesCard(
    SolarCalculationResult result,
    SystemSizingParams params,
    bool isDark,
  ) {
    final isGridTied = params.systemType == SolarSystemType.gridTied;
    final isHybrid = params.systemType == SolarSystemType.hybrid;

    return _buildSectionCard(
      title: _isBangla
          ? 'সুরক্ষাব্যবস্থা ও ওয়্যারিং ক্যাবল'
          : 'Protection & Wiring Cables',
      icon: Icons.security_rounded,
      isDark: isDark,
      children: [
        _buildDisclosureToggle(
          isExpanded: _showProtectionDetails,
          isDark: isDark,
          onTap: () =>
              setState(() => _showProtectionDetails = !_showProtectionDetails),
        ),
        if (_showProtectionDetails) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla
                      ? 'পিভি ডিসি ব্রেকার (DC MCB)'
                      : 'PV Array DC Breaker',
                  value: '≥ ${result.pvBreakerAmp.toInt()} A',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailMetric(
                  label: isGridTied
                      ? (_isBangla ? 'এসি গ্রিড ব্রেকার' : 'AC Grid MCB')
                      : (_isBangla ? 'ব্যাটারি ডিসি ফিউজ' : 'Battery DC Fuse'),
                  value: isGridTied
                      ? '≥ ${result.acBreakerAmp.toInt()} A'
                      : '≥ ${result.batteryFuseAmp.toInt()} A',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (!isGridTied) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (result.hasAcLoad)
                  Expanded(
                    child: _buildDetailMetric(
                      label: _isBangla
                          ? 'ইনভার্টার এসি ব্রেকার'
                          : 'AC Output Breaker',
                      value: '≥ ${result.acBreakerAmp.toInt()} A (220V)',
                      isDark: isDark,
                    ),
                  ),
                if (result.hasAcLoad && !isHybrid) const SizedBox(width: 8),
                if (!isHybrid)
                  Expanded(
                    child: _buildDetailMetric(
                      label: _isBangla
                          ? 'কন্ট্রোলার-ব্যাটারি ব্রেকার'
                          : 'SCC Battery Breaker',
                      value: '≥ ${result.chargeControllerBreakerAmp.toInt()} A',
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla
                      ? 'পিভি তারের মাপ (কপার)'
                      : 'PV Array Cable Size',
                  value: result.pvCableSizeMm,
                  isDark: isDark,
                ),
              ),
              if (!isGridTied) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDetailMetric(
                    label: _isBangla
                        ? 'ব্যাটারি তারের মাপ'
                        : 'Battery Cable Size',
                    value: result.batteryCableSizeMm,
                    isDark: isDark,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSystemSpecsRecapCard(
    SolarCalculationResult result,
    SystemSizingParams params,
    bool isDark,
  ) {
    String recapText;
    if (params.systemType == SolarSystemType.gridTied) {
      recapText = _isBangla
          ? 'আপনার দৈনিক ${result.totalDailyWh.toStringAsFixed(0)} Wh চাহিদার জন্য মোট ${result.totalPanels}টি ${params.panelPmax.toInt()}Wp প্যানেল এবং একটি ${(result.inverterCapacityVa / 1000).toStringAsFixed(1)} kW অন-গ্রিড নেট-মিটারিং ইনভার্টার সুপারিশ করা হলো (ব্যাটারিহীন সিস্টেম)।'
          : 'For your daily ${result.totalDailyWh.toStringAsFixed(0)} Wh load, ${result.totalPanels}x ${params.panelPmax.toInt()}Wp panels with a ${(result.inverterCapacityVa / 1000).toStringAsFixed(1)} kW Grid-Tied Inverter is recommended.';
    } else {
      recapText = _isBangla
          ? 'আপনার দৈনিক ${result.totalDailyWh.toStringAsFixed(0)} Wh চাহিদার জন্য মোট ${result.totalPanels}টি ${params.panelPmax.toInt()}Wp প্যানেল এবং ${result.totalBatteries}টি ${params.batteryCapacityAh.toInt()}Ah ব্যাটারির এই কনফিগারেশনটি সুপারিশ করা হলো।'
          : 'For your daily ${result.totalDailyWh.toStringAsFixed(0)} Wh load, a balanced system of ${result.totalPanels}x ${params.panelPmax.toInt()}Wp panels and ${result.totalBatteries}x ${params.batteryCapacityAh.toInt()}Ah batteries is recommended.';
    }

    final activeColor = isDark ? AppColors.accentCyan : AppColors.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: activeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: activeColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              recapText,
              style: TextStyle(
                fontSize: 12,
                color: activeColor,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? highlightText,
    required List<Widget> children,
    required bool isDark,
  }) {
    final activeColor = isDark ? AppColors.accentCyan : AppColors.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: activeColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: activeColor,
                    ),
                  ),
                ],
              ),
              if (highlightText != null)
                Text(
                  highlightText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: activeColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHighlightBadge({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    final activeColor = isDark ? AppColors.accentCyan : AppColors.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: activeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleConnectionBadge({
    required String text,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hub_outlined,
            size: 14,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclosureToggle({
    required bool isExpanded,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = isDark ? AppColors.accentCyan : AppColors.primaryGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isExpanded
                  ? (_isBangla ? 'কারিগরি তথ্য লুকান' : 'Hide Technical Specs')
                  : (_isBangla
                        ? 'বিস্তারিত কারিগরি স্পেসিফিকেশন দেখুন'
                        : 'Show Technical Specs'),
              style: TextStyle(
                fontSize: 11.5,
                color: activeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
              color: activeColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailMetric({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
