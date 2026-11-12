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
import 'contact_screen.dart';
import 'cost_based_solar_screen.dart';
import 'installation_screen.dart';
import 'land_based_solar_screen.dart';
import 'license_screen.dart';
import 'load_selection_screen.dart';
import 'maintenance_screen.dart';
import 'tools_screen.dart';
import 'financial_analysis_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isBangla = true;
  bool isMenuOpen = false;

  // 🎛️ ফ্লোটিং কন্ট্রোল স্লাইড অ্যানিমেশন
  late AnimationController _controlsAnimationController;
  late Animation<Offset> _leftSlideAnimation;
  late Animation<Offset> _rightSlideAnimation;
  bool _areControlsVisible = false; // শুরুতে বাটনগুলো অদৃশ্য থাকবে

  @override
  void initState() {
    super.initState();
    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // বাঁ দিক থেকে ড্রয়ার বাটন স্লাইড হওয়া
    _leftSlideAnimation =
        Tween<Offset>(
          begin: const Offset(-2.0, 0.0), // স্ক্রিনের বাঁয়ে লুকানো থাকবে
          end: Offset.zero, // দৃশ্যমান পজিশন
        ).animate(
          CurvedAnimation(
            parent: _controlsAnimationController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    // ডান দিক থেকে মোড ও ভাষা বাটন স্লাইড হওয়া
    _rightSlideAnimation =
        Tween<Offset>(
          begin: const Offset(2.0, 0.0), // স্ক্রিনের ডানে লুকানো থাকবে
          end: Offset.zero, // দৃশ্যমান পজিশন
        ).animate(
          CurvedAnimation(
            parent: _controlsAnimationController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _controlsAnimationController.value = 0.0;
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    super.dispose();
  }

  void _toggleFloatingControls() {
    setState(() {
      _areControlsVisible = !_areControlsVisible;
      if (_areControlsVisible) {
        _controlsAnimationController.forward();
      } else {
        _controlsAnimationController.reverse();
      }
    });
  }

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

    // 🌟 স্ক্রিন সাইজ অনুযায়ী ডায়নামিক স্কেলিং (সর্বনিম্ন ও সর্বোচ্চ সীমা সহ)
    final double screenHeight = MediaQuery.of(context).size.height;
    final double dynamicLogoHeight = (screenHeight * 0.075).clamp(52.0, 78.0);
    final double dynamicSunSize = (screenHeight * 0.10).clamp(72.0, 96.0);

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
            // ১. ব্যাকগ্রাউন্ড ইমেজ (স্ক্রিনে ট্যাপ ডিটেক্টর)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleFloatingControls,
                child: Image.asset(
                  isDark ? AppAssets.bgHomeDark : AppAssets.bgHome,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackBackground(isDark),
                ),
              ),
            ),

            // ২. সূক্ষ্ম গ্রেডিয়েন্ট ওভারলে
            Positioned.fill(
              child: IgnorePointer(
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
            ),

            // ৩. মূল কনটেন্ট (টাইটেল, ফিউশন সূর্য, এবং ফুটার)
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  const Spacer(flex: 3),

                  // ৩.১ ব্যানারহীন ওপেন টাইটেল সেকশন (ডায়নামিক ও ফুল ব্লক ট্যাপযোগ্য)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GestureDetector(
                      onTap: toggleMenu,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 🌟 ডায়নামিক সাইজের ফিউশন-সান
                          SolarFusionSun(size: dynamicSunSize, isMini: true),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 🌟 ডায়নামিক উচ্চতার লোগো
                                Image.asset(
                                  isBangla
                                      ? AppAssets.logoBn
                                      : AppAssets.logoEn,
                                  height: dynamicLogoHeight,
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
                                // 🌟 স্লোগানে FittedBox যুক্ত করা হলো যাতে কোনো ডিভাইসেই লাইন ভেঙে না যায়
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    isBangla
                                        ? 'ঘরের মাঝে রবির কিরণ'
                                        : 'Plug into the Sun',
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
                                              : Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                          blurRadius: 3,
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 5),

                  // ৩.২ ব্যানারহীন ওপেন বিসিএসআইআর ফুটার প্ল্যাটফর্ম
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

            // ৪. সোলার ফিউশন ড্রপ-ডাউন মেনু
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

            // ৫. ফ্লোটিং স্লাইডিং কন্ট্রোলস (ড্রয়ার বাটন)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: SlideTransition(
                    position: _leftSlideAnimation,
                    child: _buildTactileCircleButton(
                      icon: Icons.menu_rounded,
                      iconColor: isDark
                          ? AppColors.accentCyan
                          : AppColors.primaryGreen,
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),

            // ৬. ফ্লোটিং স্লাইডিং কন্ট্রোলস (মোড ও ভাষা বাটন)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: SlideTransition(
                    position: _rightSlideAnimation,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTactileCircleButton(
                          customChild: ThemeToggleButton(isBangla: isBangla),
                          onTap: null,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildTactileLanguageButton(isDark),
                      ],
                    ),
                  ),
                ),
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

    // 🌟 ডায়ালগের পরিবর্তে সরাসরি ContactScreen ওপেন করা হচ্ছে
    if (option == 'Contact' || option == 'যোগাযোগ') {
      _openScreen(ContactScreen(isBangla: isBangla));
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

    if (option == 'Financial Analysis' ||
        option == 'আর্থিক বিশ্লেষণ' ||
        lower.contains('financial')) {
      _openScreen(
        FinancialAnalysisScreen(
          isBangla: isBangla,
          onToggleLanguage: toggleLanguage,
        ),
      );
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
}
