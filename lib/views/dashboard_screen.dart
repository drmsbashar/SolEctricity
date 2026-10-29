import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../widgets/app_drawer.dart';
import '../widgets/fab_menu.dart';

import 'package:url_launcher/url_launcher.dart';

import 'maintenance_screen.dart';

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
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF263238),
      drawer: AppDrawer(
        isBangla: isBangla,
        onNavigate: (route) => _navigateTo(context, route),
        onAboutTap: () => _showAboutDialog(context),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          decoration: BoxDecoration(
            color: AppColors.skyBlue,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // ১. ব্যাকগ্রাউন্ড
              Positioned.fill(
                child: Image.asset(
                  AppAssets.bgHome,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackBackground(),
                ),
              ),

              // ২. মূল কনটেন্ট
              SafeArea(
                child: Column(
                  children: [
                    // হেডার বার
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.menu_rounded,
                                color: Colors.redAccent,
                                size: 26,
                              ),
                            ),
                          ),
                          _buildLanguageButton(),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // টাইটেল
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBangla ? 'সূর্য বিদ্যুৎ' : 'SolEctricity',
                              style: TextStyle(
                                fontSize: isBangla ? 36 : 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.titleRed,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isBangla
                                  ? 'ঘরের মাঝে রবির কিরণ'
                                  : 'Plug to the Sun',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
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
                                Shadow(color: Colors.black45, blurRadius: 4),
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
                                : 'Bangladesh Council of Scientific and Industrial Research',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ৩. ফ্লোটিং অ্যাকশন মেনু
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
      ),
    );
  }

  Widget _buildLanguageButton() {
    return InkWell(
      onTap: toggleLanguage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
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
              color: isBangla ? Colors.blue[800] : Colors.green[800],
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

  Widget _buildFallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF67B7D1), Color(0xFF88C9DC), Color(0xFF2E7D32)],
          stops: [0.0, 0.65, 0.85],
        ),
      ),
    );
  }

  // ওয়েবসাইট খোলার ফাংশন (যেখানে আসল লিংক বসানো আছে)
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

  // মেনুতে ক্লিক করলে যে ফাংশনটি কল হয়
  void _navigateTo(BuildContext context, String option) {
    if (option == 'BCSIR website') {
      _launchBcsirWebsite();
      return;
    }

    if (option == 'Contact') {
      _showContactDialog(context);
      return;
    }

    // রক্ষণাবেক্ষণ পেজে যাওয়া
    if (option == 'Maintenance') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MaintenanceScreen(isBangla: isBangla),
        ),
      );
      return;
    }

    // বাকি পেজগুলোর জন্য সাময়িক মেসেজ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBangla ? '$option পেজ লোড হচ্ছে...' : 'Loading $option...',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBangla ? 'পরিচিতি' : 'About Solectricity'),
        content: Text(
          isBangla
              ? 'বাংলাদেশ বিজ্ঞান ও শিল্প গবেষণা পরিষদ (BCSIR) কর্তৃক প্রস্তুতকৃত সোলার ক্যালকুলেটর অ্যাপ্লিকেশন।'
              : 'Solar calculator mobile application developed by BCSIR.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isBangla ? 'ঠিক আছে' : 'OK'),
          ),
        ],
      ),
    );
  }

  // যোগাযোগ (Contact) ডায়ালগ
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.mail_outline_rounded, color: Color(0xFF1B6A3B)),
            const SizedBox(width: 8),
            Text(
              isBangla ? 'যোগাযোগ' : 'Contact',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                'bashar@agni.com\nbashar@bcsir.gov.bd',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B6A3B),
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
