import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class LicenseScreen extends StatelessWidget {
  final bool isBangla;

  const LicenseScreen({super.key, required this.isBangla});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          isBangla ? 'অনুমোদন ও গোপনীয়তা নীতি' : 'License & Privacy Policy',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIntroCard(),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    icon: Icons.storage_rounded,
                    iconColor: Colors.blueAccent,
                    title: isBangla
                        ? 'তথ্য সংগ্রহ ও ব্যবহার'
                        : 'Information Collection and Use',
                    content: isBangla
                        ? 'সেবা উন্নত করতে অ্যাপ কিছু তথ্য চাইতে পারে। সিস্টেম ডিজাইনের জন্য আপনি যে তথ্য দেবেন, তা শুধু আপনার ডিভাইসেই থাকবে। আমরা তা সংগ্রহ করি না। আপনার ব্যক্তিগত তথ্য ব্যবহার করে, এমন কোনো তৃতীয় পক্ষের সেবা এই অ্যাপে নেই।'
                        : 'To improve your experience, the app may ask for certain information. The information you enter for system design stays on your device only, and we do not collect it. The app does not use any third-party service to collect your personal information.',
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    icon: Icons.history_rounded,
                    iconColor: Colors.orange,
                    title: isBangla ? 'লগ ডেটা' : 'Log Data',
                    content: isBangla
                        ? 'অ্যাপ ব্যবহারে কোনো ত্রুটি বা সমস্যা হলে আমরা লগ ডেটা হিসেবে কিছু প্রযুক্তিগত তথ্য সংগ্রহ করতে পারি। এতে থাকতে পারে ডিভাইসের আইপি (IP) ঠিকানা, ডিভাইসের নাম, অপারেটিং সিস্টেমের সংস্করণ, অ্যাপের কনফিগারেশন, ব্যবহারের তারিখ ও সময় এবং অন্যান্য পরিসংখ্যান।'
                        : 'If an error occurs while you use the app, we may collect technical information as Log Data. This may include your device’s Internet Protocol (IP) address, device name, operating system version, app configuration, the date and time of use, and other statistics.',
                  ),
                  const SizedBox(height: 14),
                  _buildServiceProvidersCard(),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    icon: Icons.security_rounded,
                    iconColor: Colors.teal,
                    title: isBangla ? 'নিরাপত্তা' : 'Security',
                    content: isBangla
                        ? 'আপনি আমাদের ওপর আস্থা রেখেছেন, এজন্য ধন্যবাদ। তবে ইন্টারনেটে তথ্য আদান-প্রদান বা ইলেকট্রনিক সংরক্ষণের কোনো পদ্ধতিই শতভাগ নিরাপদ নয়। তাই আমরা তথ্যের পূর্ণ নিরাপত্তার নিশ্চয়তা দিতে পারি না।'
                        : 'We value the trust you place in us. However, no method of transmission over the internet or electronic storage is 100% secure, so we cannot guarantee absolute security.',
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    icon: Icons.child_care_rounded,
                    iconColor: Colors.indigo,
                    title: isBangla
                        ? 'শিশুদের গোপনীয়তা'
                        : 'Children’s Privacy',
                    content: isBangla
                        ? 'এই অ্যাপ কোনো বয়সের ব্যবহারকারীর নাম, বয়স, যোগাযোগ তালিকা বা ছবির মতো ব্যক্তিগত তথ্য সংগ্রহ করে না। কারও ব্যক্তিগত তথ্য সংগ্রহ হয়েছে বলে মনে হলে অনুগ্রহ করে bashar@bcsir.gov.bd ঠিকানায় জানান।'
                        : 'This app does not collect personal information such as name, age, contact list or photos from users of any age. If you believe any personal information has been collected, please contact us at bashar@bcsir.gov.bd.',
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    icon: Icons.update_rounded,
                    iconColor: Colors.deepPurple,
                    title: isBangla
                        ? 'নীতির পরিবর্তন'
                        : 'Changes to This Policy',
                    content: isBangla
                        ? 'বিসিএসআইআর যেকোনো সময় এই নীতি পরিবর্তন করতে পারে। পরিবর্তন হলে এই পাতার শীর্ষে হালনাগাদের তারিখ জানানো হবে। আমরা অনুরোধ করছি, আপনি মাঝে মাঝে নীতিটি দেখে নেবেন। ধরে নেওয়া হবে, ব্যবহারকারী নিয়মিত নীতি পড়বেন এবং পরিবর্তন সম্পর্কে অবগত থাকবেন।'
                        : 'BCSIR may update this policy at any time. When it does, the updated date at the top of this page will change. We encourage you to review the policy from time to time. Users are expected to read it regularly and stay aware of any changes.',
                  ),
                  const SizedBox(height: 14),
                  _buildDisclaimerCard(),
                  const SizedBox(height: 14),
                  _buildRestrictionsCard(),
                  const SizedBox(height: 14),
                  _buildContactCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // পরিচিতি ও শিরোনাম কার্ড
  Widget _buildIntroCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.policy_rounded,
                  color: AppColors.primaryGreen,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBangla
                          ? 'গোপনীয়তা নীতি ও অনুমোদন'
                          : 'Privacy Policy & License',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B6A3B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBangla
                          ? 'সবার জন্য উন্মুক্ত ও অবাণিজ্যিক'
                          : 'Free and Open Source',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            isBangla
                ? 'বাংলাদেশ বিজ্ঞান ও শিল্প গবেষণা পরিষদ (বিসিএসআইআর) সোলার-হোম-সিস্টেম ডিজাইনের জন্য Solectricity (সূর্য বিদ্যুৎ) অ্যাপ তৈরি করেছে। অ্যাপটি বিনা মূল্যে সবার জন্য উন্মুক্ত।\n\nএই নীতিতে বলা হয়েছে, অ্যাপ ব্যবহারের সময় আমরা ব্যবহারকারীর তথ্য কীভাবে সংগ্রহ, ব্যবহার ও প্রকাশ করি। অ্যাপটি ডাউনলোড, ইনস্টল বা ব্যবহার করলে ধরে নেওয়া হবে যে আপনি এই নীতি পড়েছেন, বুঝেছেন এবং এর শর্তাবলী মেনে নিয়েছেন। এই নীতিতে উল্লেখ করা ক্ষেত্র ছাড়া আপনার তথ্য অন্য কারও সঙ্গে ব্যবহার বা শেয়ার করা হবে না।'
                : 'The Bangladesh Council of Scientific and Industrial Research (BCSIR) has developed Solectricity (সূর্য বিদ্যুৎ), a smartphone app for designing Solar Home Systems. The app is free and open to everyone.\n\nThis policy explains how we collect, use and disclose information when you use the app. By downloading, installing or using the app, you confirm that you have read and understood this policy and agree to its terms. We will not use or share your information with anyone except as described here.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF37474F),
            ),
          ),
        ],
      ),
    );
  }

  // সাধারণ সেকশন কার্ড
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF37474F),
            ),
          ),
        ],
      ),
    );
  }

  // সেবা প্রদানকারী কার্ড
  Widget _buildServiceProvidersCard() {
    final points = isBangla
        ? [
            'সেবা উন্নত করতে;',
            'সেবা-সংক্রান্ত কাজ সম্পাদন করতে;',
            'সেবা কীভাবে ব্যবহৃত হচ্ছে, তা বিশ্লেষণ করতে।',
          ]
        : [
            'improve our service;',
            'carry out service-related tasks;',
            'help us analyze how the service is used.',
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_alt_rounded,
                color: Colors.teal,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'সেবা প্রদানকারী' : 'Service Providers',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Text(
            isBangla
                ? 'নিচের কারণে আমরা তৃতীয় পক্ষের প্রতিষ্ঠান বা ব্যক্তির সহায়তা নিতে পারি:'
                : 'We may engage third-party companies or individuals to:',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 8),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isBangla
                ? 'এসব তৃতীয় পক্ষ ব্যবহারকারীর তথ্য গোপন রাখতে এবং অন্য কোনো উদ্দেশ্যে ব্যবহার না করতে বাধ্য থাকবে।'
                : 'These third parties must keep your information confidential and must not use it for any other purpose.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF37474F),
            ),
          ),
        ],
      ),
    );
  }

  // দায়মুক্তি কার্ড
  Widget _buildDisclaimerCard() {
    final points = isBangla
        ? [
            'অ্যাপ ব্যবহার বা ব্যবহারে অক্ষমতার কারণে কোনো ক্ষতি হলে বিসিএসআইআর দায়ী থাকবে না।',
            'অ্যাপের তথ্য, লেখা, ছবি, লিঙ্ক বা অন্য উপাদানের নির্ভুলতা ও সম্পূর্ণতার নিশ্চয়তা বিসিএসআইআর দেয় না।',
            'বিসিএসআইআর যেকোনো সময় নোটিশ ছাড়াই অ্যাপ বা এর উপাদান পরিবর্তন করতে পারে। অ্যাপ হালনাগাদ করার কোনো প্রতিশ্রুতিও দেয় না।',
            'অ্যাপটি আপনার সব প্রয়োজন মেটাবে, বা এটি নিরবচ্ছিন্ন ও ত্রুটিমুক্ত থাকবে, এমন নিশ্চয়তা বিসিএসআইআর দেয় না।',
          ]
        : [
            'BCSIR is not liable for any damage arising from the use of, or inability to use, the app.',
            'BCSIR does not warrant the accuracy or completeness of the app’s information, text, graphics, links or other content.',
            'BCSIR may change the app or its contents at any time without notice, and does not commit to updating it.',
            'BCSIR does not warrant that the app will meet your requirements, or that it will run without interruption or errors.',
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, color: Colors.blueGrey, size: 22),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'দায়মুক্তি' : 'Disclaimer',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF37474F),
                      ),
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

  // বিধিনিষেধ কার্ড
  Widget _buildRestrictionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade300, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.block_rounded,
                color: Colors.deepOrange,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'বিধিনিষেধ' : 'Restrictions',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Text(
            isBangla
                ? 'ব্যবহারকারী অ্যাপ বা এর কোনো অংশ অনুলিপি, পরিবর্তন, বিতরণ, বিক্রয়, সাব-লাইসেন্স বা স্থানান্তর করতে পারবেন না। রিভার্স ইঞ্জিনিয়ারিংও করতে পারবেন না। অ্যাপের কোনো কপিরাইট, ট্রেডমার্ক বা মালিকানা-সংক্রান্ত নোটিশ সরানো বা বদলানো যাবে না। অ্যাপ কোনো বেআইনি বা অননুমোদিত কাজে ব্যবহার করা যাবে না।'
                : 'You must not copy, modify, distribute, sell, sublicense, transfer or reverse engineer the app or any part of it. You must not remove or alter any copyright, trademark or other proprietary notices. You must not use the app for any illegal or unauthorized purpose.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF4E342E),
            ),
          ),
        ],
      ),
    );
  }

  // যোগাযোগ কার্ড
  Widget _buildContactCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.email_outlined, color: Color(0xFF1B6A3B), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBangla ? 'যোগাযোগ' : 'Contact Us',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B6A3B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBangla
                      ? 'এই নীতি নিয়ে কোনো প্রশ্ন বা পরামর্শ থাকলে নির্দ্বিধায় ইমেইল করুন: bashar@bcsir.gov.bd'
                      : 'If you have any questions or suggestions about this policy, please contact us at bashar@bcsir.gov.bd.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
