import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

class FabMenu extends StatefulWidget {
  final bool isOpen;
  final bool isBangla;
  final VoidCallback onToggle;
  final Function(String option) onSelectOption;

  const FabMenu({
    super.key,
    required this.isOpen,
    required this.isBangla,
    required this.onToggle,
    required this.onSelectOption,
  });

  @override
  State<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<FabMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    if (widget.isOpen) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant FabMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final options = [
      {
        'title': widget.isBangla ? 'উপকরণভিত্তিক' : 'Based on load',
        'image': AppAssets.menuLoad,
        'fallbackIcon': Icons.tv_rounded,
        'route': 'Based on load',
      },
      {
        'title': widget.isBangla ? 'স্থানভিত্তিক' : 'Based on land',
        'image': AppAssets.menuLand,
        'fallbackIcon': Icons.aspect_ratio_rounded,
        'route': 'Based on land',
      },
      {
        'title': widget.isBangla ? 'খরচভিত্তিক' : 'Based on cost',
        'image': AppAssets.menuCost,
        'fallbackText': '৳',
        'route': 'Based on cost',
      },
      {
        'title': widget.isBangla ? 'চাহিদাভিত্তিক' : 'Based on capacity',
        'image': AppAssets.menuCapacity,
        'fallbackText': 'kW',
        'route': 'Based on capacity',
      },
    ];

    return SizeTransition(
      sizeFactor: _expandAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in options)
              _buildMenuItem(
                title: item['title'] as String,
                imagePath: item['image'] as String,
                fallbackIcon: item['fallbackIcon'] as IconData?,
                fallbackText: item['fallbackText'] as String?,
                onTap: () {
                  widget.onToggle();
                  widget.onSelectOption(item['route'] as String);
                },
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String imagePath,
    IconData? fallbackIcon,
    String? fallbackText,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ১. বামে আইকন
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF424242),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.energyGreen : Colors.white24,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: fallbackText != null
                          ? Text(
                              fallbackText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                          : Icon(fallbackIcon, color: Colors.white, size: 20),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ২. ডানে টেক্সট
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
