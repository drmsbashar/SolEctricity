import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/theme_toggle_button.dart';

class MaintenanceScreen extends StatelessWidget {
  final bool isBangla;

  const MaintenanceScreen({super.key, required this.isBangla});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBangla ? 'রক্ষণাবেক্ষণ নির্দেশিকা' : 'Maintenance Guide'),
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
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 650),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSafetyCard(isDark),
                const SizedBox(height: 16),
                _buildSectionCard(
                  icon: Icons.solar_power_rounded,
                  iconColor: AppColors.solarGold,
                  title: isBangla ? 'সোলার প্যানেল' : 'Solar Panel',
                  points: isBangla
                      ? [
                          'মাসে একবার পরিষ্কার করুন। সকালে বা বিকেলে, যখন প্যানেল ঠান্ডা, পানি ও নরম ব্রাশ বা কাপড় দিয়ে। সাবান বা শক্ত জিনিস দিয়ে ঘষবেন না।',
                          'বর্ষায় বৃষ্টিই বেশিরভাগ ময়লা ধুয়ে দেয়। তবে পাখির বিষ্ঠা বা জমে থাকা ময়লা দেখলে পরিষ্কার করুন।',
                          'প্যানেলের ওপর উঠবেন না বা দাঁড়াবেন না।',
                          'প্যানেলের ওপর গাছের ডাল বা অন্য কিছুর ছায়া পড়ছে কিনা দেখুন। সামান্য ছায়াও বিদ্যুৎ অনেক কমিয়ে দেয়।',
                          'প্যানেলের পেছনের তারের সংযোগ ঠিক আছে কিনা মাসে একবার দেখুন।',
                          'ফ্রেম ও স্ট্যান্ডের নাট-বল্টু ঢিলা কিনা দেখুন, বিশেষ করে ঝড়ের আগে ও পরে। উপকূলীয় এলাকায় মরিচা পড়ছে কিনা দেখুন।',
                        ]
                      : [
                          'Clean once a month with water and a soft brush or cloth, in the morning or evening when the panel is cool. Do not use soap or abrasive materials.',
                          'In the rainy season, rain removes most dust. Still, clean off bird droppings or caked dirt when you see them.',
                          'Never climb or stand on the panel.',
                          'Check whether shade from tree branches or new structures falls on the panel. Even a small shadow can sharply reduce power.',
                          'Check the wire connections at the back of the panel once a month.',
                          'Check the frame and stand for loose nuts and bolts, especially before and after storms. In coastal areas, look for salt corrosion.',
                        ],
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  icon: Icons.developer_board_rounded,
                  iconColor: Colors.blueAccent,
                  title: isBangla ? 'চার্জ কন্ট্রোলার' : 'Charge Controller',
                  points: isBangla
                      ? [
                          'কন্ট্রোলারের চারপাশ সবসময় শুকনো রাখুন।',
                          'বর্ষায় তার বেয়ে বৃষ্টির পানি যেন ঘরে না ঢোকে, তা নিশ্চিত করুন।',
                          'প্রতিদিন সূচক বাতি (LED) দেখুন। কোন বাতির কী অর্থ, তা প্রযুক্তিবিদের কাছ থেকে জেনে নিন।',
                          'পিপড়া, টিকটিকি ও পোকামাকড় যেন ভেতরে না ঢোকে, খেয়াল রাখুন।',
                          'নিজে সেটিং বদলাবেন না বা যন্ত্র খুলবেন না।',
                        ]
                      : [
                          'Keep the surroundings of the controller dry at all times.',
                          'In the rainy season, make sure rainwater cannot enter the house along the wires.',
                          'Check the indicator lights (LEDs) daily. Ask your technician what each light means.',
                          'Keep ants, lizards and insects out of the unit.',
                          'Do not change settings or open the unit yourself.',
                        ],
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: AppColors.energyGreen,
                  title: isBangla ? 'ব্যাটারি' : 'Battery',
                  points: isBangla
                      ? [
                          'মাসে একবার শুকনো কাপড় দিয়ে ব্যাটারির উপরের অংশ মুছুন।',
                          'তার যেখানে লাগানো আছে, সেই জায়গা শুকনো নরম ব্রাশ দিয়ে পরিষ্কার করুন। সবুজ-সাদা ক্ষয় (জং) জমলে পরিষ্কার করে সামান্য গ্রিজ বা ভ্যাসলিন লাগান।',
                          'শুধু পানি দেওয়ার উপযোগী (ফ্লাডেড) ব্যাটারির জন্য: নিয়মিত দেখুন পানি সর্বনিম্ন ও সর্বোচ্চ দাগের মাঝে আছে কিনা।',
                          'পানি কমে গেলে শুধু "ব্যাটারির পানি" (ডিস্টিলড ওয়াটার) দিয়ে সর্বোচ্চ দাগ পর্যন্ত ভরুন। উপচে ফেলবেন না। অন্য কোনো পানি ব্যবহার করবেন না। এটি বাজারে কিনতে পাওয়া যায়।',
                          'সিল্ড (জেল/AGM) বা লিথিয়াম ব্যাটারিতে পানি দেওয়া যায় না। সেগুলো খুলবেন না।',
                          'ব্যাটারি একেবারে শেষ হতে দেবেন না। চার্জ কমে এলে অপ্রয়োজনীয় বাতি ও যন্ত্র বন্ধ রাখুন। এতে ব্যাটারি বেশিদিন টেকে।',
                        ]
                      : [
                          'Wipe the top of the battery with a dry cloth once a month.',
                          'Clean the wire contact points with a dry, soft brush. If green-white corrosion has formed, clean it off and apply a little grease or petroleum jelly.',
                          'For flooded (refillable) batteries only: regularly check that the water level is between the minimum and maximum marks.',
                          'If the level is low, refill only with distilled water (“battery water”) up to the maximum mark. Do not overfill. Never use any other water. Distilled water is available in the local market.',
                          'Sealed (gel/AGM) and lithium batteries cannot be refilled. Do not open them.',
                          'Do not let the battery run completely empty. When the charge is low, switch off unnecessary lights and appliances. This greatly extends battery life.',
                        ],
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  icon: Icons.cable_rounded,
                  iconColor: Colors.deepPurpleAccent,
                  title: isBangla ? 'তার ও লোড' : 'Wires and Loads',
                  points: isBangla
                      ? [
                          'তারের গায়ের আবরণ ফেটে গেছে বা ইঁদুরে কেটেছে কিনা দেখুন। খোলা বা ঢিলা সংযোগ থাকলে ঠিক করান।',
                          'নির্ধারিত ক্ষমতার বেশি যন্ত্র চালাবেন না। ফিউজ নিজে বদলাবেন না।',
                        ]
                      : [
                          'Check for cracked insulation or rodent damage. Have any exposed or loose connection repaired.',
                          'Do not run appliances beyond the rated capacity, and do not replace fuses yourself.',
                        ],
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _buildScheduleCard(isDark),
                const SizedBox(height: 20),
                _buildTroubleshootingCard(isDark),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.alertRed.withValues(alpha: 0.12)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.alertRed.withValues(alpha: 0.4)
              : Colors.deepOrange.shade300,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.deepOrange,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla
                    ? 'নিরাপত্তার নিয়ম (সবার আগে পড়ুন)'
                    : 'Safety Rules (Read First)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bulletItem(
            isBangla
                ? '১। ব্যাটারি বা তারে হাত দেওয়ার আগে সব বাতি ও যন্ত্র বন্ধ করুন।'
                : '1. Switch off all lights and appliances before touching the battery or wires.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '২। ব্যাটারির দুই টার্মিনাল কখনো ধাতব জিনিস দিয়ে একসঙ্গে ছুঁবেন না।'
                : '2. Never touch both battery terminals together with any metal object.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৩। ব্যাটারির কাছে আগুন, দেশলাই, ধূমপান বা স্ফুলিঙ্গ নয়।'
                : '3. No fire, matches, smoking or sparks near the battery.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৪। ব্যাটারির তরল চোখে বা হাতে লাগলে প্রচুর পানি দিয়ে ধুয়ে ফেলুন।'
                : '4. Battery liquid contains acid. Wash immediately with water if exposed.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৫। ব্যাটারি শুকনো, ছায়াযুক্ত ও শিশুদের নাগালের বাইরে রাখুন।'
                : '5. Keep the battery in a dry, ventilated place out of children\'s reach.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> points,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
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
            height: 18,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          ...points.map((p) => _bulletItem(p, isDark)),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Colors.teal,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'রক্ষণাবেক্ষণের সময়সূচি' : 'Maintenance Schedule',
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
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildTableHeader(
                  left: isBangla ? 'কখন' : 'When',
                  right: isBangla ? 'কাজ' : 'Tasks',
                  isDark: isDark,
                ),
                _buildTableRow(
                  when: isBangla ? 'প্রতিদিন' : 'Daily',
                  task: isBangla
                      ? 'কন্ট্রোলারের বাতি দেখা; প্যানেলে ছায়া আছে কিনা দেখা'
                      : 'Check controller lights; check for shade on the panel',
                  isDark: isDark,
                ),
                _buildTableRow(
                  when: isBangla ? 'প্রতি মাসে' : 'Monthly',
                  task: isBangla
                      ? 'প্যানেল পরিষ্কার; তার ও টার্মিনাল পরীক্ষা; পানির স্তর দেখা'
                      : 'Clean panel; check terminals; check water level',
                  isDark: isDark,
                ),
                _buildTableRow(
                  when: isBangla ? 'প্রতি বছর' : 'Yearly',
                  task: isBangla
                      ? 'প্রযুক্তিবিদ দিয়ে পুরো সিস্টেম ও নাট-বল্টু পরীক্ষা'
                      : 'Full system check by a technician',
                  isDark: isDark,
                ),
                _buildTableRow(
                  when: isBangla ? 'ঝড়ের আগে' : 'Before storm',
                  task: isBangla
                      ? 'প্যানেল ও স্ট্যান্ড শক্ত আছে কিনা দেখে সিস্টেম বন্ধ রাখা'
                      : 'Ensure stand is secure; switch off the system',
                  isDark: isDark,
                ),
                _buildTableRow(
                  when: isBangla ? 'ঝড়ের পরে' : 'After storm',
                  task: isBangla
                      ? 'ক্ষতি ও ঢিলা তার দেখে তবেই চালু করা'
                      : 'Check for damage and loose wires before switching on',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_circle_rounded, color: Colors.indigo, size: 24),
              SizedBox(width: 8),
              Text(
                'সমস্যা হলে কী করবেন',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildTableHeader(
                  left: isBangla ? 'সমস্যা' : 'Problem',
                  right: isBangla ? 'করণীয়' : 'What to do',
                  isDark: isDark,
                ),
                _buildTableRow(
                  when: isBangla
                      ? 'বাতি কম জ্বলে বা চার্জ দ্রুত শেষ হয়'
                      : 'Lights dim or battery drains quickly',
                  task: isBangla
                      ? 'প্যানেলে ময়লা/ছায়া দেখুন; অপ্রয়োজনীয় লোড কমান'
                      : 'Check panel for dirt & shade; reduce unnecessary loads',
                  isDark: isDark,
                ),
                _buildTableRow(
                  when: isBangla
                      ? 'কন্ট্রোলারে অস্বাভাবিক বাতি'
                      : 'Unusual light on controller',
                  task: isBangla
                      ? 'নিজে না খুলে প্রযুক্তিবিদকে জানান'
                      : 'Do not open it; call a technician',
                  isDark: isDark,
                ),
                _buildTableRow(
                  when: isBangla
                      ? 'ব্যাটারি গরম হচ্ছে বা গন্ধ বের হচ্ছে'
                      : 'Battery hot or bad smell',
                  task: isBangla
                      ? 'সিস্টেম বন্ধ করে ব্যাটারি থেকে দূরে থাকুন, টেকনিশিয়ান ডাকুন'
                      : 'Switch off, stay away, call technician immediately',
                  isDark: isDark,
                ),
                _buildTableRow(
                  when: isBangla ? 'কিছুই চলছে না' : 'Nothing works',
                  task: isBangla
                      ? 'তার ও ফিউজ দেখুন; সমাধান না হলে টেকনিশিয়ান ডাকুন'
                      : 'Check wires and fuse; call a technician if unresolved',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader({
    required String left,
    required String right,
    required bool isDark,
  }) {
    return Container(
      color: isDark ? AppColors.darkInputBg : Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              left,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? AppColors.energyGreen : const Color(0xFF1B6A3B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? AppColors.energyGreen : const Color(0xFF1B6A3B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow({
    required String when,
    required String task,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              when,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : const Color(0xFF263238),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark ? AppColors.darkTextSecondary : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.accentCyan : Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : const Color(0xFF37474F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
