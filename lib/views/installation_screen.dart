import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../widgets/theme_toggle_button.dart';

class InstallationScreen extends StatefulWidget {
  final bool isBangla;

  const InstallationScreen({super.key, required this.isBangla});

  @override
  State<InstallationScreen> createState() => _InstallationScreenState();
}

class _InstallationScreenState extends State<InstallationScreen> {
  late List<bool> _checklistValues;

  @override
  void initState() {
    super.initState();
    _checklistValues = List.filled(8, false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isBangla = widget.isBangla;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBangla
              ? 'সোলার হোম সিস্টেম স্থাপন নির্দেশিকা'
              : 'Solar Home System Installation Guide',
        ),
        actions: [
          // ☀️/🌙 স্ট্যান্ডার্ডাইজড থিম টগল বাটন
          ThemeToggleButton(isBangla: isBangla),
        ],
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
                _buildSafetyCard(isBangla, isDark),
                const SizedBox(height: 12),

                _buildImageCard(
                  imagePath: AppAssets.installFig1,
                  caption: isBangla
                      ? 'চিত্র ১: নিরাপত্তার মূল নিষেধ'
                      : 'Figure 1: Key safety prohibitions',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                _buildPanelSection(isBangla, isDark),
                const SizedBox(height: 16),

                _buildSectionCard(
                  icon: Icons.developer_board_rounded,
                  iconColor: Colors.blueAccent,
                  title: isBangla
                      ? 'চার্জ কন্ট্রোলার / ইনভার্টার স্থাপন'
                      : 'Installing Charge Controller / Inverter',
                  points: isBangla
                      ? [
                          '১। ঘরের ভেতর শুকনো, ঠান্ডা ও বাতাস চলাচলের জায়গায় রাখুন। সরাসরি রোদ ও গরম জায়গা এড়িয়ে চলুন।',
                          '২। ইনভার্টারের চারপাশে ফাঁকা জায়গা রাখুন। কিছু দিয়ে ঢেকে দেবেন না।',
                          '৩। শিশুদের নাগালের বাইরে রাখুন।',
                          '৪। "প্রকল্প ডিজাইন" নক্সা অনুযায়ী (+) চিহ্নিত টার্মিনালে লাল তার ও (–) চিহ্নিত টার্মিনালে কালো/নীল তার লাগান।',
                          '৫। ইনভার্টার থেকে বৈদ্যুতিক যন্ত্রে সংযোগের সময় L/P চিহ্নিত টার্মিনালে লাল তার ও N চিহ্নিত টার্মিনালে কালো/নীল তার লাগান।',
                          '৬। ব্যাটারির ভোল্টেজ (১২ বা ২৪ ভোল্ট), কন্ট্রোলার ও ইনভার্টারের ভোল্টেজ মিলিয়ে নিন। না মিললে সংযোগ দেবেন না।',
                        ]
                      : [
                          '1. Place them indoors in a dry, cool and ventilated place, away from direct sunlight and heat.',
                          '2. Leave free space around the inverter. Do not cover it.',
                          '3. Keep them out of children\'s reach.',
                          '4. As in the "Project Design" drawing, connect the red wire to the terminals marked (+) and the black/blue wire to the terminals marked (–).',
                          '5. For the wiring from the inverter to the appliances, connect the red wire to the terminal marked L/P and the black/blue wire to the terminal marked N.',
                          '6. Check that the battery voltage (12 V or 24 V) matches the controller and inverter ratings. If it does not match, do not connect.',
                        ],
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                _buildSectionCard(
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: AppColors.energyGreen,
                  title: isBangla
                      ? 'ব্যাটারি স্থাপন'
                      : 'Installing the Battery',
                  points: isBangla
                      ? [
                          '১। ঘরের ভেতর শুকনো, ঠান্ডা ও বাতাস চলাচলের জায়গায় রাখুন। ভেজা মেঝেতে সরাসরি না রেখে কাঠ বা প্লাস্টিকের পাটাতনের ওপর রাখুন।',
                          '২। পানি দেওয়ার উপযোগী (ফ্লাডেড) ব্যাটারি শোবার ঘরে রাখবেন না। শিশুদের নাগালের বাইরে রাখুন।',
                          '৩। ব্যাটারি কন্ট্রোলার বা ইনভার্টারের কাছে রাখুন, যাতে অল্প দৈর্ঘ্যের তার দিয়ে সংযোগ দেওয়া যায়।',
                          '৪। "প্রকল্প ডিজাইন" নক্সা অনুযায়ী ব্যাটারির (+) টার্মিনালে লাল তার ও (–) টার্মিনালে কালো/নীল তার লাগান।',
                          '৫। সিরিজ সংযোগে ছবির নিয়ম মেনে তার লাগান। একই ধরন, ক্ষমতা ও বয়সের ব্যাটারি ব্যবহার করুন। পুরনো ও নতুন ব্যাটারি মেশাবেন না।',
                          '৬। ব্যাটারি ও কন্ট্রোলারের মাঝে (+) তারে ফিউজ বা সার্কিট ব্রেকার লাগান।',
                        ]
                      : [
                          '1. Place it indoors in a dry, cool and ventilated place. Put it on a wooden or plastic platform rather than directly on a damp floor.',
                          '2. Do not keep a flooded (refillable) battery in a bedroom. Keep it out of children\'s reach.',
                          '3. Keep the battery close to the charge controller or inverter, so that a short wire can connect them.',
                          '4. As in the "Project Design" drawing, connect the red wire to the battery\'s (+) terminal and the black/blue wire to the (–) terminal.',
                          '5. For a series connection, connect the wires as shown in the picture. Use batteries of the same type, capacity and age. Do not mix old and new batteries.',
                          '6. Install a fuse or circuit breaker on the (+) wire between the battery and the controller.',
                        ],
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                _buildSectionCard(
                  icon: Icons.cable_rounded,
                  iconColor: Colors.deepPurpleAccent,
                  title: isBangla
                      ? 'তার, সুরক্ষা ও আর্থিং'
                      : 'Wiring, Protection and Earthing',
                  points: isBangla
                      ? [
                          '১। সিস্টেমের ক্ষমতার উপযোগী পুরু তার ব্যবহার করুন। খোলা জায়গার তার রোদ-সহনশীল হতে হবে এবং পাইপ বা নালার ভেতর দিয়ে নিতে হবে।',
                          '২। সব সংযোগ শক্ত করে লাগান। কোনো টার্মিনাল বা তারের খোলা অংশ যেন বাইরে না থাকে।',
                          '৩। বজ্রপাত ও বিদ্যুৎ-ঝুঁকি কমাতে প্যানেলের ফ্রেম ও স্ট্যান্ডে আর্থিং (মাটির সঙ্গে সংযোগ) দিন। এ কাজ প্রশিক্ষিত প্রযুক্তিবিদ দিয়ে করানো ভালো।',
                        ]
                      : [
                          '1. Use thick wire suitable for the system\'s capacity. Wire in open areas must be sunlight-resistant and run inside a pipe or conduit.',
                          '2. Make all connections tight. No bare wire or terminal should be left exposed.',
                          '3. To reduce lightning and electrical hazards, earth (ground) the panel frame and stand. It is best to have a trained technician do this.',
                        ],
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                _buildImageCard(
                  imagePath: AppAssets.installFig5,
                  caption: isBangla
                      ? 'চিত্র ৫: সংযোগের ক্রম — ১. ব্যাটারি, ২. প্যানেল, ৩. লোড'
                      : 'Figure 5: Connection order — 1. battery, 2. panel, 3. loads',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),

                _buildOrderTableCard(isBangla, isDark),
                const SizedBox(height: 20),

                _buildChecklistCard(isBangla, isDark),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyCard(bool isBangla, bool isDark) {
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
                ? '১। বৃষ্টি, ভেজা আবহাওয়া বা ঝড়ের সময় ছাদে কাজ করবেন না। সম্ভব হলে দুজন মিলে কাজ করুন।'
                : '1. Do not work on the roof in rain, wet weather or storms. If possible, work in pairs.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '২। আলো পড়লে প্যানেল থেকে বিদ্যুৎ তৈরি হয়। তাই তার লাগানোর সময় প্যানেল অন্ধকার কাপড় বা কার্টন দিয়ে ঢেকে রাখুন, অথবা সকালে বা সন্ধ্যায় কাজ করুন।'
                : '2. A panel produces electricity whenever light falls on it. Cover the panel with a dark cloth or cardboard while connecting wires, or work in the early morning or evening.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৩। ব্যাটারির দুই টার্মিনাল কখনো ধাতব জিনিস (চাবি, প্লায়ার্স, তার) দিয়ে একসঙ্গে ছুঁবেন না। কাজের সময় আংটি ও ঘড়ি খুলে রাখুন এবং ইনসুলেশন দেওয়া যন্ত্র ব্যবহার করুন।'
                : '3. Never touch both battery terminals together with any metal object (keys, pliers, wire). Remove rings and watches, and use insulated tools.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৪। ব্যাটারির কাছে আগুন, ধূমপান বা স্ফুলিঙ্গ নয়।'
                : '4. No fire, smoking or sparks near the battery.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৫। লাল তার (+) ও কালো/নীল তার (–) ভুল জায়গায় লাগালে কন্ট্রোলার বা ইনভার্টার নষ্ট হতে পারে। লাগানোর আগে প্রতিবার চিহ্ন মিলিয়ে নিন।'
                : '5. Connecting red (+) and black/blue (–) wires the wrong way can damage the controller or inverter. Check the markings every time before connecting.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৬। কাজ শেষ না হওয়া পর্যন্ত সব সুইচ বন্ধ এবং ফিউজ খোলা রাখুন।'
                : '6. Keep all switches off and fuses removed until the work is finished.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPanelSection(bool isBangla, bool isDark) {
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
                Icons.solar_power_rounded,
                color: AppColors.solarGold,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                isBangla
                    ? 'সোলার প্যানেল স্থাপন'
                    : 'Installing the Solar Panel',
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
          _bulletItem(
            isBangla
                ? '১। জায়গা: সাধারণত বাড়ির ছাদে বা টিনের চালার ওপর প্যানেল বসানো হয়। ছাদ বা চালায় ছায়া পড়লে ঘরের কাছে খোলা জায়গায় শক্ত খুঁটি বা স্ট্যান্ডের ওপর উঁচুতে বসান। গাছ বা দালানের ছায়া যেন সকাল ৮টা থেকে বিকাল ৪টা পর্যন্ত প্যানেলে না পড়ে।'
                : '1. Location: Panels are usually mounted on the rooftop or tin roof of a house. If the roof is shaded, mount the panel in an open area near the house, high on a sturdy pole or stand. Make sure no shade from trees or buildings falls on the panel between 8 am and 4 pm.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '২। দিক: প্যানেল দক্ষিণমুখী করে বসান, যাতে সকাল ৮টা থেকে বিকাল ৪টা পর্যন্ত, অর্থাৎ অন্তত ৮ ঘণ্টা সূর্যের আলো পাওয়া যায়।'
                : '2. Direction: Face the panels south so they receive direct sunlight for at least eight hours, from 8 am to 4 pm.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৩। দক্ষিণ দিক বের করা: Solectricity অ্যাপের "টুল" অংশে কম্পাস আছে, তা দিয়ে ঠিক দক্ষিণ দিক বের করুন। কম্পাস দেখার সময় ফোন লোহা বা ধাতব জিনিস থেকে দূরে রাখুন।'
                : '3. Finding south: Use the compass in the "Tools" tab of the Solectricity app to find due south. Keep the phone away from iron and metal objects while using it.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৪। কোণ: সর্বোচ্চ বিদ্যুৎ পেতে প্যানেল ভূমির সঙ্গে প্রায় ২৫ ডিগ্রি কোণে বসান।'
                : '4. Tilt: For maximum power, tilt the south-facing panel at about 25 degrees to the ground.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৫। কোণ মাপা: ২৫ ডিগ্রি কোণ বা চালার কোণ মাপতে অ্যাপের "টুল" অংশের সমতলকারী (লেভেলার) ও কোণমাপক (চাঁদা) ব্যবহার করুন।'
                : '5. Measuring the angle: Use the leveler and the protractor in the app\'s "Tools" tab to check the 25° tilt or the angle of your roof.',
            isDark,
          ),

          _buildImageCard(
            imagePath: AppAssets.installFig2,
            caption: isBangla
                ? 'চিত্র ২: প্যানেল দক্ষিণমুখী করে ভূমির সঙ্গে প্রায় ২৫° কোণে বসান'
                : 'Figure 2: Face the panel south and tilt it at about 25° to the ground',
            isDark: isDark,
          ),

          _bulletItem(
            isBangla
                ? '৬। শক্তভাবে লাগানো: ঝড়ে যেন প্যানেল উড়ে না যায়, তাই মরিচারোধী নাট-বল্টু ব্যবহার করুন। টিনের চালার দুর্বল জায়গায় বা শুধু টিনের ওপর ভর দিয়ে লাগাবেন না।'
                : '6. Fixing firmly: Use rust-resistant nuts and bolts so the panel is not blown away in a storm. Do not fix it on weak parts of a tin roof or on the tin alone.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৭। তারের দৈর্ঘ্য: প্যানেল এমন জায়গায় লাগান, যাতে অল্প দৈর্ঘ্যের তার দিয়ে ঘরের ভেতর কন্ট্রোলারে সংযোগ দেওয়া যায়।'
                : '7. Wire length: Place the panel so that a short wire can bring power to the charge controller inside the house.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '৮। বৃষ্টির পানি: তার ঘরে ঢোকার আগে নিচের দিকে একটু ঝুলিয়ে বাঁকা করে নিন, যাতে পানি তার বেয়ে ভেতরে না আসে। দেয়ালের ফাঁক ভালোভাবে বন্ধ করুন।'
                : '8. Rainwater: Let the wire hang down in a loop before it enters the house, so water cannot run along it inside. Seal gaps in the wall properly.',
            isDark,
          ),

          _buildImageCard(
            imagePath: AppAssets.installFig3,
            caption: isBangla
                ? 'চিত্র ৩: তার ঝুলিয়ে বাঁকা করে ঘরে ঢোকান, যাতে বৃষ্টির পানি ভেতরে না আসে'
                : 'Figure 3: Let the wire loop down before it enters the house so rainwater cannot follow it in',
            isDark: isDark,
          ),

          _bulletItem(
            isBangla
                ? '৯। তারের সংযোগ: "প্রকল্প ডিজাইন" নক্সার ছবি অনুযায়ী প্যানেলের (+) টার্মিনালে লাল তার ও (–) টার্মিনালে কালো/নীল তার লাগান।'
                : '9. Wire connection: As in the "Project Design" drawing, connect the red wire to the terminal marked (+) and the black/blue wire to the terminal marked (–) on the panel.',
            isDark,
          ),
          _bulletItem(
            isBangla
                ? '১০। সিরিজ বা প্যারালাল সংযোগ: ছবিতে দেখানো নিয়মে তার লাগান। সিরিজে ভোল্টেজ বাড়ে এবং প্যারালালে কারেন্ট বাড়ে। একই ধরন ও ক্ষমতার প্যানেল ব্যবহার করুন। মোট ভোল্টেজ কন্ট্রোলারের সর্বোচ্চ সীমার বেশি হতে পারবে না।'
                : '10. Series or parallel connection: Connect the wires as shown in the picture. Series connection raises the voltage, and parallel connection raises the current. Use panels of the same type and rating. The total voltage must not exceed the controller\'s maximum input limit.',
            isDark,
          ),

          _buildImageCard(
            imagePath: AppAssets.installFig4,
            caption: isBangla
                ? 'চিত্র ৪: সিরিজ ও প্যারালাল সংযোগ (ব্যাটারি ও প্যানেল উভয়ের ক্ষেত্রে একই নিয়ম)'
                : 'Figure 4: Series and parallel connections (same rule for batteries and panels)',
            isDark: isDark,
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

  Widget _buildOrderTableCard(bool isBangla, bool isDark) {
    final steps = isBangla
        ? [
            {
              'step': 'ধাপ ১',
              'action': 'সব সুইচ বন্ধ করুন এবং ফিউজ খুলে রাখুন',
            },
            {
              'step': 'ধাপ ২',
              'action': 'আগে ব্যাটারি থেকে কন্ট্রোলারে সংযোগ দিন',
            },
            {
              'step': 'ধাপ ৩',
              'action': 'তারপর প্যানেল থেকে কন্ট্রোলারে সংযোগ দিন',
            },
            {
              'step': 'ধাপ ৪',
              'action': 'সবশেষে কন্ট্রোলার বা ইনভার্টার থেকে লোডে সংযোগ দিন',
            },
            {
              'step': 'ধাপ ৫',
              'action': 'ফিউজ লাগিয়ে চালু করুন এবং কন্ট্রোলারের বাতি দেখুন',
            },
          ]
        : [
            {
              'step': 'Step 1',
              'action': 'Switch everything off and remove the fuses',
            },
            {
              'step': 'Step 2',
              'action': 'Connect the battery to the controller first',
            },
            {
              'step': 'Step 3',
              'action': 'Then connect the panel to the controller',
            },
            {
              'step': 'Step 4',
              'action': 'Finally connect controller/inverter to loads',
            },
            {
              'step': 'Step 5',
              'action': 'Insert the fuses, switch on, check lights',
            },
          ];

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
              Icon(
                Icons.format_list_numbered_rounded,
                color: isDark ? AppColors.accentCyan : Colors.teal,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla
                    ? 'সংযোগ ও চালু করার ক্রম'
                    : 'Connection and Start-up Order',
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
                Container(
                  color: isDark ? AppColors.darkInputBg : Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(
                          isBangla ? 'ধাপ' : 'Step',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark
                                ? AppColors.energyGreen
                                : const Color(0xFF1B6A3B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isBangla ? 'কাজ' : 'Action',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark
                                ? AppColors.energyGreen
                                : const Color(0xFF1B6A3B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                ),
                ...steps.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : Colors.grey.shade200,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            item['step'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.energyGreen
                                  : const Color(0xFF1B6A3B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['action'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : Colors.black87,
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.solarGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.solarGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.solarGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBangla
                        ? 'বন্ধ করতে হলে উল্টো ক্রমে করুন: আগে লোড, তারপর প্যানেল, সবশেষে ব্যাটারি।'
                        : 'To switch off, reverse the order: loads first, then panel, then battery.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.solarGold
                          : const Color(0xFF795548),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(bool isBangla, bool isDark) {
    final List<String> checklist = isBangla
        ? [
            'প্যানেল দক্ষিণমুখী, প্রায় ২৫ ডিগ্রি কোণে এবং ছায়ামুক্ত',
            'প্যানেল ও স্ট্যান্ড শক্তভাবে আটকানো',
            'সব জায়গায় লাল (+) ও কালো/নীল (–) ঠিক আছে',
            'তারের সংযোগ শক্ত এবং কোথাও খোলা তার নেই',
            'ফিউজ বা সার্কিট ব্রেকার লাগানো হয়েছে',
            'তার বেয়ে বৃষ্টির পানি ঘরে ঢুকবে না',
            'ব্যাটারি, কন্ট্রোলার ও ইনভার্টারের ভোল্টেজ মিলেছে',
            'সবকিছু শিশুদের নাগালের বাইরে',
          ]
        : [
            'Panel faces south, tilted at about 25°, and is free of shade',
            'Panel and stand are firmly fixed',
            'Red (+) and black/blue (–) are correct everywhere',
            'All connections are tight and no wire is exposed',
            'Fuse or circuit breaker is installed',
            'Rainwater cannot enter the house along the wires',
            'Battery, controller and inverter voltages match',
            'Everything is out of children\'s reach',
          ];

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
              Icon(
                Icons.checklist_rounded,
                color: isDark ? AppColors.accentCyan : Colors.blueGrey,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'চালু করার আগে চেকলিস্ট' : 'Pre-start Checklist',
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
          ...List.generate(checklist.length, (index) {
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primaryGreen,
              title: Text(
                checklist[index],
                style: TextStyle(
                  fontSize: 13,
                  color: _checklistValues[index]
                      ? (isDark ? Colors.white38 : Colors.grey.shade500)
                      : (isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF37474F)),
                  decoration: _checklistValues[index]
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              value: _checklistValues[index],
              onChanged: (val) {
                setState(() {
                  _checklistValues[index] = val ?? false;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImageCard({
    required String imagePath,
    required String caption,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                color: isDark ? AppColors.darkInputBg : Colors.grey.shade100,
                child: Column(
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      color: isDark ? Colors.white24 : Colors.grey.shade400,
                      size: 36,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ছবি লোড করা যায়নি ($imagePath)',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: isDark ? AppColors.darkInputBg : Colors.grey.shade50,
            child: Text(
              caption,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF37474F),
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
              fontSize: 15,
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
