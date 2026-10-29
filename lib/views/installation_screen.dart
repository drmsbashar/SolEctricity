import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

class InstallationScreen extends StatefulWidget {
  final bool isBangla;

  const InstallationScreen({super.key, required this.isBangla});

  @override
  State<InstallationScreen> createState() => _InstallationScreenState();
}

class _InstallationScreenState extends State<InstallationScreen> {
  // চেকলিস্টের স্টেট সংরক্ষণের তালিকা
  late List<bool> _checklistValues;

  @override
  void initState() {
    super.initState();
    _checklistValues = List.filled(8, false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isBangla = widget.isBangla;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          isBangla
              ? 'সোলার হোম সিস্টেম স্থাপন নির্দেশিকা'
              : 'Solar Home System Installation Guide', //[cite: 2]
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ১. নিরাপত্তার নিয়ম
              _buildSafetyCard(isBangla),
              const SizedBox(height: 12),

              // চিত্র ১: নিরাপত্তার মূল নিষেধ
              _buildImageCard(
                imagePath: AppAssets.installFig1,
                caption: isBangla
                    ? 'চিত্র ১: নিরাপত্তার মূল নিষেধ' //[cite: 2]
                    : 'Figure 1: Key safety prohibitions', //[cite: 2]
              ),
              const SizedBox(height: 16),

              // ২. সোলার প্যানেল স্থাপন
              _buildPanelSection(isBangla),
              const SizedBox(height: 16),

              // ৩. চার্জ কন্ট্রোলার / ইনভার্টার স্থাপন
              _buildSectionCard(
                icon: Icons.developer_board_rounded,
                iconColor: Colors.blueAccent,
                title: isBangla
                    ? 'চার্জ কন্ট্রোলার / ইনভার্টার স্থাপন'
                    : 'Installing Charge Controller / Inverter', //[cite: 2]
                points: isBangla
                    ? [
                        '১। ঘরের ভেতর শুকনো, ঠান্ডা ও বাতাস চলাচলের জায়গায় রাখুন। সরাসরি রোদ ও গরম জায়গা এড়িয়ে চলুন।', //[cite: 2]
                        '২। ইনভার্টারের চারপাশে ফাঁকা জায়গা রাখুন। কিছু দিয়ে ঢেকে দেবেন না।', //[cite: 2]
                        '৩। শিশুদের নাগালের বাইরে রাখুন।', //[cite: 2]
                        '৪। "প্রকল্প ডিজাইন" নক্সা অনুযায়ী (+) চিহ্নিত টার্মিনালে লাল তার ও (–) চিহ্নিত টার্মিনালে কালো/নীল তার লাগান।', //[cite: 2]
                        '৫। ইনভার্টার থেকে বৈদ্যুতিক যন্ত্রে সংযোগের সময় L/P চিহ্নিত টার্মিনালে লাল তার ও N চিহ্নিত টার্মিনালে কালো/নীল তার লাগান।', //[cite: 2]
                        '৬। ব্যাটারির ভোল্টেজ (১২ বা ২৪ ভোল্ট), কন্ট্রোলার ও ইনভার্টারের ভোল্টেজ মিলিয়ে নিন। না মিললে সংযোগ দেবেন না।', //[cite: 2]
                      ]
                    : [
                        '1. Place them indoors in a dry, cool and ventilated place, away from direct sunlight and heat.', //[cite: 2]
                        '2. Leave free space around the inverter. Do not cover it.', //[cite: 2]
                        '3. Keep them out of children\'s reach.', //[cite: 2]
                        '4. As in the "Project Design" drawing, connect the red wire to the terminals marked (+) and the black/blue wire to the terminals marked (–).', //[cite: 2]
                        '5. For the wiring from the inverter to the appliances, connect the red wire to the terminal marked L/P and the black/blue wire to the terminal marked N.', //[cite: 2]
                        '6. Check that the battery voltage (12 V or 24 V) matches the controller and inverter ratings. If it does not match, do not connect.', //[cite: 2]
                      ],
              ),
              const SizedBox(height: 16),

              // ৪. ব্যাটারি স্থাপন
              _buildSectionCard(
                icon: Icons.battery_charging_full_rounded,
                iconColor: Colors.green,
                title: isBangla
                    ? 'ব্যাটারি স্থাপন'
                    : 'Installing the Battery', //[cite: 2]
                points: isBangla
                    ? [
                        '১। ঘরের ভেতর শুকনো, ঠান্ডা ও বাতাস চলাচলের জায়গায় রাখুন। ভেজা মেঝেতে সরাসরি না রেখে কাঠ বা প্লাস্টিকের পাটাতনের ওপর রাখুন।', //[cite: 2]
                        '২। পানি দেওয়ার উপযোগী (ফ্লাডেড) ব্যাটারি শোবার ঘরে রাখবেন না। শিশুদের নাগালের বাইরে রাখুন।', //[cite: 2]
                        '৩। ব্যাটারি কন্ট্রোলার বা ইনভার্টারের কাছে রাখুন, যাতে অল্প দৈর্ঘ্যের তার দিয়ে সংযোগ দেওয়া যায়।', //[cite: 2]
                        '৪। "প্রকল্প ডিজাইন" নক্সা অনুযায়ী ব্যাটারির (+) টার্মিনালে লাল তার ও (–) টার্মিনালে কালো/নীল তার লাগান।', //[cite: 2]
                        '৫। সিরিজ সংযোগে ছবির নিয়ম মেনে তার লাগান। একই ধরন, ক্ষমতা ও বয়সের ব্যাটারি ব্যবহার করুন। পুরনো ও নতুন ব্যাটারি মেশাবেন না।', //[cite: 2]
                        '৬। ব্যাটারি ও কন্ট্রোলারের মাঝে (+) তারে ফিউজ বা সার্কিট ব্রেকার লাগান।', //[cite: 2]
                      ]
                    : [
                        '1. Place it indoors in a dry, cool and ventilated place. Put it on a wooden or plastic platform rather than directly on a damp floor.', //[cite: 2]
                        '2. Do not keep a flooded (refillable) battery in a bedroom. Keep it out of children\'s reach.', //[cite: 2]
                        '3. Keep the battery close to the charge controller or inverter, so that a short wire can connect them.', //[cite: 2]
                        '4. As in the "Project Design" drawing, connect the red wire to the battery\'s (+) terminal and the black/blue wire to the (–) terminal.', //[cite: 2]
                        '5. For a series connection, connect the wires as shown in the picture. Use batteries of the same type, capacity and age. Do not mix old and new batteries.', //[cite: 2]
                        '6. Install a fuse or circuit breaker on the (+) wire between the battery and the controller.', //[cite: 2]
                      ],
              ),
              const SizedBox(height: 16),

              // ৫. তার, সুরক্ষা ও আর্থিং
              _buildSectionCard(
                icon: Icons.cable_rounded,
                iconColor: Colors.deepPurpleAccent,
                title: isBangla
                    ? 'তার, সুরক্ষা ও আর্থিং'
                    : 'Wiring, Protection and Earthing', //[cite: 2]
                points: isBangla
                    ? [
                        '১। সিস্টেমের ক্ষমতার উপযোগী পুরু তার ব্যবহার করুন। খোলা জায়গার তার রোদ-সহনশীল হতে হবে এবং পাইপ বা নালার ভেতর দিয়ে নিতে হবে।', //[cite: 2]
                        '২। সব সংযোগ শক্ত করে লাগান। কোনো টার্মিনাল বা তারের খোলা অংশ যেন বাইরে না থাকে।', //[cite: 2]
                        '৩। বজ্রপাত ও বিদ্যুৎ-ঝুঁকি কমাতে প্যানেলের ফ্রেম ও স্ট্যান্ডে আর্থিং (মাটির সঙ্গে সংযোগ) দিন। এ কাজ প্রশিক্ষিত প্রযুক্তিবিদ দিয়ে করানো ভালো।', //[cite: 2]
                      ]
                    : [
                        '1. Use thick wire suitable for the system\'s capacity. Wire in open areas must be sunlight-resistant and run inside a pipe or conduit.', //[cite: 2]
                        '2. Make all connections tight. No bare wire or terminal should be left exposed.', //[cite: 2]
                        '3. To reduce lightning and electrical hazards, earth (ground) the panel frame and stand. It is best to have a trained technician do this.', //[cite: 2]
                      ],
              ),
              const SizedBox(height: 16),

              // চিত্র ৫: সংযোগের ক্রম
              _buildImageCard(
                imagePath: AppAssets.installFig5,
                caption: isBangla
                    ? 'চিত্র ৫: সংযোগের ক্রম — ১. ব্যাটারি, ২. প্যানেল, ৩. লোড' //[cite: 2]
                    : 'Figure 5: Connection order — 1. battery, 2. panel, 3. loads', //[cite: 2]
              ),
              const SizedBox(height: 8),

              // ৬. সংযোগ ও চালু করার ক্রম (টেবিল কার্ড)
              _buildOrderTableCard(isBangla),
              const SizedBox(height: 20),

              // ৭. চালু করার আগে চেকলিস্ট
              _buildChecklistCard(isBangla),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // নিরাপত্তার নিয়ম কার্ড
  Widget _buildSafetyCard(bool isBangla) {
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
                    : 'Safety Rules (Read First)', //[cite: 2]
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
                ? '১। বৃষ্টি, ভেজা আবহাওয়া বা ঝড়ের সময় ছাদে কাজ করবেন না। সম্ভব হলে দুজন মিলে কাজ করুন।' //[cite: 2]
                : '1. Do not work on the roof in rain, wet weather or storms. If possible, work in pairs.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '২। আলো পড়লে প্যানেল থেকে বিদ্যুৎ তৈরি হয়। তাই তার লাগানোর সময় প্যানেল অন্ধকার কাপড় বা কার্টন দিয়ে ঢেকে রাখুন, অথবা সকালে বা সন্ধ্যায় কাজ করুন।' //[cite: 2]
                : '2. A panel produces electricity whenever light falls on it. Cover the panel with a dark cloth or cardboard while connecting wires, or work in the early morning or evening.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '৩। ব্যাটারির দুই টার্মিনাল কখনো ধাতব জিনিস (চাবি, প্লায়ার্স, তার) দিয়ে একসঙ্গে ছুঁবেন না। কাজের সময় আংটি ও ঘড়ি খুলে রাখুন এবং ইনসুলেশন দেওয়া যন্ত্র ব্যবহার করুন।' //[cite: 2]
                : '3. Never touch both battery terminals together with any metal object (keys, pliers, wire). Remove rings and watches, and use insulated tools.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '৪। ব্যাটারির কাছে আগুন, ধূমপান বা স্ফুলিঙ্গ নয়।' //[cite: 2]
                : '4. No fire, smoking or sparks near the battery.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '৫। লাল তার (+) ও কালো/নীল তার (–) ভুল জায়গায় লাগালে কন্ট্রোলার বা ইনভার্টার নষ্ট হতে পারে। লাগানোর আগে প্রতিবার চিহ্ন মিলিয়ে নিন।' //[cite: 2]
                : '5. Connecting red (+) and black/blue (–) wires the wrong way can damage the controller or inverter. Check the markings every time before connecting.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '৬। কাজ শেষ না হওয়া পর্যন্ত সব সুইচ বন্ধ এবং ফিউজ খোলা রাখুন।' //[cite: 2]
                : '6. Keep all switches off and fuses removed until the work is finished.', //[cite: 2]
          ),
        ],
      ),
    );
  }

  // সোলার প্যানেল সেকশন (ছবিসহ)
  Widget _buildPanelSection(bool isBangla) {
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
              const Icon(
                Icons.solar_power_rounded,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                isBangla
                    ? 'সোলার প্যানেল স্থাপন'
                    : 'Installing the Solar Panel', //[cite: 2]
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          _bulletItem(
            isBangla
                ? '১। জায়গা: সাধারণত বাড়ির ছাদে বা টিনের চালার ওপর প্যানেল বসানো হয়। ছাদ বা চালায় ছায়া পড়লে ঘরের কাছে খোলা জায়গায় শক্ত খুঁটি বা স্ট্যান্ডের ওপর উঁচুতে বসান। গাছ বা দালানের ছায়া যেন সকাল ৮টা থেকে বিকাল ৪টা পর্যন্ত প্যানেলে না পড়ে।' //[cite: 2]
                : '1. Location: Panels are usually mounted on the rooftop or tin roof of a house. If the roof is shaded, mount the panel in an open area near the house, high on a sturdy pole or stand. Make sure no shade from trees or buildings falls on the panel between 8 am and 4 pm.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '২। দিক: প্যানেল দক্ষিণমুখী করে বসান, যাতে সকাল ৮টা থেকে বিকাল ৪টা পর্যন্ত, অর্থাৎ অন্তত ৮ ঘণ্টা সূর্যের আলো পাওয়া যায়।' //[cite: 2]
                : '2. Direction: Face the panels south so they receive direct sunlight for at least eight hours, from 8 am to 4 pm.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '৩। দক্ষিণ দিক বের করা: Solectricity অ্যাপের "টুল" অংশে কম্পাস আছে, তা দিয়ে ঠিক দক্ষিণ দিক বের করুন। কম্পাস দেখার সময় ফোন লোহা বা ধাতব জিনিস থেকে দূরে রাখুন।' //[cite: 2]
                : '3. Finding south: Use the compass in the "Tools" tab of the Solectricity app to find due south. Keep the phone away from iron and metal objects while using it.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '৪। কোণ: সর্বোচ্চ বিদ্যুৎ পেতে প্যানেল ভূমির সঙ্গে প্রায় ২৫ ডিগ্রি কোণে বসান।' //[cite: 2]
                : '4. Tilt: For maximum power, tilt the south-facing panel at about 25 degrees to the ground.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '৫। কোণ মাপা: ২৫ ডিগ্রি কোণ বা চালার কোণ মাপতে অ্যাপের "টুল" অংশের সমতলকারী (লেভেলার) ও কোণমাপক (চাঁদা) ব্যবহার করুন।' //[cite: 2]
                : '5. Measuring the angle: Use the leveler and the protractor in the app\'s "Tools" tab to check the 25° tilt or the angle of your roof.', //[cite: 2]
          ),

          // চিত্র ২: কোণ ও দিক
          _buildImageCard(
            imagePath: AppAssets.installFig2,
            caption: isBangla
                ? 'চিত্র ২: প্যানেল দক্ষিণমুখী করে ভূমির সঙ্গে প্রায় ২৫° কোণে বসান' //[cite: 2]
                : 'Figure 2: Face the panel south and tilt it at about 25° to the ground', //[cite: 2]
          ),

          _bulletItem(
            isBangla
                ? '৬। শক্তভাবে লাগানো: ঝড়ে যেন প্যানেল উড়ে না যায়, তাই মরিচারোধী নাট-বল্টু ব্যবহার করুন। টিনের চালার দুর্বল জায়গায় বা শুধু টিনের ওপর ভর দিয়ে লাগাবেন না।' //[cite: 2]
                : '6. Fixing firmly: Use rust-resistant nuts and bolts so the panel is not blown away in a storm. Do not fix it on weak parts of a tin roof or on the tin alone.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '৭। তারের দৈর্ঘ্য: প্যানেল এমন জায়গায় লাগান, যাতে অল্প দৈর্ঘ্যের তার দিয়ে ঘরের ভেতর কন্ট্রোলারে সংযোগ দেওয়া যায়।' //[cite: 2]
                : '7. Wire length: Place the panel so that a short wire can bring power to the charge controller inside the house.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '৮। বৃষ্টির পানি: তার ঘরে ঢোকার আগে নিচের দিকে একটু ঝুলিয়ে বাঁকা করে নিন, যাতে পানি তার বেয়ে ভেতরে না আসে। দেয়ালের ফাঁক ভালোভাবে বন্ধ করুন।' //[cite: 2]
                : '8. Rainwater: Let the wire hang down in a loop before it enters the house, so water cannot run along it inside. Seal gaps in the wall properly.', //[cite: 2]
          ),

          // চিত্র ৩: ড্রিপ লুপ
          _buildImageCard(
            imagePath: AppAssets.installFig3,
            caption: isBangla
                ? 'চিত্র ৩: তার ঝুলিয়ে বাঁকা করে ঘরে ঢোকান, যাতে বৃষ্টির পানি ভেতরে না আসে' //[cite: 2]
                : 'Figure 3: Let the wire loop down before it enters the house so rainwater cannot follow it in', //[cite: 2]
          ),

          _bulletItem(
            isBangla
                ? '৯। তারের সংযোগ: "প্রকল্প ডিজাইন" নক্সার ছবি অনুযায়ী প্যানেলের (+) টার্মিনালে লাল তার ও (–) টার্মিনালে কালো/নীল তার লাগান।' //[cite: 2]
                : '9. Wire connection: As in the "Project Design" drawing, connect the red wire to the terminal marked (+) and the black/blue wire to the terminal marked (–) on the panel.', //[cite: 2]
          ),
          _bulletItem(
            isBangla
                ? '১০। সিরিজ বা প্যারালাল সংযোগ: ছবিতে দেখানো নিয়মে তার লাগান। সিরিজে ভোল্টেজ বাড়ে এবং প্যারালালে কারেন্ট বাড়ে। একই ধরন ও ক্ষমতার প্যানেল ব্যবহার করুন। মোট ভোল্টেজ কন্ট্রোলারের সর্বোচ্চ সীমার বেশি হতে পারবে না।' //[cite: 2]
                : '10. Series or parallel connection: Connect the wires as shown in the picture. Series connection raises the voltage, and parallel connection raises the current. Use panels of the same type and rating. The total voltage must not exceed the controller\'s maximum input limit.', //[cite: 2]
          ),

          // চিত্র ৪: সিরিজ ও প্যারালাল সংযোগ
          _buildImageCard(
            imagePath: AppAssets.installFig4,
            caption: isBangla
                ? 'চিত্র ৪: সিরিজ ও প্যারালাল সংযোগ (ব্যাটারি ও প্যানেল উভয়ের ক্ষেত্রে একই নিয়ম)' //[cite: 2]
                : 'Figure 4: Series and parallel connections (same rule for batteries and panels)', //[cite: 2]
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

  // সংযোগের ক্রম টেবিল কার্ড
  Widget _buildOrderTableCard(bool isBangla) {
    final List<Map<String, String>> steps = isBangla
        ? [
            {
              'step': 'ধাপ ১',
              'action': 'সব সুইচ বন্ধ করুন এবং ফিউজ খুলে রাখুন',
            }, //[cite: 2]
            {
              'step': 'ধাপ ২',
              'action': 'আগে ব্যাটারি থেকে কন্ট্রোলারে সংযোগ দিন',
            }, //[cite: 2]
            {
              'step': 'ধাপ ৩',
              'action': 'তারপর প্যানেল থেকে কন্ট্রোলারে সংযোগ দিন',
            }, //[cite: 2]
            {
              'step': 'ধাপ ৪',
              'action': 'সবশেষে কন্ট্রোলার বা ইনভার্টার থেকে লোডে (বাতি, পাখা ইত্যাদি) সংযোগ দিন',
            }, //[cite: 2]
            {
              'step': 'ধাপ ৫',
              'action': 'ফিউজ লাগিয়ে চালু করুন এবং কন্ট্রোলারের বাতি ঠিক জ্বলছে কিনা দেখুন',
            }, //[cite: 2]
          ]
        : [
            {
              'step': 'Step 1',
              'action': 'Switch everything off and remove the fuses',
            }, //[cite: 2]
            {
              'step': 'Step 2',
              'action': 'Connect the battery to the controller first',
            }, //[cite: 2]
            {
              'step': 'Step 3',
              'action': 'Then connect the panel to the controller',
            }, //[cite: 2]
            {
              'step': 'Step 4',
              'action': 'Finally connect the controller or inverter to the loads (lights, fans, etc.)',
            }, //[cite: 2]
            {
              'step': 'Step 5',
              'action': 'Insert the fuses, switch on, and check that the controller lights are normal',
            }, //[cite: 2]
          ];

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
              const Icon(
                Icons.format_list_numbered_rounded,
                color: Colors.teal,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla
                    ? 'সংযোগ ও চালু করার ক্রম'
                    : 'Connection and Start-up Order', //[cite: 2]
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
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(
                          isBangla ? 'ধাপ' : 'Step', //[cite: 2]
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
                          isBangla ? 'কাজ' : 'Action', //[cite: 2]
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
                ...steps.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
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
                          width: 70,
                          child: Text(
                            item['step'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF1B6A3B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['action'] ?? '',
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBangla
                        ? 'বন্ধ করতে হলে উল্টো ক্রমে করুন: আগে লোড, তারপর প্যানেল, সবশেষে ব্যাটারি।' //[cite: 2]
                        : 'To switch off, reverse the order: loads first, then panel, then battery.', //[cite: 2]
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF795548),
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

  // চালু করার আগে চেকলিস্ট
  Widget _buildChecklistCard(bool isBangla) {
    final List<String> checklist = isBangla
        ? [
            'প্যানেল দক্ষিণমুখী, প্রায় ২৫ ডিগ্রি কোণে এবং ছায়ামুক্ত', //[cite: 2]
            'প্যানেল ও স্ট্যান্ড শক্তভাবে আটকানো', //[cite: 2]
            'সব জায়গায় লাল (+) ও কালো/নীল (–) ঠিক আছে', //[cite: 2]
            'তারের সংযোগ শক্ত এবং কোথাও খোলা তার নেই', //[cite: 2]
            'ফিউজ বা সার্কিট ব্রেকার লাগানো হয়েছে', //[cite: 2]
            'তার বেয়ে বৃষ্টির পানি ঘরে ঢুকবে না', //[cite: 2]
            'ব্যাটারি, কন্ট্রোলার ও ইনভার্টারের ভোল্টেজ মিলেছে', //[cite: 2]
            'সবকিছু শিশুদের নাগালের বাইরে', //[cite: 2]
          ]
        : [
            'Panel faces south, tilted at about 25°, and is free of shade', //[cite: 2]
            'Panel and stand are firmly fixed', //[cite: 2]
            'Red (+) and black/blue (–) are correct everywhere', //[cite: 2]
            'All connections are tight and no wire is exposed', //[cite: 2]
            'Fuse or circuit breaker is installed', //[cite: 2]
            'Rainwater cannot enter the house along the wires', //[cite: 2]
            'Battery, controller and inverter voltages match', //[cite: 2]
            'Everything is out of children\'s reach', //[cite: 2]
          ];

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
              const Icon(
                Icons.checklist_rounded,
                color: Colors.blueGrey,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isBangla
                    ? 'চালু করার আগে চেকলিস্ট'
                    : 'Pre-start Checklist', //[cite: 2]
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
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
                      ? Colors.grey.shade600
                      : const Color(0xFF37474F),
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

  // ছবি এবং ক্যাপশন প্রদর্শনকারী কার্ড
  Widget _buildImageCard({required String imagePath, required String caption}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
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
                color: Colors.grey.shade100,
                child: Column(
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey.shade400,
                      size: 36,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ছবি লোড করা যায়নি ($imagePath)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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
            color: Colors.grey.shade50,
            child: Text(
              caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF37474F),
              ),
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
              fontSize: 15,
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
