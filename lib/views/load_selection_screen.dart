import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/appliance_item.dart';
import '../models/appliance_presets.dart';
import '../widgets/solar_ui_components.dart';
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
        title: Text(
          _isBangla ? 'উপকরণ নির্বাচন' : 'Load Selection',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
              onPressed: _handleLanguageToggle,
              icon: const Icon(
                Icons.translate_rounded,
                color: Colors.white,
                size: 15,
              ),
              label: Text(
                _isBangla ? 'ENG' : 'বাংলা',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        // ডার্ক মোডে ডিপ ওলেড থেকে গভীর স্লেটের হাই-কনট্রাস্ট গ্রেডিয়েন্ট
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF030712), // পিওর ডিপ ব্যাকড্রপ
                    const Color(0xFF0B1120), // নেভি স্লেট ট্রাফ
                    const Color(0xFF020617), // ডিপ ওলেড বেস
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
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.95,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: AppliancePresetsData.categories.length,
                      itemBuilder: (context, index) {
                        final category = AppliancePresetsData.categories[index];
                        final count = engine.getCountByCategory(category.key);
                        return TactilePressableCard(
                          category: category,
                          count: count,
                          isBangla: _isBangla,
                          isDark: isDark,
                          onTap: () => _openCategoryInput(category),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            _buildLiveFrostedSummaryBar(engine, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveFrostedSummaryBar(
    LoadCalculationEngine engine,
    bool isDark,
  ) {
    return FrostedGlassBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DigitalMetricTile(
                  label: _isBangla ? 'এসি দৈনিক' : 'Daily AC',
                  value: engine.sigmaLac.toStringAsFixed(0),
                  unit: 'Wh',
                  icon: Icons.power_rounded,
                  accentColor: isDark
                      ? AppColors.skyBlue
                      : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DigitalMetricTile(
                  label: _isBangla ? 'ডিসি দৈনিক' : 'Daily DC',
                  value: engine.sigmaLdc.toStringAsFixed(0),
                  unit: 'Wh',
                  icon: Icons.battery_charging_full_rounded,
                  accentColor: AppColors.energyGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DigitalMetricTile(
                  label: _isBangla ? 'এসি পিক' : 'AC Peak',
                  value: engine.sigmaLa.toStringAsFixed(0),
                  unit: 'W',
                  icon: Icons.flash_on_rounded,
                  accentColor: AppColors.alertRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
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
                      backgroundColor: AppColors.alertRed,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                    : AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.analytics_rounded, size: 20),
              label: Text(
                _isBangla
                    ? 'সম্পূর্ণ লোড পর্যালোচনা (Summary)'
                    : 'Review Load Summary',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TactilePressableCard extends StatefulWidget {
  final CategoryConfig category;
  final int count;
  final bool isBangla;
  final bool isDark;
  final VoidCallback onTap;

  const TactilePressableCard({
    super.key,
    required this.category,
    required this.count,
    required this.isBangla,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<TactilePressableCard> createState() => _TactilePressableCardState();
}

class _TactilePressableCardState extends State<TactilePressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.isBangla
        ? widget.category.titleBn
        : widget.category.titleEn;
    final bool hasItems = widget.count > 0;

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

    final String resolvedIconPath =
        (widget.isDark && darkIcons.containsKey(widget.category.key))
        ? darkIcons[widget.category.key]!
        : widget.category.svgPath;

    final double translateY = _isPressed ? 3.0 : 0.0;
    final double scale = _isPressed ? 0.96 : 1.0;

    // ডার্ক মোডে ডিসটিঙ্কট রং নির্বাচন:
    // ব্যাকগ্রাউন্ডের চেয়ে স্পষ্ট উজ্জ্বল স্লেট মেটালিক টোন
    final Color darkCardSurface = hasItems
        ? const Color(0xFF064E3B) // আইটেম থাকলে রিচ এমারেল্ড ডার্ক
        : const Color(0xFF1E293B); // সাধারণ বাটন: স্পষ্ট স্লেট ব্লু

    final Color darkBorderColor = hasItems
        ? const Color(0xFF10B981) // আইটেম থাকলে উজ্জ্বল নিওন এমারেল্ড
        : const Color(0xFF475569); // স্পষ্ট দৃশ্যমান মেটালিক বর্ডার

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.identity()
              ..translate(0.0, translateY)
              ..scale(scale),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? darkCardSurface
                  : (hasItems ? const Color(0xFFE8F5E9) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isDark
                    ? darkBorderColor
                    : (hasItems
                          ? const Color(0xFF059669)
                          : const Color(0xFFB0BEC5)),
                width: hasItems ? 2.0 : 1.5,
              ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : widget.isDark
                  ? [
                      // ডার্ক মোডে গভীর শ্যাডো + ওপরের হাইলাইট রিম
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: hasItems
                            ? const Color(0xFF10B981).withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.08),
                        blurRadius: 1,
                        offset: const Offset(0, -1),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.16),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 0,
                        offset: const Offset(0, -2),
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
                              widget.category.svgPath,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => Icon(
                                Icons.bolt_rounded,
                                size: 36,
                                color: widget.isDark
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: widget.isDark
                          ? (hasItems
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFFF1F5F9))
                          : (hasItems
                                ? const Color(0xFF047857)
                                : AppColors.lightTextPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ব্যাজ
        if (hasItems)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.energyGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDark ? const Color(0xFF0F172A) : Colors.white,
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 22),
              child: Center(
                child: Text(
                  '${widget.count}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
