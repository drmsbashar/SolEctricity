import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

class FabMenu extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // মূল অ্যাকশন বাটন (+ / x)
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.fabGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isOpen ? Icons.close : Icons.add,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ৪টি ড্রপডাউন অপশন
        if (isOpen) ...[
          _buildItem(
            title: isBangla ? 'উপকরণভিত্তিক' : 'Based on load',
            imagePath: AppAssets.menuLoad,
            fallbackIcon: Icons.tv_rounded,
            onTap: () => onSelectOption('Based on load'),
          ),
          _buildItem(
            title: isBangla ? 'স্থানভিত্তিক' : 'Based on land',
            imagePath: AppAssets.menuLand,
            fallbackIcon: Icons.aspect_ratio_rounded,
            onTap: () => onSelectOption('Based on land'),
          ),
          _buildItem(
            title: isBangla ? 'খরচভিত্তিক' : 'Based on cost',
            imagePath: AppAssets.menuCost,
            fallbackText: '৳',
            onTap: () => onSelectOption('Based on cost'),
          ),
          _buildItem(
            title: isBangla ? 'ক্ষমতাভিত্তিক' : 'Based on capacity',
            imagePath: AppAssets.menuCapacity,
            fallbackText: 'kW',
            onTap: () => onSelectOption('Based on capacity'),
          ),
        ],
      ],
    );
  }

  Widget _buildItem({
    required String title,
    required String imagePath,
    IconData? fallbackIcon,
    String? fallbackText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF424242),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
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
          ],
        ),
      ),
    );
  }
}
