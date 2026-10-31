import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

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
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF90D5E7), // উপরের হালকা নীল
              Colors.white, // নিচের সাদা গ্রেডিয়েন্ট
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            // ১. ড্রয়ার হেডার (গাঢ় সবুজ)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 45,
                left: 16,
                right: 16,
                bottom: 20,
              ),
              color: AppColors.primaryGreen,
              child: Row(
                children: [
                  // নামের পাশে appIcon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        AppAssets.appIcon,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.wb_sunny_rounded,
                              color: Colors.orange,
                              size: 30,
                            ),
                      ),
                    ),
                  ),
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
                          isBangla ? 'ঘরের মাঝে রবির কিরণ' : 'Plug to the Sun',
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
                  _divider(),

                  // ২. প্রকল্প (Project)
                  _buildAccordion(
                    context: context,
                    iconPath: AppAssets.iconProject,
                    fallbackIcon: Icons.hub_outlined,
                    title: isBangla ? 'প্রকল্প' : 'Project',
                    children: [
                      _buildSubItem(
                        iconPath: AppAssets.iconLoad,
                        fallbackIcon: Icons.tv_rounded,
                        title: isBangla ? 'উপকরণভিত্তিক' : 'Based on load',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Based on load');
                        },
                      ),
                      _buildSubItem(
                        iconPath: AppAssets.iconLand,
                        fallbackIcon: Icons.aspect_ratio_rounded,
                        title: isBangla ? 'স্থানভিত্তিক' : 'Based on land',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Based on land');
                        },
                      ),
                      _buildSubItem(
                        iconPath: AppAssets.iconCost,
                        fallbackIcon: Icons.currency_lira_rounded,
                        title: isBangla ? 'খরচভিত্তিক' : 'Based on cost',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Based on cost');
                        },
                      ),
                      _buildSubItem(
                        iconPath: AppAssets.iconCapacity,
                        fallbackIcon: Icons.flash_on_rounded,
                        title: isBangla ? 'ক্ষমতাভিত্তিক' : 'Based on capacity',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Based on capacity');
                        },
                      ),
                    ],
                  ),
                  _divider(),

                  // ৩. আর্থিক বিশ্লেষণ
                  _buildSingleItem(
                    iconPath: AppAssets.iconFinancial,
                    fallbackIcon: Icons.attach_money_rounded,
                    title: isBangla ? 'আর্থিক বিশ্লেষণ' : 'Financial Analysis',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('Financial Analysis');
                    },
                  ),
                  _divider(),

                  // ৪. উপকরণ (Tools)
                  _buildAccordion(
                    context: context,
                    iconPath: AppAssets.iconTools,
                    fallbackIcon: Icons.build_outlined,
                    title: isBangla ? 'উপকরণ' : 'Tools',
                    children: [
                      _buildSubItem(
                        iconPath: AppAssets.iconCompass,
                        fallbackIcon: Icons.explore_outlined,
                        title: isBangla ? 'কম্পাস' : 'Compass',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Compass');
                        },
                      ),
                      _buildSubItem(
                        iconPath: AppAssets.iconLeveler,
                        fallbackIcon: Icons.straighten_outlined,
                        title: isBangla ? 'সমতলকারী' : 'Leveler',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('Leveler');
                        },
                      ),
                      _buildSubItem(
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
                  _divider(),

                  // ৫. স্থাপন (Installation)
                  _buildSingleItem(
                    iconPath: AppAssets.iconInstallation,
                    fallbackIcon: Icons.build_circle_outlined,
                    title: isBangla ? 'স্থাপন' : 'Installation',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('Installation');
                    },
                  ),
                  _divider(),

                  // ৬. রক্ষণাবেক্ষণ (Maintenance)
                  _buildSingleItem(
                    iconPath: AppAssets.iconMaintenance,
                    fallbackIcon: Icons.home_repair_service_outlined,
                    title: isBangla ? 'রক্ষণাবেক্ষণ' : 'Maintenance',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('Maintenance');
                    },
                  ),
                  _divider(),

                  // ৭. যোগাযোগ (Contact)
                  _buildSingleItem(
                    iconPath: AppAssets.iconContact,
                    fallbackIcon: Icons.mail_outline_rounded,
                    title: isBangla ? 'যোগাযোগ' : 'Contact',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('Contact');
                    },
                  ),
                  _divider(),

                  // ৮. বিসিএসআইআর ওয়েব
                  _buildSingleItem(
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
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: _buildDynamicIcon(
          iconPath,
          fallbackIcon,
          24,
          AppColors.textDark,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        trailing: const Icon(
          Icons.expand_more_rounded,
          color: AppColors.textDark,
        ),
        children: children,
      ),
    );
  }

  Widget _buildSingleItem({
    String? iconPath,
    IconData? fallbackIcon,
    Widget? customLeading,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading:
          customLeading ??
          _buildDynamicIcon(iconPath, fallbackIcon, 24, AppColors.textDark),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSubItem({
    String? iconPath,
    IconData? fallbackIcon,
    Color? iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.black.withValues(alpha: 0.04),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 48, right: 16),
        leading: _buildDynamicIcon(
          iconPath,
          fallbackIcon,
          20,
          iconColor ?? AppColors.textMuted,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
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

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: Colors.black.withValues(alpha: 0.08),
    );
  }
}
