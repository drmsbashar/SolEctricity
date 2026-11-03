import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/fab_menu.dart';
import '../widgets/theme_toggle_button.dart';
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
            // ১. ব্যাকগ্রাউন্ড ইমেজ (ডার্ক ও লাইট মোডে স্বতন্ত্র ব্যাকগ্রাউন্ড)
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

            // ২. থিম-সচেতন গ্রেডিয়েন্ট ওভারলে (ডার্ক মোডে কোনো কালো শেড নেই)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [Colors.transparent, Colors.transparent]
                        : [
                            AppColors.lightBgTop.withValues(alpha: 0.15),
                            AppColors.lightBgBottom.withValues(alpha: 0.45),
                          ],
                  ),
                ),
              ),
            ),

            // ৩. মূল কনটেন্ট (UI)
            SafeArea(
              child: Column(
                children: [
                  // হেডার বার (ড্রয়ার মেনু, সেন্ট্রাল থিম টগল ও ভাষা বাটন)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCardBg.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.menu_rounded,
                              color: isDark
                                  ? AppColors.accentCyan
                                  : Colors.redAccent,
                              size: 26,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // ☀️/🌙 স্ট্যান্ডার্ডাইজড থিম টগল বাটন
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCardBg.withValues(
                                        alpha: 0.9,
                                      )
                                    : Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ThemeToggleButton(isBangla: isBangla),
                            ),
                            const SizedBox(width: 8),
                            _buildLanguageButton(isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),

                  // টাইটেল (অ্যানিমেটেড ঝলমলে সূর্য + ভাষা অনুযায়ী PNG টাইটেল লোগো + সাবটাইটেল)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ১. আগুনের ঝলকানিযুক্ত কাস্টম অ্যানিমেটেড সূর্য
                          const SolarFusionSun(size: 60),
                          const SizedBox(width: 14),

                          // ২. টাইটেল লোগো ও সাবটাইটেল
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // “সূর্য বিদ্যুৎ / SolEctricity” লেখার বদলে আপনার PNG লোগো
                                Image.asset(
                                  isBangla
                                      ? 'assets/images/app_logo_bn.png' // 👈 বাংলা লোগো
                                      : 'assets/images/app_logo_en.png', // 👈 ইংরেজি লোগো
                                  height: 40, // আপনার ছবির অনুপাত অনুযায়ী ৩৫-৪৫ দিতে পারেন
                                  fit: BoxFit.contain,
                                  alignment: Alignment.centerLeft,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                        isBangla
                                            ? 'সূর্য বিদ্যুৎ'
                                            : 'SolEctricity',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? AppColors.energyGreen
                                              : AppColors.titleRed,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                // ট্যাগলাইন / সাবটাইটেল
                                Text(
                                  isBangla
                                      ? 'ঘরের মাঝে রবির কিরণ'
                                      : 'Plug to the Sun',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textDark,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(1, 1),
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
                  ),
                  const Spacer(flex: 5),

                  // ফুটার
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Image.asset(
                          AppAssets.bcsirLogo,
                          height: 44,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.account_balance,
                                size: 40,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isBangla
                              ? 'বাংলাদেশ বিজ্ঞান ও শিল্প গবেষণা পরিষদ\nবিজ্ঞান ও প্রযুক্তি মন্ত্রণালয়'
                              : 'Bangladesh Council of Scientific and Industrial Research\nMinistry of Science and Technology',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ৪. ফ্লোটিং অ্যাকশন মেনু
            Positioned(
              top: 250,
              right: 20,
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

  Widget _buildLanguageButton(bool isDark) {
    return InkWell(
      onTap: toggleLanguage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCardBg.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.black12,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: 16,
              color: isBangla ? Colors.blue[700] : Colors.green[700],
            ),
            const SizedBox(width: 5),
            Text(
              isBangla ? 'En' : 'বাং',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isBangla ? Colors.blue[900] : Colors.green[900],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.mail_outline_rounded,
              color: isDark ? AppColors.accentCyan : const Color(0xFF1B6A3B),
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
                fontSize: 14,
                height: 1.4,
                color: isDark ? AppColors.darkTextSecondary : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                ),
              ),
              child: SelectableText(
                'bashar@agni.com\nbashar@bcsir.gov.bd',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.accentCyan
                      : const Color(0xFF1B6A3B),
                  height: 1.5,
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

/// বাস্তব সূর্যের অগ্নিকুণ্ড ও আগুনের ঝলকানির সূর্য
/// (Organic Solar Corona & Dynamic Flame Flares)
class SolarFusionSun extends StatefulWidget {
  final double size;
  final bool isMini;

  const SolarFusionSun({super.key, this.size = 64, this.isMini = false});

  @override
  State<SolarFusionSun> createState() => _SolarFusionSunState();
}

class _SolarFusionSunState extends State<SolarFusionSun>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // অবিরাম ধীরগতিতে আবর্তন ও আগুনের শিখার নৃত্য
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // ফিউশন কোর ও আগুনের মৃদু প্রাকৃতিক স্পন্দন (Breathing Flame Pulse)
        final pulse =
            1.0 + 0.05 * math.sin(_controller.value * 2 * math.pi * 4);

        return Transform.scale(
          scale: widget.isMini ? 1.0 : pulse,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ১. দূরবর্তী বহিরাগত লালচে-কমলা অগ্নিরশ্মি স্তর (ঘড়ির কাটার দিকে ধীর ঘূর্ণন)
                Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _SolarFlamePainter(
                      animValue: _controller.value,
                      flareColor: const Color(0xFFEA580C), // প্লাজমা অরেঞ্জ
                      flameCount: widget.isMini ? 8 : 12,
                      scaleFactor: 1.0,
                    ),
                  ),
                ),

                // ২. অভ্যন্তরীণ সোনালি-হলুদ আগুনের ঝলকানি স্তর (বিপরীত ঘূর্ণন ও দ্রুত শিখা)
                Transform.rotate(
                  angle: -_controller.value * 2 * math.pi * 0.7,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _SolarFlamePainter(
                      animValue: _controller.value + 0.3,
                      flareColor: const Color(0xFFFBBF24), // অ্যাম্বার গোল্ড
                      flameCount: widget.isMini ? 6 : 10,
                      scaleFactor: 0.86,
                    ),
                  ),
                ),

                // ৩. প্লাজমা করোনা আভা (Soft Corona Glow Cloud)
                Container(
                  width: widget.size * 0.70,
                  height: widget.size * 0.70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.7),
                        const Color(0xFFDC2626).withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.35, 0.75, 1.0],
                    ),
                  ),
                ),

                // ৪. জ্বলন্ত কেন্দ্রীয় পারমাণবিক ফিউশন কোর (উজ্জ্বল সাদা ও আগুনের বৃত্ত)
                Container(
                  width: widget.size * 0.46,
                  height: widget.size * 0.46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFFEF08A), // লেমন সোনালি কোর
                        Color(0xFFF59E0B), // প্রখর অ্যাম্বার
                        Color(0xFFDC2626), // জ্বলন্ত অগ্নি লাল
                      ],
                      stops: [0.12, 0.45, 0.80, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                        blurRadius: widget.size * 0.35,
                        spreadRadius: widget.size * 0.06,
                      ),
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.6),
                        blurRadius: widget.size * 0.55,
                        spreadRadius: widget.size * 0.12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// বক্রাকার অগ্নিরশ্মি ও শিখা (Bézier Flame Tongues) অঙ্কনের কাস্টম পেইন্টার
class _SolarFlamePainter extends CustomPainter {
  final double animValue;
  final Color flareColor;
  final int flameCount;
  final double scaleFactor;

  _SolarFlamePainter({
    required this.animValue,
    required this.flareColor,
    required this.flameCount,
    required this.scaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width * 0.22) * scaleFactor;
    final maxRadius = (size.width * 0.48) * scaleFactor;

    for (int i = 0; i < flameCount; i++) {
      final angle = (i * 2 * math.pi) / flameCount;

      // প্রতিটি শিখার স্বতন্ত্র দোলাচল ও গতিশীল দৈর্ঘ্য (Living flame shimmer)
      final flicker = math.sin((animValue * 2 * math.pi * 3) + (i * 1.5));
      final flameLength = maxRadius + (flicker * (size.width * 0.04));

      final path = Path();

      // আগুনের শিখার শুরু (গোড়া)
      final startX = center.dx + baseRadius * math.cos(angle - 0.16);
      final startY = center.dy + baseRadius * math.sin(angle - 0.16);

      // আগুনের শিখার ডগা (Tip of the flare)
      final tipX = center.dx + flameLength * math.cos(angle);
      final tipY = center.dy + flameLength * math.sin(angle);

      // আগুনের শিখার শেষ প্রান্ত (গোড়া)
      final endX = center.dx + baseRadius * math.cos(angle + 0.16);
      final endY = center.dy + baseRadius * math.sin(angle + 0.16);

      // বক্রতা ও শিখা ফোটানোর কন্ট্রোল পয়েন্ট
      final ctrlDist = flameLength * 0.65;
      final ctrlX1 = center.dx + ctrlDist * math.cos(angle - 0.28);
      final ctrlY1 = center.dy + ctrlDist * math.sin(angle - 0.28);

      final ctrlX2 = center.dx + ctrlDist * math.cos(angle + 0.10);
      final ctrlY2 = center.dy + ctrlDist * math.sin(angle + 0.10);

      path.moveTo(startX, startY);
      path.quadraticBezierTo(ctrlX1, ctrlY1, tipX, tipY);
      path.quadraticBezierTo(ctrlX2, ctrlY2, endX, endY);
      path.close();

      // মসৃণ স্বচ্ছতাযুক্ত আগুনের গ্রেডিয়েন্ট পেইন্ট
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            flareColor.withValues(alpha: 0.85),
            flareColor.withValues(alpha: 0.15),
            Colors.transparent,
          ],
          stops: const [0.2, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SolarFlamePainter oldDelegate) => true;
}
