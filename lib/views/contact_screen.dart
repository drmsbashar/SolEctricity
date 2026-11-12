import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../widgets/theme_toggle_button.dart';

class ContactScreen extends StatelessWidget {
  final bool isBangla;

  const ContactScreen({super.key, required this.isBangla});

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'bashar@bcsir.gov.bd',
      queryParameters: {
        'subject': isBangla
            ? 'SolEctricity — কারিগরি সহায়তা ও অনুসন্ধান'
            : 'SolEctricity — Technical Support & Inquiry',
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBangla
                    ? 'ইমেইল অ্যাপ চালু করা যায়নি: bashar@bcsir.gov.bd'
                    : 'Could not open email app: bashar@bcsir.gov.bd',
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error launching email client: bashar@bcsir.gov.bd'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBangla ? 'যোগাযোগ' : 'Contact Us'),
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
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAddressCard(isDark),
                    const SizedBox(height: 16),
                    _buildEmailActionCard(context, isDark),
                    const SizedBox(height: 16),
                    _buildSupportScopeCard(isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      (isDark ? AppColors.accentCyan : const Color(0xFF0284C7))
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: isDark
                      ? AppColors.accentCyan
                      : const Color(0xFF0284C7),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBangla
                          ? 'গবেষণা ও প্রাতিষ্ঠানিক ঠিকানা'
                          : 'Office Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBangla ? 'সরাসরি দপ্তর' : 'Institutional Headquarters',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
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
                ? 'ইনস্টিটিউট অব এনার্জি রিসার্চ অ্যান্ড ডেভেলপমেন্ট (IERD)\nবাংলাদেশ বিজ্ঞান ও শিল্প গবেষণা পরিষদ (বিসিএসআইআর)\nড. কুদরত-এ-খুদা সড়ক, ধানমন্ডি, ঢাকা-১২০৫, বাংলাদেশ।'
                : 'Institute of Energy Research and Development (IERD)\nBangladesh Council of Scientific and Industrial Research (BCSIR)\nDr. Qudrat-i-Khuda Road, Dhanmondi, Dhaka-1205, Bangladesh.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailActionCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.energyGreen : const Color(0xFF16A34A))
              .withValues(alpha: 0.35),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.energyGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mail_rounded,
                  color: AppColors.energyGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBangla ? 'ইমেইল যোগাযোগ' : 'Direct Email Channel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBangla
                          ? 'যেকোনো জিজ্ঞাসা বা মতামতের জন্য'
                          : 'For any query or feedback',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _sendEmail(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color:
                    (isDark ? AppColors.energyGreen : const Color(0xFF16A34A))
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.energyGreen.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.alternate_email_rounded,
                    color: AppColors.energyGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'bashar@bcsir.gov.bd',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: AppColors.energyGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.energyGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isBangla ? 'মেইল করুন' : 'Send',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.send_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportScopeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: isDark ? AppColors.accentCyan : const Color(0xFF0284C7),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'সহায়তার ক্ষেত্রসমূহ' : 'Areas of Assistance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Divider(
            height: 20,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          _buildScopeBullet(
            isBangla
                ? 'সোলার হোম সিস্টেম (SHS) এবং অন-গ্রিড/হাইব্রিড সাইজিং সম্পর্কিত প্রশ্ন।'
                : 'Questions regarding Solar Home System (SHS) and On-Grid/Hybrid sizing calculations.',
            isDark,
          ),
          _buildScopeBullet(
            isBangla
                ? 'প্যানেল স্পেসিফিকেশন, ইনভার্টার অনুপাত এবং স্ট্রিং কনফিগারেশন যাচাই।'
                : 'Validation of PV module wattage, inverter DC/AC ratio, and string setup.',
            isDark,
          ),
          _buildScopeBullet(
            isBangla
                ? 'অ্যাপ্লিকেশনে প্রদর্শিত নাসা (NASA) সৌর বিকিরণ উপাত্ত সংক্রান্ত জিজ্ঞাসা।'
                : 'Queries on localized NASA solar radiation (PSH) and climate metrics.',
            isDark,
          ),
          _buildScopeBullet(
            isBangla
                ? 'সফটওয়্যারের ত্রুটি সংশোধন (Bug report) ও প্রযুক্তিগত উন্নয়ন পরামর্শ।'
                : 'Reporting app bugs, improvements, and collaborative research feedback.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildScopeBullet(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? AppColors.accentCyan : const Color(0xFF0284C7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
