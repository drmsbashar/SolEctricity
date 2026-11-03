import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/appliance_item.dart';
import '../widgets/theme_toggle_button.dart';

class LoadSummaryScreen extends StatefulWidget {
  final List<ApplianceItem> items;
  final bool isBangla;
  final VoidCallback onProceedToSizing;

  const LoadSummaryScreen({
    super.key,
    required this.items,
    required this.isBangla,
    required this.onProceedToSizing,
  });

  @override
  State<LoadSummaryScreen> createState() => _LoadSummaryScreenState();
}

class _LoadSummaryScreenState extends State<LoadSummaryScreen> {
  late List<ApplianceItem> _currentItems;

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.items);
  }

  void _deleteItem(String id) {
    setState(() {
      _currentItems.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final engine = LoadCalculationEngine(_currentItems);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _currentItems),
        ),
        title: Text(widget.isBangla ? 'লোড পর্যালোচনা' : 'Load Summary'),
        actions: [
          // ☀️/🌙 স্ট্যান্ডার্ডাইজড থিম টগল বাটন
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
        child: _currentItems.isEmpty
            ? Center(
                child: Text(
                  widget.isBangla
                      ? 'কোনো উপকরণ যুক্ত করা হয়নি।'
                      : 'No appliances added.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ১. শক্তি অনুপাত বার (AC vs DC)
                          _buildRatioCard(engine, isDark),

                          const SizedBox(height: 14),

                          // ২. এসি উপকরণের তালিকা
                          _buildSectionHeader(
                            title: widget.isBangla
                                ? 'এসি (AC) উপকরণসমূহ'
                                : 'AC Appliances',
                            color: isDark
                                ? AppColors.accentCyan
                                : const Color(0xFF2563EB),
                            icon: Icons.power,
                          ),
                          const SizedBox(height: 6),
                          if (engine.acItems.isEmpty)
                            _buildEmptyNotice(
                              widget.isBangla
                                  ? 'কোনো এসি উপকরণ নেই'
                                  : 'No AC appliances',
                              isDark,
                            )
                          else
                            ...engine.acItems.map(
                              (item) => _buildItemTile(item, isDark),
                            ),

                          const SizedBox(height: 16),

                          // ৩. ডিসি উপকরণের তালিকা
                          _buildSectionHeader(
                            title: widget.isBangla
                                ? 'ডিসি (DC) উপকরণসমূহ'
                                : 'DC Appliances',
                            color: AppColors.energyGreen,
                            icon: Icons.battery_charging_full,
                          ),
                          const SizedBox(height: 6),
                          if (engine.dcItems.isEmpty)
                            _buildEmptyNotice(
                              widget.isBangla
                                  ? 'কোনো ডিসি উপকরণ নেই'
                                  : 'No DC appliances',
                              isDark,
                            )
                          else
                            ...engine.dcItems.map(
                              (item) => _buildItemTile(item, isDark),
                            ),

                          const SizedBox(height: 16),

                          // ৪. সারসংক্ষেপ হাইলাইট কার্ড
                          _buildTotalSummaryCard(engine, isDark),
                        ],
                      ),
                    ),
                  ),

                  // ৫. বটম অ্যাকশন বার
                  _buildBottomActionBar(isDark),
                ],
              ),
      ),
    );
  }

  // এসি ও ডিসি অনুপাত কার্ড
  Widget _buildRatioCard(LoadCalculationEngine engine, bool isDark) {
    final acPct = engine.acPercentage;
    final dcPct = engine.dcPercentage;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isBangla
                    ? 'এসি: ${acPct.toStringAsFixed(1)}%'
                    : 'AC: ${acPct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.accentCyan
                      : const Color(0xFF2563EB),
                  fontSize: 13,
                ),
              ),
              Text(
                widget.isBangla
                    ? 'ডিসি: ${dcPct.toStringAsFixed(1)}%'
                    : 'DC: ${dcPct.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.energyGreen,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (acPct * 10).toInt().clamp(1, 1000),
                    child: Container(
                      color: isDark
                          ? AppColors.accentCyan
                          : const Color(0xFF2563EB),
                    ),
                  ),
                  Expanded(
                    flex: (dcPct * 10).toInt().clamp(1, 1000),
                    child: Container(color: AppColors.energyGreen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyNotice(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildItemTile(ApplianceItem item, bool isDark) {
    final name = widget.isBangla ? item.nameBn : item.nameEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.watt.toStringAsFixed(0)}W × ${item.quantity} | '
                  '${item.hoursPerDay.toStringAsFixed(1)} '
                  '${widget.isBangla ? 'ঘণ্টা/দিন' : 'hrs/day'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.dailyEnergyWh.toStringAsFixed(0)} Wh',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.energyGreen,
                ),
              ),
              Text(
                '${item.totalWatt.toStringAsFixed(0)} W peak',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.alertRed,
              size: 22,
            ),
            tooltip: widget.isBangla ? 'মুছুন' : 'Delete',
            onPressed: () => _deleteItem(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummaryCard(LoadCalculationEngine engine, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : const Color(0xFF1B6A3B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isBangla
                ? 'শক্তি চাহিদার সারসংক্ষেপ'
                : 'Energy Demand Summary',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const Divider(color: Colors.white24, height: 16),
          _buildSummaryRow(
            label: widget.isBangla
                ? 'এসি দৈনিক চাহিদা (ΣLac):'
                : 'AC Daily Demand (ΣLac):',
            value: '${engine.sigmaLac.toStringAsFixed(1)} Wh/day',
          ),
          _buildSummaryRow(
            label: widget.isBangla
                ? 'ডিসি দৈনিক চাহিদা (ΣLdc):'
                : 'DC Daily Demand (ΣLdc):',
            value: '${engine.sigmaLdc.toStringAsFixed(1)} Wh/day',
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildSummaryRow(
              label: widget.isBangla
                  ? 'সর্বমোট দৈনিক শক্তি (ΣLtotal):'
                  : 'Total Daily Energy (ΣLtotal):',
              value: '${engine.sigmaLtotal.toStringAsFixed(1)} Wh/day',
              isBold: true,
              fontSize: 14,
            ),
          ),
          const Divider(color: Colors.white24, height: 18),
          _buildSummaryRow(
            label: widget.isBangla
                ? 'ইনভার্টারের এসি পিক লোড (ΣLa):'
                : 'AC Peak Load for Inverter (ΣLa):',
            value: '${engine.sigmaLa.toStringAsFixed(0)} W',
          ),
          _buildSummaryRow(
            label: widget.isBangla
                ? 'প্রস্তাবিত ইনভার্টার রেটিং (১.২৫×):'
                : 'Recommended Inverter Rating (1.25×):',
            value: '≥ ${engine.recommendedInverterWatt.toStringAsFixed(0)} W',
            valueColor: AppColors.solarGold,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    bool isBold = false,
    double fontSize = 13,
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, _currentItems),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.accentCyan
                      : const Color(0xFF1B6A3B),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF1B6A3B),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.isBangla ? 'উপকরণ সংশোধন' : 'Edit Appliances',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _currentItems.isEmpty
                    ? null
                    : widget.onProceedToSizing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.energyGreen
                      : const Color(0xFF1B6A3B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.isBangla ? 'সিস্টেম সাইজিং →' : 'System Sizing →',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
