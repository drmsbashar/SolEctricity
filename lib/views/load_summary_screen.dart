import 'package:flutter/material.dart';

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
    final engine = LoadCalculationEngine(_currentItems);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B6A3B),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _currentItems),
        ),
        title: Text(
          widget.isBangla ? 'লোড পর্যালোচনা' : 'Load Summary',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _currentItems.isEmpty
          ? Center(
              child: Text(
                widget.isBangla
                    ? 'কোনো উপকরণ যুক্ত করা হয়নি।'
                    : 'No appliances added.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                        _buildRatioCard(engine),

                        const SizedBox(height: 14),

                        // ২. এসি উপকরণের তালিকা
                        _buildSectionHeader(
                          title: widget.isBangla
                              ? 'এসি (AC) উপকরণসমূহ'
                              : 'AC Appliances',
                          color: Colors.blue.shade800,
                          icon: Icons.power,
                        ),
                        const SizedBox(height: 6),
                        if (engine.acItems.isEmpty)
                          _buildEmptyNotice(
                            widget.isBangla
                                ? 'কোনো এসি উপকরণ নেই'
                                : 'No AC appliances',
                          )
                        else
                          ...engine.acItems.map((item) => _buildItemTile(item)),

                        const SizedBox(height: 16),

                        // ৩. ডিসি উপকরণের তালিকা
                        _buildSectionHeader(
                          title: widget.isBangla
                              ? 'ডিসি (DC) উপকরণসমূহ'
                              : 'DC Appliances',
                          color: Colors.green.shade800,
                          icon: Icons.battery_charging_full,
                        ),
                        const SizedBox(height: 6),
                        if (engine.dcItems.isEmpty)
                          _buildEmptyNotice(
                            widget.isBangla
                                ? 'কোনো ডিসি উপকরণ নেই'
                                : 'No DC appliances',
                          )
                        else
                          ...engine.dcItems.map((item) => _buildItemTile(item)),

                        const SizedBox(height: 16),

                        // ৪. সারসংক্ষেপ হাইলাইট কার্ড
                        _buildTotalSummaryCard(engine),
                      ],
                    ),
                  ),
                ),

                // ৫. বটম অ্যাকশন বার
                _buildBottomActionBar(),
              ],
            ),
    );
  }

  // এসি ও ডিসি অনুপাত কার্ড
  Widget _buildRatioCard(LoadCalculationEngine engine) {
    final acPct = engine.acPercentage;
    final dcPct = engine.dcPercentage;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
                    color: Colors.blue.shade800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  widget.isBangla
                      ? 'ডিসি: ${dcPct.toStringAsFixed(1)}%'
                      : 'DC: ${dcPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
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
                      flex: (acPct * 10).toInt(),
                      child: Container(color: Colors.blue.shade600),
                    ),
                    Expanded(
                      flex: (dcPct * 10).toInt(),
                      child: Container(color: Colors.green.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyNotice(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildItemTile(ApplianceItem item) {
    final name = widget.isBangla ? item.nameBn : item.nameEn;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.watt.toStringAsFixed(0)}W × ${item.quantity} | '
                    '${item.hoursPerDay.toStringAsFixed(1)} '
                    '${widget.isBangla ? 'ঘণ্টা/দিন' : 'hrs/day'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
                    color: Color(0xFF1B6A3B),
                  ),
                ),
                Text(
                  '${item.totalWatt.toStringAsFixed(0)} W peak',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 22,
              ),
              tooltip: widget.isBangla ? 'মুছুন' : 'Delete',
              onPressed: () => _deleteItem(item.id),
            ),
          ],
        ),
      ),
    );
  }

  // সর্বমোট গণনার হাইলাইট কার্ড
  Widget _buildTotalSummaryCard(LoadCalculationEngine engine) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B6A3B),
        borderRadius: BorderRadius.circular(14),
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
          const Divider(color: Colors.white30, height: 16),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
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
          const Divider(color: Colors.white30, height: 18),
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
            valueColor: Colors.amberAccent,
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
              color: Colors.white.withAlpha(230),
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

  // বটম বার
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
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
                  foregroundColor: const Color(0xFF1B6A3B),
                  side: const BorderSide(color: Color(0xFF1B6A3B)),
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
                  backgroundColor: const Color(0xFF1B6A3B),
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
