import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/theme_toggle_button.dart';

class AboutScreen extends StatelessWidget {
  final bool isBangla;

  const AboutScreen({super.key, required this.isBangla});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBangla ? 'পরিচিতি' : 'About'),
        actions: [ThemeToggleButton(isBangla: isBangla)],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkBgTop, AppColors.darkBgBottom]
                : [AppColors.lightBgTop, AppColors.lightBgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderCard(isDark),
                    const SizedBox(height: 16),
                    _buildFeaturesCard(isDark),
                    const SizedBox(height: 16),
                    _buildGoalCard(isDark),
                    const SizedBox(height: 16),
                    _buildInstitutionCard(isDark),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.04),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    'assets/images/app-icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.solar_power_rounded,
                        color: AppColors.primaryGreen,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBangla ? 'সূর্য বিদ্যুৎ' : 'SolEctricity',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.energyGreen
                                : const Color(0xFF1B6A3B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isBangla
                          ? 'স্মার্ট সোলার সাইজিং ও ফিজিবিলিটি সমাধান'
                          : 'Smart Solar Sizing & Feasibility Suite',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(
            height: 24,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Text(
            isBangla
                ? "'সূর্য বিদ্যুৎ (SolEctricity)' হলো একটি প্রকৌশল-মানসম্পন্ন সোলার ফটোভোলটাইক সাইজিং ও কারিগরি সম্ভাব্যতা বিশ্লেষণ সফটওয়্যার। বাংলাদেশ বিজ্ঞান ও শিল্প গবেষণা পরিষদ (BCSIR)-এর নবায়নযোগ্য শক্তি গবেষণার মানদণ্ড এবং নাসা (NASA) ক্লাইমেট ডেটাসেটের ওপর ভিত্তি করে এটি তৈরি করা হয়েছে। এর মাধ্যমে সাধারণ ব্যবহারকারী ও সৌর প্রকৌশলীরা বাস্তবসম্মত ও সাশ্রয়ী উপায়ে অন-গ্রিড, হাইব্রিড বা অফ-গ্রিড সিস্টেমের পূর্ণাঙ্গ পরিকল্পনা করতে পারবেন।"
                : "SolEctricity is an engineering-grade solar photovoltaic sizing and financial feasibility application. Integrating NASA solar radiation databases with localized research benchmarks from the Bangladesh Council of Scientific and Industrial Research (BCSIR), it enables homeowners and solar installers to design technically optimized residential and commercial rooftop systems.",
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : const Color(0xFF37474F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.solarGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'অ্যাপের প্রধান বৈশিষ্ট্যসমূহ' : 'Key Capabilities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : const Color(0xFF263238),
                ),
              ),
            ],
          ),
          Divider(
            height: 20,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          _buildFeatureItem(
            icon: Icons.layers_outlined,
            title: isBangla
                ? 'চার পদ্ধতিতে পূর্ণাঙ্গ সাইজিং'
                : 'Four Calculation Engines',
            desc: isBangla
                ? 'লোড চাহিদা, ছাদ/জমির আয়তন, আর্থিক বাজেট এবং কাঙ্ক্ষিত ক্ষমতার ভিত্তিতে আলাদাভাবে সিস্টেম নির্ধারণ।'
                : 'Design and evaluate systems based on load target, land/roof boundary, investment budget, or system capacity.',
            isDark: isDark,
          ),
          _buildFeatureItem(
            icon: Icons.satellite_alt_rounded,
            title: isBangla
                ? 'স্যাটেলাইট ছাদ পরিমাপ ও লেআউট'
                : 'Geospatial Rooftop Sizing',
            desc: isBangla
                ? 'ম্যাপে বহুভুজ এঁকে সীমানা নির্ধারণ, চিলেকোঠা বা ছায়ার মতো বাধা বাদ দেওয়া এবং ২১ ডিসেম্বরের শীতকালীন ছায়া কোণ অনুযায়ী সারি দূরত্ব (Inter-row pitch) প্রাক্কলন।'
                : 'Polygon boundary mapping with obstacle exclusion and winter solstice shadow clearance for realistic panel layouts.',
            isDark: isDark,
          ),
          _buildFeatureItem(
            icon: Icons.price_check_rounded,
            title: isBangla
                ? 'বাজেটভিত্তিক টার্নকি বিল (BOM)'
                : 'Budget & Turnkey Costing',
            desc: isBangla
                ? 'অন-গ্রিড, হাইব্রিড ও অফ-গ্রিড আর্কিটেকচারে প্যানেল, ইনভার্টার, ব্যাটারি ও ওয়্যারিংয়ের উপাদানভিত্তিক খরচ বিভাজন এবং পে-ব্যাক টাইম গণনা।'
                : 'Automated system capacity (kWp) and turnkey Bill of Materials (BOM) estimation across On-Grid, Hybrid, and Off-Grid architectures.',
            isDark: isDark,
          ),
          _buildFeatureItem(
            icon: Icons.checklist_rtl_rounded,
            title: isBangla ? 'লোড ও ব্যবহার পরিকল্পক' : 'Daily Load Planner',
            desc: isBangla
                ? 'নির্দিষ্ট বাজেট বা ক্ষমতার বিপরীতে লাইট, ফ্যান, টিভি ইত্যাদি ব্যবহারের সময় নির্ধারণ এবং AC/DC ইনভার্টার অপচয় সমন্বয়।'
                : 'Real-time energy balance mapping with AC/DC inverter efficiency derating and overload safeguards.',
            isDark: isDark,
          ),
          _buildFeatureItem(
            icon: Icons.picture_as_pdf_rounded,
            title: isBangla
                ? 'খাঁটি বাংলা ও ইংরেজি PDF রিপোর্ট'
                : 'High-Fidelity PDF Export',
            desc: isBangla
                ? 'ক্যানভাস রেন্ডারিংয়ের মাধ্যমে যুক্তাক্ষর অক্ষুণ্ণ রেখে তাৎক্ষণিক প্রাতিষ্ঠানিক প্রপোজাল তৈরি, প্রিন্ট ও শেয়ারিং সুবিধা।'
                : 'Canvas-rendered, crystal-clear bilingual PDF feasibility proposals detailing GPS coordinates, financial ROI, and annual carbon offsets.',
            isDark: isDark,
          ),
          _buildFeatureItem(
            icon: Icons.compass_calibration_rounded,
            title: isBangla
                ? 'অন-সাইট সেন্সর টুলস'
                : 'Sensors: Compass & Leveler',
            desc: isBangla
                ? 'প্যানেল স্থাপনের সঠিক দিক (অ্যাজিমুথ) ও কাত কোণ (টিল্ট) পরিমাপের জন্য ডিজিটাল কম্পাস ও লেভেলার।'
                : 'Set true south direction and optimal panel tilt using built-in digital compass and leveler sensors.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.accentCyan.withValues(alpha: 0.15)
                  : Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDark ? AppColors.accentCyan : Colors.teal.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF37474F),
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF263238),
                    ),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.energyGreen.withValues(alpha: 0.12)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.energyGreen.withValues(alpha: 0.4)
              : Colors.green.shade300,
          width: 1.2,
        ),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: isDark ? AppColors.energyGreen : const Color(0xFF1B6A3B),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'আমাদের লক্ষ্য ও উদ্দেশ্য' : 'Our Mission',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.energyGreen
                      : const Color(0xFF1B6A3B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isBangla
                ? 'সৌর বিদ্যুৎ ব্যবস্থার জটিল গাণিতিক ও প্রযুক্তিগত হিসাব-নিকাশকে সহজবোধ্য করে নাগরিক ও বিশেষজ্ঞদের হাতে পৌঁছে দেওয়াই এই অ্যাপের লক্ষ্য। স্থানীয় বাজারের মান এবং বাস্তবসম্মত আবহাওয়া তথ্য ব্যবহার করে সিস্টেমের অতিরিক্ত খরচ পরিহার ও দীর্ঘমেয়াদী স্থায়িত্ব নিশ্চিত করাই এর মূল ব্রত।'
                : 'SolEctricity aims to make complex solar engineering and mathematical formulations accessible to citizens, technicians, and researchers. By marrying local market realities with meteorological benchmarks, it ensures cost-effective, durable, and sustainable solar installations.',
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_rounded,
                color: isDark ? AppColors.accentCyan : const Color(0xFF0284C7),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'গবেষণা ও উন্নয়ন' : 'Research & Development',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : const Color(0xFF263238),
                ),
              ),
            ],
          ),
          Divider(
            height: 20,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Text(
            isBangla
                ? 'ইনস্টিটিউট অব এনার্জি রিসার্চ অ্যান্ড ডেভেলপমেন্ট (আইইআরডি)\nবাংলাদেশ বিজ্ঞান ও শিল্প গবেষণা পরিষদ (বিসিএসআইআর)\nবিজ্ঞান ও প্রযুক্তি মন্ত্রণালয়\nড. কুদরত-এ-খুদা সড়ক, ধানমন্ডি, ঢাকা-১২০৫, বাংলাদেশ।'
                : 'Institute of Energy Research and Development (IERD)\nBangladesh Council of Scientific and Industrial Research (BCSIR)\nMinistry of Science and Technology\nDr. Qudrat-i-Khuda Road, Dhanmondi, Dhaka-1205, Bangladesh.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
