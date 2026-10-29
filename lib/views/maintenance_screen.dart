import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class MaintenanceScreen extends StatelessWidget {
  final bool isBangla;

  const MaintenanceScreen({super.key, required this.isBangla});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          isBangla ? 'রক্ষণাবেক্ষণ নির্দেশিকা' : 'Maintenance Guide',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ১. নিরাপত্তার নিয়ম
              _buildSafetyCard(),
              const SizedBox(height: 16),

              // ২. সোলার প্যানেল
              _buildSectionCard(
                icon: Icons.solar_power_rounded,
                iconColor: Colors.orange,
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
              ),
              const SizedBox(height: 14),

              // ৩. চার্জ কন্ট্রোলার
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
              ),
              const SizedBox(height: 14),

              // ৪. ব্যাটারি
              _buildSectionCard(
                icon: Icons.battery_charging_full_rounded,
                iconColor: Colors.green,
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
              ),
              const SizedBox(height: 14),

              // ৫. তার ও লোড
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
              ),
              const SizedBox(height: 20),

              // ৬. সময়সূচি টেবিল
              _buildScheduleCard(),
              const SizedBox(height: 20),

              // ৭. ট্রাবলশুটিং টেবিল
              _buildTroubleshootingCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // নিরাপত্তার নিয়ম কার্ড
  Widget _buildSafetyCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.shade300, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
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
                ? 'ব্যাটারি বা তারে হাত দেওয়ার আগে সব বাতি ও যন্ত্র বন্ধ করুন।'
                : 'Switch off all lights and appliances before touching the battery or wires.',
          ),
          _bulletItem(
            isBangla
                ? 'ব্যাটারির দুই টার্মিনাল কখনো ধাতব জিনিস (চাবি, প্লায়ার্স, তার) দিয়ে একসঙ্গে ছুঁবেন না।'
                : 'Never touch both battery terminals together with any metal object (keys, pliers, wire).',
          ),
          _bulletItem(
            isBangla
                ? 'ব্যাটারির কাছে আগুন, দেশলাই, ধূমপান বা স্ফুলিঙ্গ নয়।'
                : 'No fire, matches, smoking or sparks near the battery.',
          ),
          _bulletItem(
            isBangla
                ? 'ব্যাটারির পানিতে অ্যাসিড থাকে। চোখে বা হাতে লাগলে সঙ্গে সঙ্গে প্রচুর পানি দিয়ে ধুয়ে ফেলুন।'
                : 'Battery liquid contains acid. If it touches your eyes or skin, wash immediately with plenty of water.',
          ),
          _bulletItem(
            isBangla
                ? 'ব্যাটারি শুকনো, ছায়াযুক্ত, বাতাস চলাচলের জায়গায় এবং শিশুদের নাগালের বাইরে রাখুন।'
                : 'Keep the battery in a dry, shaded, ventilated place, out of children’s reach.',
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
    required List<String> points,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          ...points.map((p) => _bulletItem(p)),
        ],
      ),
    );
  }

  // রক্ষণাবেক্ষণের সময়সূচি
  Widget _buildScheduleCard() {
    final List<Map<String, String>> schedule = isBangla
        ? [
            {
              'when': 'প্রতিদিন',
              'task': 'কন্ট্রোলারের বাতি দেখা; প্যানেলে ছায়া আছে কিনা দেখা',
            },
            {
              'when': 'প্রতি মাসে',
              'task': 'প্যানেল পরিষ্কার; প্যানেলের তার ও ব্যাটারির টার্মিনাল পরীক্ষা; ব্যাটারির উপরিভাগ মোছা; পানির স্তর দেখা (ফ্লাডেড ব্যাটারি)',
            },
            {
              'when': 'প্রতি বছর',
              'task': 'প্রযুক্তিবিদ দিয়ে পুরো সিস্টেম পরীক্ষা; নাট-বল্টু ও স্ট্যান্ড পরীক্ষা',
            },
            {
              'when': 'ঝড়/বন্যার আগে',
              'task':
                  'প্যানেল ও স্ট্যান্ড শক্ত আছে কিনা দেখা; সিস্টেম বন্ধ রাখা',
            },
            {
              'when': 'ঝড়/বন্যার পরে',
              'task': 'ক্ষতি, ভেজা সংযোগ ও ঢিলা তার দেখে তবেই চালু করা',
            },
          ]
        : [
            {
              'when': 'Daily',
              'task': 'Check controller lights; check for shade on the panel',
            },
            {
              'when': 'Monthly',
              'task': 'Clean panel; check panel wiring and battery terminals; wipe battery top; check water level (flooded batteries)',
            },
            {
              'when': 'Yearly',
              'task': 'Full system check by a technician; check nuts, bolts and stand',
            },
            {
              'when': 'Before storm/flood',
              'task':
                  'Make sure panel and stand are secure; switch the system off',
            },
            {
              'when': 'After storm/flood',
              'task': 'Check for damage, wet connections and loose wires before switching on',
            },
          ];

    return _buildCustomTableCard(
      title: isBangla ? 'রক্ষণাবেক্ষণের সময়সূচি' : 'Maintenance Schedule',
      icon: Icons.calendar_today_rounded,
      iconColor: Colors.teal,
      headerLeft: isBangla ? 'কখন' : 'When',
      headerRight: isBangla ? 'কাজ' : 'Tasks',
      data: schedule,
    );
  }

  // সমস্যা হলে করণীয় (ট্রাবলশুটিং)
  Widget _buildTroubleshootingCard() {
    final List<Map<String, String>> problems = isBangla
        ? [
            {
              'when': 'বাতি কম জ্বলে বা ব্যাটারি দ্রুত শেষ হয়',
              'task': 'প্যানেলের ময়লা ও ছায়া দেখুন; পানির স্তর দেখুন; অপ্রয়োজনীয় লোড কমান',
            },
            {
              'when': 'কন্ট্রোলারে লাল বা অস্বাভাবিক বাতি',
              'task': 'নিজে খুলবেন না; প্রযুক্তিবিদকে জানান',
            },
            {
              'when': 'ব্যাটারি ফুলে গেছে, গরম হচ্ছে বা পোড়া গন্ধ',
              'task': 'সিস্টেম বন্ধ করুন, ব্যাটারি থেকে দূরে থাকুন, সঙ্গে সঙ্গে প্রযুক্তিবিদকে ডাকুন',
            },
            {
              'when': 'কিছুই চলছে না',
              'task': 'তার ও ফিউজ দেখুন; ঠিক না হলে প্রযুক্তিবিদকে জানান',
            },
          ]
        : [
            {
              'when': 'Lights are dim or battery drains quickly',
              'task': 'Check panel for dirt & shade; check water level; reduce load',
            },
            {
              'when': 'Red or unusual light on controller',
              'task': 'Do not open it; call a technician',
            },
            {
              'when': 'Battery swollen, hot or burnt smell',
              'task': 'Switch off, stay away, call technician immediately',
            },
            {
              'when': 'Nothing works',
              'task':
                  'Check wires and fuse; if still not fixed, call a technician',
            },
          ];

    return _buildCustomTableCard(
      title: isBangla ? 'সমস্যা হলে কী করবেন' : 'Troubleshooting',
      icon: Icons.build_circle_rounded,
      iconColor: Colors.indigo,
      headerLeft: isBangla ? 'সমস্যা' : 'Problem',
      headerRight: isBangla ? 'করণীয়' : 'What to do',
      data: problems,
    );
  }

  Widget _buildCustomTableCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String headerLeft,
    required String headerRight,
    required List<Map<String, String>> data,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // হেডার
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          headerLeft,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1B6A3B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          headerRight,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1B6A3B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // ডেটা তালিকা
                ...data.map((row) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            row['when'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF263238),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            row['task'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF37474F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
