import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/appliance_item.dart';

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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _currentItems),
        ),
        title: Text(
          widget.isBangla ? 'লোড পর্যালোচনা' : 'Load Summary',
          style: const TextStyle(fontWeight: FontWeight.bold),
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

                          // ৪. ইঞ্জিনিয়ারিং সারসংক্ষেপ কনসোল কার্ড
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF0284C7),
                                  const Color(0xFF38BDF8),
                                ]
                              : [
                                  const Color(0xFF0284C7),
                                  const Color(0xFF38BDF8),
                                ],
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

  Widget _buildTactileItemTile(ApplianceItem item, bool isDark) {
    final name = widget.isBangla ? item.nameBn : item.nameEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
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
          const SizedBox(width: 8),
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
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTactileTotalSummaryCard(
    LoadCalculationEngine engine,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // ডার্ক ও লাইট উভয় মোডেই বিশেষ ডিপ এনার্জি-গ্রিন সিগনেচার ব্যাকগ্রাউন্ড
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF042416), // ডার্ক মোডের বিশেষ ডিপ পাইন
                  const Color(0xFF071B12), // গভীর মেটালিক এমারেল্ড শেড
                ]
              : [
                  const Color(0xFF063A24), // লাইট মোডের মূল গাঢ় সবুজ
                  const Color(0xFF0F4D32),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF10B981)
                    .withValues(alpha: 0.55) // ডার্কে স্পষ্ট নিয়ন ফ্রেম
              : const Color(0xFF047857), // লাইটে শার্প এমারেল্ড বর্ডার
          width: 1.6,
        ),
        boxShadow: isDark
            ? [
                // ডার্ক মোডের অনন্য এমারেল্ড গ্লো
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  ? 'সর্বমোট দৈনিক শক্তি (ΣLtotal):'
                  : 'Total Daily Energy (ΣLtotal):',
              value: '${engine.sigmaLtotal.toStringAsFixed(1)} Wh/day',
              isBold: true,
              fontSize: 15,
              valueColor: isDark ? const Color(0xFF34D399) : Colors.white,
            ),
          ),
          const Divider(color: Colors.white24, height: 22),
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
            isBold: true,
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
