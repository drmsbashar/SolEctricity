import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/solar_calculation_result.dart';
import '../models/system_sizing_params.dart';
import '../services/pdf_report_service.dart';
import '../services/solar_calculation_service.dart';
import '../widgets/app_bar_title.dart';

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

  // 💰 পরিবর্তনশীল বাজার দর ভ্যারিয়েবল
  double? _customRatePerWatt;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _initDefaultRate();
  }

  void _initDefaultRate() {
    final isGridTied = widget.params.systemType == SolarSystemType.gridTied;
    final isHybrid = widget.params.systemType == SolarSystemType.hybrid;

    if (isGridTied) {
      _customRatePerWatt = 70.0;
    } else if (isHybrid) {
      _customRatePerWatt = 110.0;
    } else {
      _customRatePerWatt = 125.0;
    }
  }

  void _toggleLanguage() {
    setState(() {
      _isBangla = !_isBangla;
    });
  }

  void _openRateEditorDialog(bool isDark) {
    final controller = TextEditingController(
      text: _customRatePerWatt?.toStringAsFixed(0) ?? '70',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isBangla
                  ? 'প্রতি ওয়াট সিস্টেম খরচ নির্ধারণ করুন'
                  : 'Set Turnkey Cost per Watt',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isBangla
                  ? 'লোকাল বাজারের সরঞ্জাম ও ইনস্টলেশন দর অনুযায়ী প্রতি ওয়াটের রেট (টাকা/Wp) লিখুন:'
                  : 'Enter current market turnkey rate per watt (BDT/Wp):',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                prefixText: '৳ ',
                suffixText: '/ Wp',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.check_circle_rounded,
                    color: isDark
                        ? AppColors.accentCyan
                        : AppColors.primaryGreen,
                  ),
                  onPressed: () {
                    final val = double.tryParse(controller.text);
                    if (val != null && val > 0) {
                      setState(() {
                        _customRatePerWatt = val;
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📐 বাস্তবসম্মত ছাদ ও জমির ক্ষেত্রফল নির্ণয় অ্যালগরিদম
  Map<String, double> _calculateRealisticRoofArea(
    SolarCalculationResult result,
    SystemSizingParams params,
  ) {
    const double assumedLatitude = 23.8103; // বাংলাদেশের রেফারেন্স অক্ষাংশ
    final dims = SolarGeometryEngine.getModuleDimensions(
      params.panelPmax.toInt(),
    );
    final tilt = SolarCalculationService.calculateOptimalTilt(assumedLatitude);
    final tiltRad = tilt * (math.pi / 180.0);
    final double singlePanelNS = dims.lengthM * math.cos(tiltRad);

    final double pitch = SolarGeometryEngine.calculateRowPitch(
      latitude: assumedLatitude,
      tiltAngleDeg: tilt,
      moduleLengthM: dims.lengthM,
    );

    final int rows = result.panelsParallel;
    final int cols = result.panelsSeries;

    double netAreaSqM = 0.0;
    if (rows <= 1) {
      netAreaSqM =
          (singlePanelNS * dims.widthM) * math.max(1, result.totalPanels);
    } else {
      final double totalLengthNS = (singlePanelNS) + ((rows - 1) * pitch);
      final double totalWidthEW = cols * dims.widthM;
      netAreaSqM = totalLengthNS * totalWidthEW;
    }

    if (netAreaSqM <= 0) {
      netAreaSqM =
          (result.totalArrayWatt / 1000.0) * 7.5; // ফলব্যাক স্ট্যান্ডার্ড
    }

    final double netAreaSqFt = netAreaSqM * 10.7639;
    return {'sqM': netAreaSqM, 'sqFt': netAreaSqFt};
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final result = widget.result;
    final params = widget.params;
    final isGridTied = params.systemType == SolarSystemType.gridTied;
    final isHybrid = params.systemType == SolarSystemType.hybrid;

    // 📐 ডায়নামিক জ্যামিতিক স্থান ও আনুমানিক বাজেটের হিসাব
    final areaMap = _calculateRealisticRoofArea(result, params);
    final double estimatedRoofSqFt = areaMap['sqFt']!;
    final double estimatedRoofSqM = areaMap['sqM']!;
    final double effectiveRate = _customRatePerWatt ?? 70.0;
    final double estimatedTotalBudget = result.totalArrayWatt * effectiveRate;

    return Scaffold(
      appBar: AppBar(
        title: TwoLineAppBarTitle(
          title: _isBangla ? 'প্রয়োজনীয় সিস্টেম' : 'Sizing Summary',
          subtitle: _isBangla
              ? 'চূড়ান্ত কারিগরি স্পেসিফিকেশন'
              : 'Final System Specifications',
        ),
        actions: [
          IconButton(
            tooltip: _isBangla ? 'রিপোর্ট শেয়ার করুন' : 'Share PDF Report',
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              PdfReportService.shareOrPrintReport(result, params, _isBangla);
            },
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: TextButton.icon(
              onPressed: _toggleLanguage,
              icon: const Icon(
                Icons.translate_rounded,
                color: Colors.white,
                size: 14,
              ),
              label: Text(
                _isBangla ? 'ENG' : 'বাংলা',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
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
                ? [
                    const Color(0xFF030712),
                    const Color(0xFF0B1120),
                    const Color(0xFF020617),
                  ]
                : [
                    const Color(0xFFDCECE4),
                    const Color(0xFFEDF4F0),
                    const Color(0xFFE2EBE6),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    _buildTactileDemandHeaderCard(result, params, isDark),
                    const SizedBox(height: 16),
                    _buildSpaceAndBudgetCard(
                      roofSqFt: estimatedRoofSqFt,
                      roofSqM: estimatedRoofSqM,
                      budgetAmount: estimatedTotalBudget,
                      ratePerWatt: effectiveRate,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildPvArrayCard(result, params, isDark),
                    const SizedBox(height: 16),
                    if (!isGridTied) ...[
                      _buildBatteryBankCard(result, params, isDark),
                      const SizedBox(height: 16),
                    ],
                    _buildPowerElectronicsCard(result, params, isDark),
                    const SizedBox(height: 16),
                    _buildProtectionAndCablesCard(result, params, isDark),
                    const SizedBox(height: 16),
                    _buildSystemSpecsRecapCard(result, params, isDark),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF070D18) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF10B981).withValues(alpha: 0.45)
                        : const Color(0xFF94A3B8).withValues(alpha: 0.7),
                    width: 1.6,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.75 : 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                  if (!isDark)
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 0,
                      offset: Offset(0, -1),
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
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: isDark
                          ? AppColors.energyGreen.withValues(alpha: 0.5)
                          : const Color(0xFF063A24).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: widget.onProceedToDiagram,
                    icon: const Icon(
                      Icons.account_tree_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      _isBangla
                          ? 'সংযোগ ডায়াগ্রাম দেখুন'
                          : 'View Wiring Diagram',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        letterSpacing: 0.3,
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

  Widget _buildTactileDemandHeaderCard(
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
              ? [const Color(0xFF042416), const Color(0xFF071B12)]
              : [const Color(0xFF063A24), const Color(0xFF0F4D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF10B981).withValues(alpha: 0.55)
              : const Color(0xFF047857),
          width: 1.6,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF063A24).withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.solarGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.solarGold.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  archLabel,
                  style: const TextStyle(
                    color: AppColors.solarGold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                result.totalDailyWh.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: -0.5,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '≈ ${result.energyDemandAh.toStringAsFixed(1)} Ah/day',
                    style: const TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
          if (result.hasAcLoad &&
              result.hasDcLoad &&
              params.systemType != SolarSystemType.gridTied) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AC: ${result.dailyAcWh.toStringAsFixed(0)} Wh',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'DC: ${result.dailyDcWh.toStringAsFixed(0)} Wh',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpaceAndBudgetCard({
    required double roofSqFt,
    required double roofSqM,
    required double budgetAmount,
    required double ratePerWatt,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 1.4,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.accentCyan.withValues(alpha: 0.15)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.real_estate_agent_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.accentCyan
                      : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isBangla
                    ? 'প্রাক্কলিত স্থান ও বাজেট'
                    : 'Estimated Space & Budget',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.roofing_rounded,
                            size: 16,
                            color: AppColors.energyGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isBangla ? 'প্রয়োজনীয় ছাদ/জায়গা' : 'Required Area',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '≈ ${roofSqFt.toStringAsFixed(0)} sq.ft',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: AppColors.energyGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isBangla
                            ? '(${roofSqM.toStringAsFixed(1)} m² ছায়ামুক্ত স্থান)'
                            : '(${roofSqM.toStringAsFixed(1)} m² shadow-free area)',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _openRateEditorDialog(isDark),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.payments_rounded,
                                  size: 16,
                                  color: AppColors.solarGold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isBangla
                                      ? 'আনুমানিক বাজেট'
                                      : 'Estimated Budget',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.edit_note_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.accentCyan
                                  : AppColors.primaryGreen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '৳ ${(budgetAmount / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: AppColors.solarGold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isBangla
                              ? '(@ ৳ ${ratePerWatt.toInt()}/Wp - পরিবর্তনযোগ্য)'
                              : '(@ ৳ ${ratePerWatt.toInt()}/Wp - Editable)',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPvArrayCard(
    SolarCalculationResult result,
    SystemSizingParams params,
    bool isDark,
  ) {
    return _buildTactileCard(
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
              ? 'সংযোগ বিন্যাস: প্রতি সারিতে ${result.panelsSeries}টি করে মোট ${result.panelsParallel}টি স্ট্রিং'
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
    return _buildTactileCard(
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

    return _buildTactileCard(
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
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.energyGreen
                                : AppColors.primaryGreen)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: isDark
                        ? AppColors.energyGreen
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
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${result.controllerVoltage.toInt()}V, ≥ ${result.controllerAmpere.toInt()}A (${result.controllerType.toUpperCase()})',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: isDark
                              ? Colors.white
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
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (isDark ? AppColors.energyGreen : AppColors.primaryGreen)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isGridTied
                      ? Icons.solar_power_rounded
                      : (isHybrid
                            ? Icons.sync_alt_rounded
                            : Icons.power_rounded),
                  color: isDark
                      ? AppColors.energyGreen
                      : AppColors.primaryGreen,
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
                            fontSize: 11.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w700,
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
                                        ? AppColors.energyGreen
                                        : AppColors.primaryGreen)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isGridTied
                                ? 'DC/AC ≈ 1.15'
                                : (isHybrid
                                      ? 'Built-in MPPT'
                                      : 'Pure Sine Wave'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.energyGreen
                                  : AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isGridTied
                          ? '${(result.inverterCapacityVa / 1000).toStringAsFixed(1)} kW (220V/50Hz On-Grid)'
                          : '${result.inverterVoltage.toInt()}V DC ➔ 220V AC, ≥ ${result.inverterCapacityVa.toInt()} VA',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: isDark
                            ? Colors.white
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

    return _buildTactileCard(
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

    final activeColor = isDark ? AppColors.energyGreen : AppColors.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: activeColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              recapText,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTactileCard({
    required String title,
    required IconData icon,
    String? highlightText,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 1.4,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 0,
                  offset: Offset(0, -2),
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
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppColors.energyGreen
                                  : AppColors.primaryGreen)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isDark
                          ? AppColors.energyGreen
                          : AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              if (highlightText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.energyGreen
                                : AppColors.primaryGreen)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    highlightText,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      fontSize: 13.5,
                      color: isDark
                          ? AppColors.energyGreen
                          : AppColors.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
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
    final activeColor = isDark ? AppColors.energyGreen : AppColors.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: activeColor.withValues(alpha: 0.35)),
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
                color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : activeColor,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hub_rounded,
            size: 15,
            color: isDark ? AppColors.energyGreen : AppColors.primaryGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
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
    final activeColor = isDark ? AppColors.energyGreen : AppColors.primaryGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                fontSize: 12,
                color: activeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
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
                  ? const Color(0xFF94A3B8)
                  : AppColors.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
