import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool isBangla;

  const ThemeToggleButton({super.key, this.isBangla = true});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final bool isDark = ThemeController.instance.isDarkMode;
        return IconButton(
          tooltip: isDark
              ? (isBangla ? 'লাইট মোড' : 'Light Mode')
              : (isBangla ? 'ডার্ক মোড' : 'Dark Mode'),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark ? AppColors.solarGold : AppColors.primaryGreen,
            size: 20,
          ),
          onPressed: () => ThemeController.instance.toggleTheme(),
        );
      },
    );
  }
}
