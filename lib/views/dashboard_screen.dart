import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/fab_menu.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/solar_fusion_sun.dart';
import 'about_screen.dart';
import 'capacity_based_solar_screen.dart';
import 'cost_based_solar_screen.dart';
import 'installation_screen.dart';
import 'land_based_solar_screen.dart';
import 'license_screen.dart';
import 'load_selection_screen.dart';
import 'maintenance_screen.dart';
import 'tools_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isBangla = true;
  bool isMenuOpen = false;

  void toggleLanguage() {
    setState(() {
      isBangla = !isBangla;
    });
  }

  void toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        isBangla: isBangla,
        onNavigate: (route) => _navigateTo(context, route),
        onAboutTap: () => _openScreen(AboutScreen(isBangla: isBangla)),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // ১. ব্যাকগ্রাউন্ড ইমেজ
            Positioned.fill(
              child: Image.asset(
                isDark ? AppAssets.bgHomeDark : AppAssets.bgHome,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackBackground(isDark),
              ),
            ),

            // ২. সূক্ষ্ম গ্রেডিয়েন্ট ওভারলে
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.black.withValues(alpha: 0.20),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.40),
                          ]
                        : [
                            AppColors.lightBgTop.withValues(alpha: 0.10),
                            Colors.transparent,
                            AppColors.lightBgBottom.withValues(alpha: 0.35),
                          ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // ৩. মূল কনটেন্ট (UI)
            SafeArea(
              child: Column(
                children: [
                  // ৩.১ হেডার কন্ট্রোল বার (Drawer, Theme, Language)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ড্রয়ার বাটন
                        _buildTactileCircleButton(
                          icon: Icons.menu_rounded,
                          iconColor: isDark
                              ? AppColors.accentCyan
                              : AppColors.primaryGreen,
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          isDark: isDark,
                        ),

                        // থিম টগল ও ভাষা বাটন
                        Row(
                          children: [
                            _buildTactileCircleButton(
                              customChild: ThemeToggleButton(
                                isBangla: isBangla,
                              ),
                              onTap: null,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            _buildTactileLanguageButton(isDark),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ৩.২ ব্যানারহীন ওপেন টাইটেল সেকশন
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // সোলার ফিউশন সূর্য আইকন (ট্যাপ করলে ড্রপডাউন টগল হবে)
                        GestureDetector(
                          onTap: toggleMenu,
                          behavior: HitTestBehavior.opaque,
                          child: const SolarFusionSun(size: 90, isMini: true),
                        ),
                        const SizedBox(width: 14),

                        // লোগো ও সাবটাইটেল
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                isBangla ? AppAssets.logoBn : AppAssets.logoEn,
                                height: 76,
                                fit: BoxFit.contain,
                                alignment: Alignment.centerLeft,
                                errorBuilder: (context, error, stackTrace) =>
                                    Text(
                                      isBangla
                                          ? 'সূর্য বিদ্যুৎ'
                                          : 'SolEctricity',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? AppColors.energyGreen
                                            : AppColors.titleRed,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black38,
                                            blurRadius: 4,
                                            offset: Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isBangla
                                    ? 'ঘরের মাঝে রবির কিরণ'
                                    : 'Plug to the Sun',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textDark,
                                  shadows: [
                                    Shadow(
                                      color: isDark
                                          ? Colors.black87
                                          : Colors.white.withValues(alpha: 0.8),
                                      blurRadius: 3,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 5),

                  // ৩.৩ ব্যানারহীন ওপেন বিসিএসআইআর ফুটার প্ল্যাটফর্ম
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isBangla ? 'উপস্থাপনায়' : 'Developed by',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Image.asset(
                          AppAssets.bcsirLogo,
                          height: 46,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.account_balance,
                                size: 50,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isBangla
                              ? 'বাংলাদেশ বিজ্ঞান ও শিল্প গবেষণা পরিষদ\nবিজ্ঞান ও প্রযুক্তি মন্ত্রণালয়'
                              : 'Bangladesh Council of Scientific and Industrial Research\nMinistry of Science and Technology',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.textDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                            shadows: [
                              Shadow(
                                color: isDark
                                    ? Colors.black87
                                    : Colors.white.withValues(alpha: 0.9),
                                blurRadius: 4,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ৪. সোলার ফিউশন ড্রপ-ডাউন মেনু (সূর্যের ঠিক নিচে স্বাধীন লেয়ার হিসেবে অবস্থান করবে)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45,
              left: 50,
              child: FabMenu(
                isOpen: isMenuOpen,
                isBangla: isBangla,
                onToggle: toggleMenu,
                onSelectOption: (option) => _navigateTo(context, option),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTactileCircleButton({
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
    Widget? customChild,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : const Color(0xFFCBD5E1).withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          if (!isDark)
            const BoxShadow(
              color: Colors.white,
              blurRadius: 0,
              offset: Offset(0, -1),
            ),
        ],
      ),
      child:
          customChild ??
          IconButton(
            icon: Icon(icon, color: iconColor, size: 24),
            onPressed: onTap,
            splashRadius: 24,
          ),
    );
  }

  Widget _buildTactileLanguageButton(bool isDark) {
    return InkWell(
      onTap: toggleLanguage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : const Color(0xFFCBD5E1).withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: 16,
              color: isDark ? AppColors.accentCyan : AppColors.energyGreen,
            ),
            const SizedBox(width: 6),
            Text(
              isBangla ? 'EN' : 'বাং',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [AppColors.darkBgTop, AppColors.darkBgBottom]
              : [AppColors.lightBgTop, AppColors.lightBgBottom],
        ),
      ),
    );
  }

  Future<void> _launchBcsirWebsite() async {
    final Uri url = Uri.parse('https://bcsir.gov.bd');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBangla
                  ? 'ওয়েবসাইটটি খোলা সম্ভব হয়নি।'
                  : 'Could not launch website.',
            ),
          ),
        );
      }
    }
  }

  void _openScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _navigateTo(BuildContext context, String option) {
    if (option == 'BCSIR website') {
      _launchBcsirWebsite();
      return;
    }
    if (option == 'Contact' || option == 'যোগাযোগ') {
      _showContactDialog(context);
      return;
    }

    final lower = option.toLowerCase();

    if (lower.contains('load') ||
        option.contains('লোড') ||
        option.contains('উপকরণভিত্তিক')) {
      _openScreen(
        LoadSelectionScreen(
          isBangla: isBangla,
          onToggleLanguage: toggleLanguage,
        ),
      );
      return;
    }

    if (lower.contains('land') ||
        lower.contains('location') ||
        option.contains('স্থান') ||
        option.contains('জমি')) {
      _openScreen(LandBasedSolarScreen(isBangla: isBangla));
      return;
    }

    if (lower.contains('cost') ||
        lower.contains('budget') ||
        option.contains('খরচ') ||
        option.contains('বাজেট')) {
      _openScreen(
        CostBasedSolarScreen(
          isBangla: isBangla,
          onToggleLanguage: toggleLanguage,
        ),
      );
      return;
    }

    if (lower.contains('capacity') ||
        lower.contains('demand') ||
        option.contains('ক্ষমতা') ||
        option.contains('চাহিদা')) {
      _openScreen(
        CapacityBasedSolarScreen(
          isBangla: isBangla,
          onToggleLanguage: toggleLanguage,
        ),
      );
      return;
    }

    if (option == 'Tools' ||
        option == 'Compass' ||
        option == 'উপকরণ' ||
        option == 'কম্পাস') {
      _openScreen(ToolsScreen(isBangla: isBangla, initialIndex: 0));
      return;
    }

    if (option == 'Leveler' || option == 'লেভেলার' || option == 'সমতলকারী') {
      _openScreen(ToolsScreen(isBangla: isBangla, initialIndex: 1));
      return;
    }

    if (option == 'Protractor' || option == 'চাঁদা' || option == 'কোণ') {
      _openScreen(ToolsScreen(isBangla: isBangla, initialIndex: 2));
      return;
    }

    if (option == 'About' || option == 'পরিচিতি') {
      _openScreen(AboutScreen(isBangla: isBangla));
      return;
    }

    if (option == 'License' ||
        option == 'অনুমোদন' ||
        lower.contains('privacy') ||
        option.contains('নীতি')) {
      _openScreen(LicenseScreen(isBangla: isBangla));
      return;
    }

    if (option == 'Maintenance' || option == 'রক্ষণাবেক্ষণ') {
      _openScreen(MaintenanceScreen(isBangla: isBangla));
      return;
    }

    if (option == 'Installation' || option == 'স্থাপন') {
      _openScreen(InstallationScreen(isBangla: isBangla));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBangla ? '$option পেজ লোড হচ্ছে...' : 'Loading $option...',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(
              Icons.mail_outline_rounded,
              color: isDark ? AppColors.accentCyan : AppColors.primaryGreen,
            ),
            const SizedBox(width: 8),
            Text(
              isBangla ? 'যোগাযোগ' : 'Contact',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBangla
                  ? 'পরবর্তী কোন সংশোধন, তথ্য ও পরামর্শের জন্য ইমেইলে যোগাযোগ করুন:'
                  : 'For any additional correction, information, or suggestion, please contact through e-mail:',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isDark ? AppColors.darkTextSecondary : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                ),
              ),
              child: SelectableText(
                'bashar@agni.com\nbashar@bcsir.gov.bd',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.accentCyan : AppColors.primaryGreen,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isBangla ? 'ঠিক আছে' : 'OK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.accentCyan : AppColors.energyGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
