import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

// ১. মূল ৩ডি টেকটাইল সোলার কার্ড (Chiseled Bevel Contour)
class SolarCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final VoidCallback? onTap;

  const SolarCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardBody = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              borderColor ??
              (isDark
                  ? AppColors.darkBorder
                  : const Color(0xFFCBD5E1).withValues(alpha: 0.8)),
          width: 1.2,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.energyGreen.withValues(alpha: 0.04),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 0,
                  spreadRadius: 1,
                  offset: Offset(0, -1),
                ),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: cardBody,
        ),
      );
    }

    return cardBody;
  }
}

// ২. খাঁজকাটা বা দেবে থাকা রিসেসড ইনপুট ডিসপ্লে (Sunken Display Bay)
class RecessedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const RecessedContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}

// ৩. হাই-কনট্রাস্ট স্বতন্ত্র ডিজিটাল মিটার ডিসপ্লে (উভয় মোডের জন্য ডিসটিঙ্কট ক্লাস্টার লুক)
class DigitalMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color accentColor;
  final bool isLarge;

  const DigitalMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.accentColor = AppColors.energyGreen,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 10 : 8,
      ),
      decoration: BoxDecoration(
        // ডার্কে নিখুঁত ডিপ টেকনোলজি বেস, লাইটে খাঁটি মেটালিক রিসেসড সিলভার
        color: isDark ? const Color(0xFF060A12) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? accentColor.withValues(
                  alpha: 0.45,
                ) // ডার্কে স্পষ্ট নিয়ন অ্যাকসেন্ট রিম
              : const Color(0xFF94A3B8), // লাইটে স্পষ্ট ডিফাইনড বর্ডার
          width: 1.3,
        ),
        boxShadow: isDark
            ? [
                // ডার্ক মোডে নিয়ন গ্লো (Cyber Glow)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                const BoxShadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : [
                // লাইট মোডে ৩ডি মেটালিক ইনসেট ইফেক্ট
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 0,
                  offset: Offset(0, -1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: isLarge ? 14 : 12,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isLarge ? 11 : 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isLarge ? 20 : 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: -0.5,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF0F172A), // লাইটে খাঁটি কালো-স্লেট
                  shadows: isDark
                      ? [
                          Shadow(
                            color: accentColor.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              if (unit != null && unit!.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: isLarge ? 11 : 10,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ৪. অ্যাকশন বার ও ডিজিটাল প্যানেল কনসোল ফ্রেম
class FrostedGlassBar extends StatelessWidget {
  final Widget child;

  const FrostedGlassBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            // কনসোল ব্যাকগ্রাউন্ডকে স্পষ্ট ও আলাদা প্ল্যাটফর্ম হিসেবে তুলে ধরা
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.95)
                : const Color(0xFFFFFFFF).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF334155) // ডার্কে স্পষ্ট ফ্রেম লাইন
                    : const Color(0xFF94A3B8)
                          .withValues(alpha: 0.6), // লাইটে ডিসটিঙ্কট রিম
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
              if (!isDark)
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 0,
                  offset: Offset(0, -1),
                ),
            ],
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}
