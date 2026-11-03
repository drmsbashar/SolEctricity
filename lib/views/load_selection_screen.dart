import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/appliance_item.dart';
import '../models/appliance_presets.dart';
import 'appliance_input_screen.dart';
import 'load_summary_screen.dart';
import 'system_parameters_screen.dart';

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
  late bool _isBangla;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
  }

  void _handleLanguageToggle() {
    setState(() {
      _isBangla = !_isBangla;
    });
    widget.onToggleLanguage();
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final engine = LoadCalculationEngine(_userItems);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isBangla ? 'উপকরণ নির্বাচন' : 'Load Selection'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton.icon(
              onPressed: _handleLanguageToggle,
              icon: Icon(
                Icons.translate,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                size: 16,
              ),
              label: Text(
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
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
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
                        return _build3DCard(category, count, isDark);
                      },
                    ),
                  ),
                ),
              ),
            ),
            _buildLiveSummaryBar(engine, isDark),
          ],
        ),
      ),
    );
  }

  Widget _build3DCard(CategoryConfig category, int count, bool isDark) {
    final title = _isBangla ? category.titleBn : category.titleEn;
    final hasItems = count > 0;

    // ডার্ক মোডের জন্য নির্দিষ্ট আইকনগুলোর ম্যাপ
    final Map<String, String> darkIcons = {
      'fan': 'assets/icons/fan_dark.png',
      'light': 'assets/icons/light_dark.png',
      'tv': 'assets/icons/tv_dark.png',
      'computer': 'assets/icons/computer_dark.png',
      'laptop': 'assets/icons/laptop_dark.png',
      'printer': 'assets/icons/printer_dark.png',
      'ac_cooler': 'assets/icons/ac_dark.png',
      'fridge': 'assets/icons/fridge_dark.png',
      'cooker': 'assets/icons/cooker_dark.png',
      'oven': 'assets/icons/oven_dark.png',
      'blender': 'assets/icons/blender_dark.png',
      'others': 'assets/icons/others_dark.png',
    };

    // লাইট মোডে অরিজিনাল রঙিন আইকন এবং ডার্ক মোডে ডার্ক ফাইল লোড হবে
    final String resolvedIconPath =
        (isDark && darkIcons.containsKey(category.key))
        ? darkIcons[category.key]!
        : category.svgPath;

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
                color: hasItems
                    ? (isDark
                          ? AppColors.energyGreen.withValues(alpha: 0.15)
                          : const Color(0xFFF0FDF4))
                    : (isDark ? AppColors.darkCardBg : AppColors.lightCardBg),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasItems
                      ? (isDark
                            ? AppColors.accentCyan
                            : const Color(0xFF16A34A))
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: hasItems ? 2.0 : 1.2,
                ),
                boxShadow: isDark
                    ? [
                        if (hasItems)
                          BoxShadow(
                            color: AppColors.accentCyan.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ]
                    : [
                        BoxShadow(
                          color: hasItems
                              ? const Color(0xFF16A34A).withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.04),
                          offset: const Offset(1, 3),
                          blurRadius: 6,
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
                          resolvedIconPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                category.svgPath,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => Icon(
                                  Icons.electric_bolt,
                                  size: 36,
                                  color: isDark
                                      ? AppColors.solarGold
                                      : Colors.amber.shade700,
                                ),
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
                            ? (isDark
                                  ? AppColors.accentCyan
                                  : const Color(0xFF15803D))
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasItems)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.alertRed,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  width: 2,
                ),
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

  Widget _buildLiveSummaryBar(LoadCalculationEngine engine, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
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
                Expanded(
                  child: _buildMetricTile(
                    title: _isBangla ? 'এসি দৈনিক শক্তি' : 'Daily AC Load',
                    value: '${engine.sigmaLac.toStringAsFixed(0)} Wh',
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF2563EB),
                    bg: isDark
                        ? AppColors.darkInputBg
                        : const Color(0xFFEFF6FF),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMetricTile(
                    title: _isBangla ? 'ডিসি দৈনিক শক্তি' : 'Daily DC Load',
                    value: '${engine.sigmaLdc.toStringAsFixed(0)} Wh',
                    color: AppColors.energyGreen,
                    bg: isDark
                        ? AppColors.darkInputBg
                        : const Color(0xFFECFDF5),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMetricTile(
                    title: _isBangla ? 'এসি পিক পাওয়ার' : 'AC Peak Power',
                    value: '${engine.sigmaLa.toStringAsFixed(0)} W',
                    color: AppColors.alertRed,
                    bg: isDark
                        ? AppColors.darkInputBg
                        : const Color(0xFFFEF2F2),
                    isDark: isDark,
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

                  final updatedItems =
                      await Navigator.push<List<ApplianceItem>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoadSummaryScreen(
                            items: _userItems,
                            isBangla: _isBangla,
                            onProceedToSizing: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SystemParametersScreen(
                                    dailyTotalWh: engine.sigmaLtotal,
                                    acPeakWatt: engine.sigmaLa,
                                    dailyAcWh: engine.sigmaLac,
                                    dailyDcWh: engine.sigmaLdc,
                                    isBangla: _isBangla,
                                    onToggleLanguage: _handleLanguageToggle,
                                    onProceedToFinalResults: (params) {},
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
                  backgroundColor: isDark
                      ? AppColors.energyGreen
                      : const Color(0xFF1B6A3B),
                  foregroundColor: Colors.white,
                  elevation: 2,
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
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : color.withValues(alpha: 0.15),
          width: 0.8,
        ),
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
              color: isDark ? AppColors.darkTextSecondary : color,
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
