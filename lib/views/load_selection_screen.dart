import 'package:flutter/material.dart';

import '../models/appliance_item.dart';
import '../models/appliance_presets.dart';
import 'appliance_input_screen.dart';
import 'load_summary_screen.dart';

class LoadSelectionScreen extends StatefulWidget {
  final bool isBangla;
  final VoidCallback onToggleLanguage;

  const LoadSelectionScreen({
    super.key,
    required this.isBangla,
    required this.onToggleLanguage,
  });

  @override
  State<LoadSelectionScreen> createState() => _LoadSelectionScreenState();
}

class _LoadSelectionScreenState extends State<LoadSelectionScreen> {
  final List<ApplianceItem> _userItems = [];
  late bool _isBangla; // স্ক্রিনের নিজস্ব ভাষা স্টেট

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
  }

  // ভাষা টগল মেথড
  void _handleLanguageToggle() {
    setState(() {
      _isBangla = !_isBangla;
    });
    widget.onToggleLanguage(); // মূল অ্যাপের স্টেটও সিনক্রোনাইজ রাখা
  }

  Future<void> _openCategoryInput(CategoryConfig category) async {
    final categoryExistingItems = _userItems
        .where((item) => item.categoryKey == category.key)
        .toList();

    final result = await Navigator.push<List<ApplianceItem>>(
      context,
      MaterialPageRoute(
        builder: (context) => ApplianceInputScreen(
          category: category,
          existingItems: categoryExistingItems,
          isBangla: _isBangla,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _userItems.removeWhere((item) => item.categoryKey == category.key);
        _userItems.addAll(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = LoadCalculationEngine(_userItems);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B6A3B),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isBangla ? 'উপকরণ নির্বাচন' : 'Load Selection',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton.icon(
              onPressed: _handleLanguageToggle,
              icon: const Icon(Icons.translate, color: Colors.white, size: 16),
              label: Text(
                _isBangla ? 'ENG' : 'বাংলা',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ১২টি বাটন সম্বলিত গ্রিড
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 56.0,
                    vertical: 10.0,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemCount: AppliancePresetsData.categories.length,
                    itemBuilder: (context, index) {
                      final category = AppliancePresetsData.categories[index];
                      final count = engine.getCountByCategory(category.key);
                      return _build3DCard(category, count);
                    },
                  ),
                ),
              ),
            ),
          ),

          // নিচের লাইভ সামারি ও নেভিগেশন বার
          _buildLiveSummaryBar(engine),
        ],
      ),
    );
  }

  // ৩ডি ইফেক্ট বাটন কার্ড
  Widget _build3DCard(CategoryConfig category, int count) {
    final title = _isBangla ? category.titleBn : category.titleEn;
    final hasItems = count > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openCategoryInput(category),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: hasItems ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasItems
                      ? const Color(0xFF16A34A)
                      : Colors.grey.shade300,
                  width: hasItems ? 2.0 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasItems
                        ? const Color(0xFF16A34A).withAlpha(45)
                        : Colors.black.withAlpha(25),
                    offset: const Offset(2, 4),
                    blurRadius: 5,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 8.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          category.svgPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.electric_bolt,
                            size: 36,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasItems
                            ? const Color(0xFF15803D)
                            : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // আইটেম কাউন্টার ব্যাজ
        if (hasItems)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // রিয়েল-টাইম স্টিকি বটম বার
  Widget _buildLiveSummaryBar(LoadCalculationEngine engine) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // এসি দৈনিক শক্তি
                Expanded(
                  child: _buildMetricTile(
                    title: _isBangla ? 'এসি দৈনিক শক্তি' : 'Daily AC Load',
                    value: '${engine.sigmaLac.toStringAsFixed(0)} Wh',
                    color: const Color(0xFF2563EB),
                    bg: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 6),
                // ডিসি দৈনিক শক্তি
                Expanded(
                  child: _buildMetricTile(
                    title: _isBangla ? 'ডিসি দৈনিক শক্তি' : 'Daily DC Load',
                    value: '${engine.sigmaLdc.toStringAsFixed(0)} Wh',
                    color: const Color(0xFF059669),
                    bg: const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 6),
                // এসি পিক পাওয়ার (ΣLa)
                Expanded(
                  child: _buildMetricTile(
                    title: _isBangla ? 'এসি পিক পাওয়ার' : 'AC Peak Power',
                    value: '${engine.sigmaLa.toStringAsFixed(0)} W',
                    color: const Color(0xFFDC2626),
                    bg: const Color(0xFFFEF2F2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_userItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isBangla
                              ? 'অনুগ্রহ করে অন্তত একটি উপকরণ যোগ করুন।'
                              : 'Please add at least one appliance.',
                        ),
                        backgroundColor: const Color(0xFFD97706),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final updatedItems = await Navigator.push<List<ApplianceItem>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoadSummaryScreen(
                        items: _userItems,
                        isBangla: _isBangla,
                        onProceedToSizing: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isBangla
                                    ? 'সিস্টেম সাইজিং ক্যালকুলেশন শুরু হচ্ছে...'
                                    : 'Starting System Sizing Calculation...',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );

                  if (updatedItems != null) {
                    setState(() {
                      _userItems.clear();
                      _userItems.addAll(updatedItems);
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6A3B),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.analytics_outlined, size: 20),
                label: Text(
                  _isBangla
                      ? 'সম্পূর্ণ লোড পর্যালোচনা (Summary)'
                      : 'Review Load Summary',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40), width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
