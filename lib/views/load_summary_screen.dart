import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/appliance_item.dart';
import '../widgets/app_bar_title.dart';

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

  void _showEditItemDialog(ApplianceItem item) {
    final wattController = TextEditingController(
      text: item.watt.toStringAsFixed(
        item.watt.truncateToDouble() == item.watt ? 0 : 1,
      ),
    );
    final qtyController = TextEditingController(text: item.quantity.toString());
    final hoursController = TextEditingController(
      text: item.hoursPerDay.toStringAsFixed(
        item.hoursPerDay.truncateToDouble() == item.hoursPerDay ? 0 : 1,
      ),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.skyBlue.withValues(alpha: 0.2)
                    : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.skyBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.isBangla ? 'উপকরণ তথ্য সংশোধন' : 'Edit Appliance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isBangla ? item.nameBn : item.nameEn,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.energyGreen,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: wattController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: widget.isBangla
                      ? 'প্রতিটির ওয়াট (W)'
                      : 'Wattage per unit (W)',
                  prefixIcon: const Icon(Icons.bolt_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.isBangla ? 'উপকরণের সংখ্যা' : 'Quantity',
                  prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: widget.isBangla
                      ? 'দৈনিক ব্যবহার (ঘণ্টা)'
                      : 'Daily usage (hours)',
                  prefixIcon: const Icon(Icons.timer_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              widget.isBangla ? 'বাতিল' : 'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newWatt = double.tryParse(wattController.text) ?? item.watt;
              final newQty = int.tryParse(qtyController.text) ?? item.quantity;
              final newHours =
                  double.tryParse(hoursController.text) ?? item.hoursPerDay;

              setState(() {
                final index = _currentItems.indexWhere(
                  (element) => element.id == item.id,
                );
                if (index != -1) {
                  _currentItems[index] = item.copyWith(
                    watt: newWatt,
                    quantity: newQty,
                    hoursPerDay: newHours,
                  );
                }
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.energyGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              widget.isBangla ? 'সংরক্ষণ' : 'Save',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final engine = LoadCalculationEngine(_currentItems);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _currentItems),
        ),
        title: TwoLineAppBarTitle(
          title: widget.isBangla ? 'লোড পর্যালোচনা' : 'Load Summary',
          subtitle: widget.isBangla
              ? 'এসি ও ডিসি শক্তি হিসাব'
              : 'AC & DC Energy Breakdown',
        ),
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
        child: _currentItems.isEmpty
            ? Center(
                child: Text(
                  widget.isBangla
                      ? 'কোনো উপকরণ যুক্ত করা হয়নি।'
                      : 'No appliances added.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : AppColors.lightTextSecondary,
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ১. ৩ডি শক্তি অনুপাত বার (AC vs DC Ratio Gauge)
                          _buildTactileRatioCard(engine, isDark),

                          const SizedBox(height: 18),

                          // ২. এসি উপকরণের তালিকা
                          _buildSectionHeader(
                            title: widget.isBangla
                                ? 'এসি (AC) উপকরণসমূহ'
                                : 'AC Appliances',
                            color: isDark
                                ? AppColors.skyBlue
                                : const Color(0xFF0284C7),
                            icon: Icons.power_rounded,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          if (engine.acItems.isEmpty)
                            _buildEmptyNotice(
                              widget.isBangla
                                  ? 'কোনো এসি উপকরণ নেই'
                                  : 'No AC appliances',
                              isDark,
                            )
                          else
                            ...engine.acItems.map(
                              (item) => _buildTactileItemTile(item, isDark),
                            ),

                          const SizedBox(height: 18),

                          // ৩. ডিসি উপকরণের তালিকা
                          _buildSectionHeader(
                            title: widget.isBangla
                                ? 'ডিসি (DC) উপকরণসমূহ'
                                : 'DC Appliances',
                            color: AppColors.energyGreen,
                            icon: Icons.battery_charging_full_rounded,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          if (engine.dcItems.isEmpty)
                            _buildEmptyNotice(
                              widget.isBangla
                                  ? 'কোনো ডিসি উপকরণ নেই'
                                  : 'No DC appliances',
                              isDark,
                            )
                          else
                            ...engine.dcItems.map(
                              (item) => _buildTactileItemTile(item, isDark),
                            ),

                          const SizedBox(height: 20),

                          // ৪. ইঞ্জিনিয়ারিং সারসংক্ষেপ কনসোল কার্ড (ইনভার্টার সংক্রান্ত অংশ বাদ দেওয়া হয়েছে)
                          _buildTactileTotalSummaryCard(engine, isDark),
                        ],
                      ),
                    ),
                  ),

                  // ৫. বটম ফ্রস্টেড অ্যাকশন বার
                  _buildBottomActionBar(isDark),
                ],
              ),
      ),
    );
  }

  // ৩ডি শক্তি অনুপাত কার্ড
  Widget _buildTactileRatioCard(LoadCalculationEngine engine, bool isDark) {
    final acPct = engine.acPercentage;
    final dcPct = engine.dcPercentage;

    return Container(
      padding: const EdgeInsets.all(16.0),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.skyBlue
                          : const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isBangla
                        ? 'এসি লোড: ${acPct.toStringAsFixed(1)}%'
                        : 'AC Load: ${acPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.skyBlue
                          : const Color(0xFF0284C7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.energyGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isBangla
                        ? 'ডিসি লোড: ${dcPct.toStringAsFixed(1)}%'
                        : 'DC Load: ${dcPct.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.energyGreen,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Row(
                children: [
                  Expanded(
                    flex: (acPct * 10).toInt().clamp(1, 1000),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (dcPct * 10).toInt().clamp(1, 1000),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF34D399)],
                        ),
                      ),
                    ),
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
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
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
          color: isDark
              ? const Color(0xFF64748B)
              : AppColors.lightTextSecondary,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ),
    );
  }

  // আপগ্রেডেড আইটেম টাইল: ডিলিটের ঠিক উপরে এডিট বাটন রাখা হয়েছে
  Widget _buildTactileItemTile(ApplianceItem item, bool isDark) {
    final name = widget.isBangla ? item.nameBn : item.nameEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showEditItemDialog(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // বিবরণ অংশ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.watt.toStringAsFixed(0)}W × ${item.quantity} | '
                        '${item.hoursPerDay.toStringAsFixed(1)} '
                        '${widget.isBangla ? 'ঘণ্টা/দিন' : 'hrs/day'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // এনার্জি ও ওয়াট মান
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.dailyEnergyWh.toStringAsFixed(0)} Wh',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        fontFamily: 'monospace',
                        color: AppColors.energyGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.totalWatt.toStringAsFixed(0)} W peak',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),

                // অ্যাকশন বাটনসমূহ: ডিলিট বাটনের ঠিক উপরে এডিট বাটন
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // এডিট বাটন (উপরে)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showEditItemDialog(item),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.skyBlue.withValues(alpha: 0.15)
                                : const Color(0xFF0284C7)
                                      .withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: isDark
                                ? AppColors.skyBlue
                                : const Color(0xFF0284C7),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // ডিলিট বাটন (নিচে)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _deleteItem(item.id),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.alertRed.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.alertRed,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // চার নম্বর কার্ড: কেবল মোট দৈনিক শক্তি চাহিদার ওপর কেন্দ্রীভূত
  Widget _buildTactileTotalSummaryCard(
    LoadCalculationEngine engine,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF042416), const Color(0xFF071B12)]
              : [const Color(0xFF063A24), const Color(0xFF0F4D32)],
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF10B981).withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: AppColors.energyGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.isBangla
                    ? 'শক্তি চাহিদার সারসংক্ষেপ'
                    : 'Energy Demand Summary',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          _buildSummaryRow(
            label: widget.isBangla ? 'এসি দৈনিক চাহিদা:' : 'AC Daily Demand:',
            value: '${engine.sigmaLac.toStringAsFixed(1)} Wh/day',
          ),
          _buildSummaryRow(
            label: widget.isBangla ? 'ডিসি দৈনিক চাহিদা:' : 'DC Daily Demand:',
            value: '${engine.sigmaLdc.toStringAsFixed(1)} Wh/day',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF34D399).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: _buildSummaryRow(
              label: widget.isBangla
                  ? 'সর্বমোট দৈনিক শক্তি:'
                  : 'Total Daily Energy:',
              value: '${engine.sigmaLtotal.toStringAsFixed(1)} Wh/day',
              isBold: true,
              fontSize: 15,
              valueColor: isDark ? const Color(0xFF34D399) : Colors.white,
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, -6),
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
                      ? Colors.white
                      : AppColors.primaryGreen,
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                      : AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  widget.isBangla ? 'সিস্টেম সাইজিং →' : 'System Sizing →',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
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
