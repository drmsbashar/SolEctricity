import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  final bool isBangla;

  const AboutScreen({super.key, required this.isBangla});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          isBangla ? 'পরিচিতি' : 'About',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ১. পরিচিতি হেডার ও প্রথম প্যারাগ্রাফ
                  _buildHeaderCard(),
                  const SizedBox(height: 16),

                  // ২. অ্যাপের বৈশিষ্ট্যসমূহ
                  _buildFeaturesCard(),
                  const SizedBox(height: 16),

                  // ৩. উদ্দেশ্য (বিসিএসআইআর)
                  _buildGoalCard(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ১. অ্যাপ পরিচিতি কার্ড
  Widget _buildHeaderCard() {
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
                  Icons.solar_power_rounded,
                  color: AppColors.primaryGreen,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBangla ? 'সূর্য বিদ্যুৎ' : 'Solectricity',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B6A3B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isBangla
                          ? 'আপনার সোলার-হোম-সিস্টেমের সহজ ও নির্ভরযোগ্য ডিজাইন সহযোগী'
                          : 'Your simple and reliable companion for designing a Solar Home System',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
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
                ? "'সূর্য বিদ্যুৎ' সোলার-হোম-সিস্টেম (SHS) ডিজাইন করার একটি স্মার্টফোন অ্যাপ। সোলার প্যানেল ও ব্যাটারির সংখ্যা এবং চার্জ কন্ট্রোলার ও ইনভার্টারের আকার এই অ্যাপে সহজেই হিসাব করা যায়। সৌরচালিত গৃহ-বিদ্যুৎ ব্যবস্থার পরিকল্পিত নকশা অ্যাপেই আছে। স্থানীয় বাজার থেকে কেনা উপকরণ জোড়া দেওয়ার বিস্তারিত নির্দেশনাও পাবেন।"
                : "Solectricity is a smartphone app for designing a Solar Home System (SHS). It calculates the number of solar panels and batteries, and the size of the charge controller and inverter. It includes a schematic design for a solar-powered home, along with detailed instructions for assembling components bought in the local market.",
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: Color(0xFF37474F),
            ),
          ),
        ],
      ),
    );
  }

  // ২. বৈশিষ্ট্য কার্ড
  Widget _buildFeaturesCard() {
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
              const Icon(Icons.star_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'অ্যাপের বৈশিষ্ট্য' : 'Key features',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildFeatureItem(
            icon: Icons.calculate_rounded,
            title: isBangla ? 'চার পদ্ধতিতে গণনা' : 'Four calculation methods',
            desc: isBangla
                ? 'লোড, জায়গা, খরচ ও ক্ষমতার ভিত্তিতে সিস্টেমের হিসাব করা যায়।'
                : 'design your system by load, land, cost or capacity.',
          ),
          _buildFeatureItem(
            icon: Icons.schema_rounded,
            title: isBangla ? '২৪টি আলাদা নকশা' : '24 schematic designs',
            desc: isBangla
                ? 'প্রয়োজন অনুযায়ী সঠিক নকশা বেছে নিন। সোলার প্যানেল, চার্জ কন্ট্রোলার, ব্যাটারি ও ইনভার্টারের সংযোগ ছবিতে দেখা যাবে।'
                : 'choose the design that fits your needs and see how the solar panel, charge controller, battery and inverter connect.',
          ),
          _buildFeatureItem(
            icon: Icons.build_rounded,
            title: isBangla
                ? 'কম্পাস, সমতলকারী ও চাঁদা'
                : 'Compass, leveler and protractor',
            desc: isBangla
                ? 'প্যানেল বসানোর জায়গায় সঠিক দিক ও কোণ নির্ধারণের জন্য।'
                : 'set the right direction and tilt when installing your panels.',
          ),
          _buildFeatureItem(
            icon: Icons.fact_check_rounded,
            title: isBangla ? 'হিসাব যাচাই' : 'Check any calculation',
            desc: isBangla
                ? 'অন্য কারও করা গণনাও এই অ্যাপে মিলিয়ে দেখা যায়।'
                : 'verify calculations from other sources against the app.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.teal.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF37474F),
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
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

  // ৩. উদ্দেশ্য কার্ড
  Widget _buildGoalCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300, width: 1.2),
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
              const Icon(
                Icons.flag_rounded,
                color: Color(0xFF1B6A3B),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'উদ্দেশ্য' : 'Our goal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B6A3B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isBangla
                ? 'বাংলাদেশ বিজ্ঞান ও শিল্প গবেষণা পরিষদ (বিসিএসআইআর) এই অ্যাপ তৈরি করেছে। সোলার-হোম-সিস্টেমের জটিল হিসাব সহজ করে সাধারণ মানুষের হাতে পৌঁছে দেওয়াই এর লক্ষ্য। বাজারের বাস্তব অবস্থা ও বাজেট বিবেচনা করে সাশ্রয়ী ও সঠিক ডিজাইন পেতে সহায়তা করাই অ্যাপটির মূল উদ্দেশ্য।'
                : 'Developed by the Bangladesh Council of Scientific and Industrial Research (BCSIR), Solectricity puts the complex calculations of SHS design into the hands of ordinary people. It aims to give every user an accurate design that balances budget with what is available in the local market.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
