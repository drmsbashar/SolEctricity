import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import 'solar_fusion_sun.dart';

class AppDrawer extends StatelessWidget {
  final bool isBangla;
  final Function(String routeName) onNavigate;
  final VoidCallback onAboutTap;

  const AppDrawer({
    super.key,
    required this.isBangla,
    required this.onNavigate,
    required this.onAboutTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFF90D5E7), Colors.white],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            // ১. ড্রয়ার হেডার (সোলার ফিউশন আইকন)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 45,
                left: 16,
                right: 16,
                bottom: 20,
              ),
              color: isDark ? const Color(0xFF0F172A) : AppColors.primaryGreen,
              child: Row(
                children: [
                  SolarFusionSun(size: 56, isMini: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBangla ? 'সূর্য বিদ্যুৎ' : 'SolEctricity',
                          style: TextStyle(
                            fontSize: isBangla ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBangla
                              ? 'ঘরের মাঝে রবির কিরণ'
                              : 'Plug into the Sun',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ২. ড্রয়ারের মেনু তালিকা
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ১. হোম
                  _buildAccordion(
                    context: context,
                    iconPath: AppAssets.iconHome,
                    fallbackIcon: Icons.home_outlined,
                    title: isBangla ? 'হোম' : 'Home',
                    children: [
                      _buildSubItem(
                        context: context,
                        iconPath: AppAssets.iconAbout,
                        fallbackIcon: Icons.info_outline,
                        iconColor: Colors.amber[800],
                        title: isBangla ? 'পরিচিতি' : 'About',
                        onTap: () {
                          Navigator.pop(context);
                          onAboutTap();
                        },
                      ),
                      _buildSubItem(
                        context: context,
                        iconPath: AppAssets.iconLicense,
                        fallbackIcon: Icons.badge_outlined,
                        title: isBangla ? 'অনুমোদন' : 'License',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('License');
                        },
                      ),
                    ],
                  ),
                  _divider(isDark),

                  // ২. প্রকল্প (Project)
                  _buildAccordion(
                    context: context,
                    iconPath: AppAssets.iconProject,
                    fallbackIcon: Icons.hub_outlined,
                    title: isBangla ? 'প্রকল্প' : 'Project',
                    children: [
                      _buildSubItem(
                        context: context,
                        iconPath: AppAssets.iconLoad,
                        fallbackIcon: Icons.tv_rounded,
                        title: isBangla ? 'উপকরণভিত্তিক' : 'Based on load',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Based on load');
                        },
                      ),
                      _buildSubItem(
                        context: context,
                        iconPath: AppAssets.iconLand,
                        fallbackIcon: Icons.aspect_ratio_rounded,
                        title: isBangla ? 'স্থানভিত্তিক' : 'Based on land',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Based on land');
                        },
                      ),
                      _buildSubItem(
                        context: context,
                        iconPath: AppAssets.iconCost,
                        fallbackIcon: Icons.currency_lira_rounded,
                        title: isBangla ? 'খরচভিত্তিক' : 'Based on cost',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Based on cost');
                        },
                      ),
                      _buildSubItem(
                        context: context,
                        iconPath: AppAssets.iconCapacity,
                        fallbackIcon: Icons.flash_on_rounded,
                        title: isBangla ? 'চাহিদাভিত্তিক' : 'Based on capacity',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Based on capacity');
                        },
                      ),
                    ],
                  ),
                  _divider(isDark),

                  // ৩. আর্থিক বিশ্লেষণ
                  _buildSingleItem(
                    context: context,
                    iconPath: AppAssets.iconFinancial,
                    fallbackIcon: Icons.attach_money_rounded,
                    title: isBangla ? 'আর্থিক বিশ্লেষণ' : 'Financial Analysis',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('Financial Analysis');
                    },
                  ),
                  _divider(isDark),

                  // ৪. উপকরণ (Tools)
                  _buildAccordion(
                    context: context,
                    iconPath: AppAssets.iconTools,
                    fallbackIcon: Icons.build_outlined,
                    title: isBangla ? 'উপকরণ' : 'Tools',
                    children: [
                      _buildSubItem(
                        context: context,
                        iconPath: AppAssets.iconCompass,
                        fallbackIcon: Icons.explore_outlined,
                        title: isBangla ? 'কম্পাস' : 'Compass',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Compass');
                        },
                      ),
                      _buildSubItem(
                        context: context,
                        iconPath: AppAssets.iconLeveler,
                        fallbackIcon: Icons.straighten_outlined,
                        title: isBangla ? 'সমতলকারী' : 'Leveler',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Leveler');
                        },
                      ),
                      _buildSubItem(
                        context: context,
                        iconPath: AppAssets.iconProtractor,
                        fallbackIcon: Icons.change_history_outlined,
                        title: isBangla ? 'চাঁদা' : 'Protractor',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Protractor');
                        },
                      ),
                    ],
                  ),
                  _divider(isDark),

                  // ৫. স্থাপন (Installation)
                  _buildSingleItem(
                    context: context,
                    iconPath: AppAssets.iconInstallation,
                    fallbackIcon: Icons.build_circle_outlined,
                    title: isBangla ? 'স্থাপন' : 'Installation',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('Installation');
                    },
                  ),
                  _divider(isDark),

                  // ৬. রক্ষণাবেক্ষণ (Maintenance)
                  _buildSingleItem(
                    context: context,
                    iconPath: AppAssets.iconMaintenance,
                    fallbackIcon: Icons.home_repair_service_outlined,
                    title: isBangla ? 'রক্ষণাবেক্ষণ' : 'Maintenance',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('Maintenance');
                    },
                  ),
                  _divider(isDark),

                  // ৭. যোগাযোগ (Contact)
                  _buildSingleItem(
                    context: context,
                    iconPath: AppAssets.iconContact,
                    fallbackIcon: Icons.mail_outline_rounded,
                    title: isBangla ? 'যোগাযোগ' : 'Contact',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('Contact');
                    },
                  ),
                  _divider(isDark),

                  // ৮. বিসিএসআইআর ওয়েব
                  _buildSingleItem(
                    context: context,
                    customLeading: Image.asset(
                      AppAssets.bcsirLogo,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.public,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                    ),
                    title: isBangla ? 'বিসিএসআইআর ওয়েব' : 'BCSIR website',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('BCSIR website');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccordion({
    required BuildContext context,
    String? iconPath,
    IconData? fallbackIcon,
    required String title,
    required List<Widget> children,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor = isDark ? Colors.white : AppColors.textDark;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: _buildDynamicIcon(iconPath, fallbackIcon, 24, itemColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: itemColor,
          ),
        ),
        trailing: Icon(Icons.expand_more_rounded, color: itemColor),
        children: children,
      ),
    );
  }

  Widget _buildSingleItem({
    required BuildContext context,
    String? iconPath,
    IconData? fallbackIcon,
    Widget? customLeading,
    required String title,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor = isDark ? Colors.white : AppColors.textDark;

    return ListTile(
      leading:
          customLeading ??
          _buildDynamicIcon(iconPath, fallbackIcon, 24, itemColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: itemColor,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSubItem({
    required BuildContext context,
    String? iconPath,
    IconData? fallbackIcon,
    Color? iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 48, right: 16),
        leading: _buildDynamicIcon(
          iconPath,
          fallbackIcon,
          20,
          iconColor ?? (isDark ? Colors.white70 : AppColors.textMuted),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFCBD5E1) : AppColors.textDark,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDynamicIcon(
    String? path,
    IconData? fallbackIcon,
    double size,
    Color color,
  ) {
    if (path == null) {
      return Icon(fallbackIcon, size: size, color: color);
    }
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        placeholderBuilder: (context) =>
            Icon(fallbackIcon, size: size, color: color),
      );
    } else {
      return Image.asset(
        path,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) =>
            Icon(fallbackIcon, size: size, color: color),
      );
    }
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.08),
    );
  }
}
