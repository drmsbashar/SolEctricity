import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/app_colors.dart';
import '../models/system_sizing_params.dart';
import 'cost_based_solar_screen.dart';
import '../widgets/app_bar_title.dart';

class PlannerApplianceItem {
  final String key;
  String nameBn;
  String nameEn;
  double watt;
  final IconData icon;
  bool isAc;
  int quantity;
  double hours;

  PlannerApplianceItem({
    required this.key,
    required this.nameBn,
    required this.nameEn,
    required this.watt,
    required this.icon,
    this.isAc = true,
    this.quantity = 0,
    this.hours = 0.0,
  });

  double get rawDailyWh => watt * quantity * hours;

  // এসি লোডের ক্ষেত্রে ইনভার্টার অপচয় ডায়নামিক সমন্বয়
  double getEffectiveDailyWh({double inverterEfficiencyPercent = 90.0}) {
    final double raw = rawDailyWh;
    if (!isAc) return raw;
    final double eff = (inverterEfficiencyPercent > 0)
        ? (inverterEfficiencyPercent / 100.0)
        : 0.90;
    return raw / eff;
  }
}

class BudgetLoadPlannerScreen extends StatefulWidget {
  final double totalBudget;
  final double capacityKwp;
  final double dailyGenerationWh;
  final SolarSystemType systemType;
  final bool isBangla;
  final double inverterEfficiencyPercent;
  final List<PlannerApplianceItem>? initialItems;

  const BudgetLoadPlannerScreen({
    super.key,
    required this.totalBudget,
    required this.capacityKwp,
    required this.dailyGenerationWh,
    required this.systemType,
    required this.isBangla,
    this.inverterEfficiencyPercent = 90.0,
    this.initialItems,
  });

  @override
  State<BudgetLoadPlannerScreen> createState() =>
      _BudgetLoadPlannerScreenState();
}

class _BudgetLoadPlannerScreenState extends State<BudgetLoadPlannerScreen> {
  late bool _isBangla;
  late List<PlannerApplianceItem> _appliances;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      _appliances = widget.initialItems!;
    } else {
      _initDefaultAppliances();
    }
  }

  void _initDefaultAppliances() {
    _appliances = [
      PlannerApplianceItem(
        key: 'light',
        nameBn: 'LED লাইট',
        nameEn: 'LED Light',
        watt: 15,
        icon: Icons.lightbulb_outline_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      PlannerApplianceItem(
        key: 'fan',
        nameBn: 'সিলিং ফ্যান',
        nameEn: 'Ceiling Fan',
        watt: 75,
        icon: Icons.mode_fan_off_outlined,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      PlannerApplianceItem(
        key: 'tv',
        nameBn: 'টেলিভিশন',
        nameEn: 'Television',
        watt: 65,
        icon: Icons.tv_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      PlannerApplianceItem(
        key: 'computer',
        nameBn: 'ডেস্কটপ পিসি',
        nameEn: 'Desktop PC',
        watt: 150,
        icon: Icons.computer_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      PlannerApplianceItem(
        key: 'laptop',
        nameBn: 'ল্যাপটপ',
        nameEn: 'Laptop',
        watt: 65,
        icon: Icons.laptop_chromebook_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      PlannerApplianceItem(
        key: 'refrigerator',
        nameBn: 'ফ্রিজ / ডিপ ফ্রিজার',
        nameEn: 'Refrigerator',
        watt: 140,
        icon: Icons.kitchen_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      PlannerApplianceItem(
        key: 'air_cooler',
        nameBn: 'এয়ারকুলার',
        nameEn: 'Air Cooler',
        watt: 120,
        icon: Icons.ac_unit_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      PlannerApplianceItem(
        key: 'water_pump',
        nameBn: 'পানির পাম্প (১.০ HP)',
        nameEn: 'Water Pump (1.0 HP)',
        watt: 900,
        icon: Icons.water_drop_outlined,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      PlannerApplianceItem(
        key: 'cooker',
        nameBn: 'রাইস কুকার',
        nameEn: 'Rice Cooker',
        watt: 700,
        icon: Icons.soup_kitchen_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      PlannerApplianceItem(
        key: 'blender',
        nameBn: 'ব্লেন্ডার / মিক্সার',
        nameEn: 'Blender',
        watt: 400,
        icon: Icons.blender_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      PlannerApplianceItem(
        key: 'other',
        nameBn: 'অন্যান্য লোড',
        nameEn: 'Other Appliance',
        watt: 100,
        icon: Icons.devices_other_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
    ];
  }

  double _calculateEffectiveItemWh(PlannerApplianceItem item) {
    return item.getEffectiveDailyWh(
      inverterEfficiencyPercent: widget.inverterEfficiencyPercent,
    );
  }

  void _editApplianceWatt(PlannerApplianceItem item, bool isDark) {
    final wattController = TextEditingController(
      text: item.watt.toInt().toString(),
    );
    final nameController = TextEditingController(
      text: _isBangla ? item.nameBn : item.nameEn,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _isBangla ? '${item.nameBn} সম্পাদনা' : 'Edit ${item.nameEn}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.key == 'other') ...[
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: _isBangla ? 'উপকরণের নাম' : 'Appliance Name',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: wattController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                labelText: _isBangla
                    ? 'ওয়াট ক্ষমতা (Watt)'
                    : 'Rated Wattage (W)',
                suffixText: 'W',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isBangla ? 'বাতিল' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.accentCyan
                  : AppColors.primaryGreen,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () {
              final newWatt = double.tryParse(wattController.text);
              if (newWatt != null && newWatt > 0) {
                setState(() {
                  item.watt = newWatt;
                  if (item.key == 'other' &&
                      nameController.text.trim().isNotEmpty) {
                    item.nameBn = nameController.text.trim();
                    item.nameEn = nameController.text.trim();
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: Text(_isBangla ? 'সংরক্ষণ' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSharePdf() async {
    setState(() => _isGeneratingPdf = true);

    try {
      final doc = pw.Document();
      final activeItems = _appliances
          .where((i) => i.quantity > 0 && i.hours > 0)
          .toList();
      final double totalWh = _appliances.fold(
        0.0,
        (sum, i) => sum + _calculateEffectiveItemWh(i),
      );

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SolEctricity - Load & Budget Plan',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Affordable Solar System Sizing Proposal',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      DateTime.now().toString().split(' ')[0],
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.teal700),
                pw.SizedBox(height: 12),

                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text(
                            'Total Budget',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            CurrencyFormatter.format(
                              widget.totalBudget,
                              _isBangla,
                            ),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal900,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'Capacity',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            '${widget.capacityKwp.toStringAsFixed(2)} kWp',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal900,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'Daily Output',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            '${widget.dailyGenerationWh.toStringAsFixed(0)} Wh/day',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 18),

                pw.Text(
                  'Planned Appliances & Daily Usage:',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal900,
                  ),
                ),
                pw.SizedBox(height: 8),

                if (activeItems.isEmpty)
                  pw.Text(
                    'No specific appliances configured yet.',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey600,
                    ),
                  )
                else
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 10.5,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.teal800,
                    ),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    cellHeight: 24,
                    headers: [
                      'Appliance',
                      'Type',
                      'Rating',
                      'Qty',
                      'Hours/Day',
                      'Daily Demand',
                    ],
                    data: activeItems.map((item) {
                      return [
                        item.nameEn,
                        item.isAc ? 'AC' : 'DC',
                        '${item.watt.toInt()} W',
                        '${item.quantity}',
                        '${item.hours.toStringAsFixed(1)} h',
                        '${_calculateEffectiveItemWh(item).toStringAsFixed(0)} Wh',
                      ];
                    }).toList(),
                  ),

                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Planned Consumption: ${totalWh.toStringAsFixed(0)} Wh/day',
                      style: pw.TextStyle(
                        fontSize: 11.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                    pw.Text(
                      totalWh <= widget.dailyGenerationWh
                          ? 'Status: Safe & Within Generation (Surplus: ${(widget.dailyGenerationWh - totalWh).toStringAsFixed(0)} Wh)'
                          : 'Status: Overloaded (Deficit: ${(totalWh - widget.dailyGenerationWh).toStringAsFixed(0)} Wh)',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: totalWh <= widget.dailyGenerationWh
                            ? PdfColors.green700
                            : PdfColors.red700,
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey400),
                pw.Text(
                  'Bangladesh Council of Scientific and Industrial Research (BCSIR)',
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename:
            'Solectricity_Budget_Load_Plan_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double totalPlannedEffectiveWh = _appliances.fold(
      0.0,
      (sum, item) => sum + _calculateEffectiveItemWh(item),
    );
    final double remainingWh =
        widget.dailyGenerationWh - totalPlannedEffectiveWh;
    final double usageRatio = widget.dailyGenerationWh > 0
        ? (totalPlannedEffectiveWh / widget.dailyGenerationWh).clamp(0.0, 1.5)
        : 0.0;
    final bool isOverloaded =
        totalPlannedEffectiveWh > widget.dailyGenerationWh;
    final Color statusColor = isOverloaded
        ? AppColors.alertRed
        : (usageRatio > 0.85 ? AppColors.solarGold : AppColors.energyGreen);

    return Scaffold(
      appBar: AppBar(
        title: TwoLineAppBarTitle(
          title: _isBangla ? 'লোড পরিকল্পনা' : 'Load Planner',
          subtitle: _isBangla
              ? 'বাজেট ও কার্যকর চাহিদা'
              : 'Budget & Usage Demand',
        ),
        actions: [
          IconButton(
            tooltip: _isBangla ? 'PDF রিপোর্ট শেয়ার' : 'Share PDF Plan',
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _isGeneratingPdf ? null : _generateAndSharePdf,
          ),
          IconButton(
            tooltip: _isBangla ? 'ভাষা পরিবর্তন' : 'Toggle Language',
            onPressed: () => setState(() => _isBangla = !_isBangla),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
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
            tooltip: _isBangla ? 'হোম / ড্যাশবোর্ড' : 'Home',
            icon: const Icon(Icons.home_rounded, color: Colors.white),
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
            _buildStickyHeader(
              totalPlannedWh: totalPlannedEffectiveWh,
              remainingWh: remainingWh,
              usageRatio: usageRatio,
              isOverloaded: isOverloaded,
              statusColor: statusColor,
              isDark: isDark,
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _appliances.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildApplianceCard(_appliances[index], isDark);
                },
              ),
            ),
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader({
    required double totalPlannedWh,
    required double remainingWh,
    required double usageRatio,
    required bool isOverloaded,
    required Color statusColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isBangla ? 'মোট বাজেট' : 'Budget',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(widget.totalBudget, _isBangla),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _isBangla ? 'সিস্টেম সাইজ' : 'Capacity',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    '${widget.capacityKwp.toStringAsFixed(2)} kWp',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.energyGreen,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isBangla ? 'দৈনিক উৎপাদন' : 'Daily Output',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    '${widget.dailyGenerationWh.toStringAsFixed(0)} Wh',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.accentCyan
                          : const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: usageRatio > 1.0 ? 1.0 : usageRatio,
              minHeight: 10,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverloaded
                    ? (_isBangla
                          ? '⚠️ অতিরিক্ত ঘাটতি: +${(-remainingWh).toStringAsFixed(0)} Wh'
                          : '⚠️ Deficit: +${(-remainingWh).toStringAsFixed(0)} Wh')
                    : (_isBangla
                          ? 'উদ্বৃত্ত সোলার শক্তি: ${remainingWh.toStringAsFixed(0)} Wh'
                          : 'Surplus Solar Energy: ${remainingWh.toStringAsFixed(0)} Wh'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Text(
                '${(usageRatio * 100).toStringAsFixed(0)}% ${_isBangla ? "ব্যবহার" : "Planned"}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceCard(PlannerApplianceItem item, bool isDark) {
    final bool isActive = item.quantity > 0 && item.hours > 0;
    final double effectiveItemWh = _calculateEffectiveItemWh(item);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
            : (isDark
                  ? AppColors.darkCardBg.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? (isDark
                    ? AppColors.accentCyan.withValues(alpha: 0.4)
                    : const Color(0xFF93C5FD))
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isActive ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.icon,
                size: 22,
                color: isActive
                    ? (isDark ? AppColors.accentCyan : AppColors.primaryGreen)
                    : (isDark ? Colors.white38 : Colors.grey),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isBangla ? item.nameBn : item.nameEn,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${effectiveItemWh.toStringAsFixed(0)} Wh/day ${item.isAc ? "(${widget.inverterEfficiencyPercent.toInt()}% AC eff.)" : "(DC Direct)"}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? (isDark
                                  ? AppColors.solarGold
                                  : const Color(0xFFB45309))
                            : (isDark ? Colors.white38 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _editApplianceWatt(item, isDark),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0B132B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? AppColors.accentCyan.withValues(alpha: 0.5)
                          : const Color(0xFF0284C7),
                    ),
                  ),
                  child: Text(
                    '${item.watt.toInt()} W',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: isDark
                          ? AppColors.accentCyan
                          : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(7),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        if (!item.isAc) setState(() => item.isAc = true);
                      },
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.isAc
                              ? const Color(0xFFD97706)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'AC',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: item.isAc
                                ? Colors.white
                                : (isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (item.isAc) setState(() => item.isAc = false);
                      },
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: !item.isAc
                              ? const Color(0xFF0284C7)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'DC',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: !item.isAc
                                ? Colors.white
                                : (isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (item.quantity > 0) setState(() => item.quantity--);
                    },
                    child: const Icon(Icons.remove_circle_outline, size: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => item.quantity++),
                    child: const Icon(Icons.add_circle_outline, size: 20),
                  ),
                ],
              ),
            ],
          ),
          if (item.quantity > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _isBangla
                      ? '${item.hours.toStringAsFixed(1)} ঘণ্টা/দিন'
                      : '${item.hours.toStringAsFixed(1)} hrs/day',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      activeTrackColor: isDark
                          ? AppColors.accentCyan
                          : AppColors.primaryGreen,
                      thumbColor: isDark
                          ? AppColors.accentCyan
                          : AppColors.primaryGreen,
                    ),
                    child: Slider(
                      value: item.hours,
                      min: 0.0,
                      max: 24.0,
                      divisions: 48,
                      onChanged: (val) => setState(() => item.hours = val),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.energyGreen
                  : AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context, _appliances);
            },
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: Text(
              _isBangla ? 'সংরক্ষণ করুন ও ফিরে যান' : 'Save & Return',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
