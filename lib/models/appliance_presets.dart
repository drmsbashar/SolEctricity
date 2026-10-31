class AppliancePreset {
  final String nameBn;
  final String nameEn;
  final double defaultWatt;
  final bool defaultIsAC;

  const AppliancePreset({
    required this.nameBn,
    required this.nameEn,
    required this.defaultWatt,
    required this.defaultIsAC,
  });
}

class CategoryConfig {
  final String key;
  final String titleBn;
  final String titleEn;
  final String svgPath;
  final List<AppliancePreset> presets;

  const CategoryConfig({
    required this.key,
    required this.titleBn,
    required this.titleEn,
    required this.svgPath,
    required this.presets,
  });
}

class AppliancePresetsData {
  static const List<CategoryConfig> categories = [
    // ১. লাইট
    CategoryConfig(
      key: 'light',
      titleBn: 'লাইট',
      titleEn: 'Light',
      svgPath: 'assets/icons/light.png',
      presets: [
        AppliancePreset(
          nameBn: 'এলইডি বাল্ব',
          nameEn: 'LED Bulb',
          defaultWatt: 9,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'সোলার ডিসি বাল্ব',
          nameEn: 'Solar DC Bulb',
          defaultWatt: 7,
          defaultIsAC: false,
        ),
        AppliancePreset(
          nameBn: 'এনার্জি সেভিং বাল্ব (CFL)',
          nameEn: 'Energy Saving (CFL)',
          defaultWatt: 18,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'এলইডি টিউব ২’',
          nameEn: 'LED Tube 2ft',
          defaultWatt: 10,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'এলইডি টিউব ৪’',
          nameEn: 'LED Tube 4ft',
          defaultWatt: 20,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'এলইডি প্যানেল লাইট',
          nameEn: 'LED Panel Light',
          defaultWatt: 15,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'টিউব লাইট ২’',
          nameEn: 'Fluorescent Tube 2ft',
          defaultWatt: 20,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'টিউব লাইট ৪’',
          nameEn: 'Fluorescent Tube 4ft',
          defaultWatt: 40,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম লাইট',
          nameEn: 'Custom Light',
          defaultWatt: 12,
          defaultIsAC: true,
        ),
      ],
    ),

    // ২. ফ্যান
    CategoryConfig(
      key: 'fan',
      titleBn: 'ফ্যান',
      titleEn: 'Fan',
      svgPath: 'assets/icons/fan.png',
      presets: [
        AppliancePreset(
          nameBn: 'সিলিং ফ্যান (AC)',
          nameEn: 'Ceiling Fan (AC)',
          defaultWatt: 75,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'সোলার সিলিং ফ্যান (BLDC/DC)',
          nameEn: 'Solar BLDC Fan (DC)',
          defaultWatt: 30,
          defaultIsAC: false,
        ),
        AppliancePreset(
          nameBn: 'টেবিল ফ্যান (AC)',
          nameEn: 'Table Fan (AC)',
          defaultWatt: 45,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'টেবিল ফ্যান (DC)',
          nameEn: 'Table Fan (DC)',
          defaultWatt: 20,
          defaultIsAC: false,
        ),
        AppliancePreset(
          nameBn: 'দেয়াল ফ্যান (Wall Fan)',
          nameEn: 'Wall Fan',
          defaultWatt: 50,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'স্ট্যান্ড ফ্যান (Pedestal Fan)',
          nameEn: 'Pedestal Fan',
          defaultWatt: 60,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম ফ্যান',
          nameEn: 'Custom Fan',
          defaultWatt: 55,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৩. টেলিভিশন
    CategoryConfig(
      key: 'tv',
      titleBn: 'টেলিভিশন',
      titleEn: 'TV',
      svgPath: 'assets/icons/tv.png',
      presets: [
        AppliancePreset(
          nameBn: 'এলইডি টিভি (২৪"-৩২")',
          nameEn: 'LED TV (24"-32")',
          defaultWatt: 40,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ডিসি এলইডি টিভি (২৪"-৩২")',
          nameEn: 'DC LED TV (24"-32")',
          defaultWatt: 25,
          defaultIsAC: false,
        ),
        AppliancePreset(
          nameBn: 'এলইডি টিভি (৪০"-৫৫")',
          nameEn: 'LED TV (40"-55")',
          defaultWatt: 70,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'স্মার্ট ৪কে টিভি',
          nameEn: 'Smart 4K TV',
          defaultWatt: 100,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'বাক্স টিভি (CRT)',
          nameEn: 'CRT Box TV',
          defaultWatt: 90,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম টিভি',
          nameEn: 'Custom TV',
          defaultWatt: 50,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৪. কম্পিউটার
    CategoryConfig(
      key: 'computer',
      titleBn: 'কম্পিউটার',
      titleEn: 'Computer',
      svgPath: 'assets/icons/computer.png',
      presets: [
        AppliancePreset(
          nameBn: 'অফিস ডেস্কটপ ও মনিটর',
          nameEn: 'Desktop PC & Monitor',
          defaultWatt: 150,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'গেমিং / ভারী পিসি',
          nameEn: 'Gaming PC',
          defaultWatt: 350,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'অল-ইন-ওয়ান পিসি',
          nameEn: 'All-in-One PC',
          defaultWatt: 90,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম পিসি',
          nameEn: 'Custom PC',
          defaultWatt: 180,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৫. ল্যাপটপ
    CategoryConfig(
      key: 'laptop',
      titleBn: 'ল্যাপটপ',
      titleEn: 'Laptop',
      svgPath: 'assets/icons/laptop.png',
      presets: [
        AppliancePreset(
          nameBn: 'সাধারণ ল্যাপটপ',
          nameEn: 'Standard Laptop',
          defaultWatt: 45,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'গেমিং ল্যাপটপ',
          nameEn: 'Gaming Laptop',
          defaultWatt: 120,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ট্যাবলেট / আইপ্যাড',
          nameEn: 'Tablet / iPad',
          defaultWatt: 15,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম ল্যাপটপ',
          nameEn: 'Custom Laptop',
          defaultWatt: 65,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৬. প্রিন্টার
    CategoryConfig(
      key: 'printer',
      titleBn: 'প্রিন্টার',
      titleEn: 'Printer',
      svgPath: 'assets/icons/printer.png',
      presets: [
        AppliancePreset(
          nameBn: 'ইঙ্কজেট প্রিন্টার',
          nameEn: 'Inkjet Printer',
          defaultWatt: 25,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'লেজার প্রিন্টার',
          nameEn: 'Laser Printer',
          defaultWatt: 400,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম প্রিন্টার',
          nameEn: 'Custom Printer',
          defaultWatt: 50,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৭. এয়ারকুলার
    CategoryConfig(
      key: 'ac_cooler',
      titleBn: 'এয়ারকুলার',
      titleEn: 'AC / Cooler',
      svgPath: 'assets/icons/ac.png',
      presets: [
        AppliancePreset(
          nameBn: 'সাধারণ এয়ারকুলার',
          nameEn: 'Room Air Cooler',
          defaultWatt: 150,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ইনভার্টার এয়ারকুলার',
          nameEn: 'Inverter Air Cooler',
          defaultWatt: 100,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: '১ টন ইনভার্টার এসি',
          nameEn: '1.0 Ton Inverter AC',
          defaultWatt: 1000,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: '১.৫ টন ইনভার্টার এসি',
          nameEn: '1.5 Ton Inverter AC',
          defaultWatt: 1500,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম কুলার/এসি',
          nameEn: 'Custom Cooler/AC',
          defaultWatt: 200,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৮. ফ্রিজ
    CategoryConfig(
      key: 'fridge',
      titleBn: 'ফ্রিজ',
      titleEn: 'Fridge',
      svgPath: 'assets/icons/fridge.png',
      presets: [
        AppliancePreset(
          nameBn: 'সাধারণ ফ্রিজ (নন-ইনভার্টার)',
          nameEn: 'Standard Refrigerator',
          defaultWatt: 150,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ইনভার্টার ফ্রিজ',
          nameEn: 'Inverter Refrigerator',
          defaultWatt: 90,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ডিপ ফ্রিজ',
          nameEn: 'Deep Freezer',
          defaultWatt: 200,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'সোলার ডিসি ফ্রিজ',
          nameEn: 'Solar DC Refrigerator',
          defaultWatt: 60,
          defaultIsAC: false,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম ফ্রিজ',
          nameEn: 'Custom Fridge',
          defaultWatt: 120,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৯. কুকার
    CategoryConfig(
      key: 'cooker',
      titleBn: 'কুকার',
      titleEn: 'Cooker',
      svgPath: 'assets/icons/cooker.png',
      presets: [
        AppliancePreset(
          nameBn: 'রাইস কুকার',
          nameEn: 'Rice Cooker',
          defaultWatt: 700,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ইন্ডাকশন কুকার',
          nameEn: 'Induction Cooker',
          defaultWatt: 1500,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ইনফ্রারেড কুকার',
          nameEn: 'Infrared Cooker',
          defaultWatt: 1800,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম কুকার',
          nameEn: 'Custom Cooker',
          defaultWatt: 1000,
          defaultIsAC: true,
        ),
      ],
    ),

    // ১০. ওভেন
    CategoryConfig(
      key: 'oven',
      titleBn: 'ওভেন',
      titleEn: 'Oven',
      svgPath: 'assets/icons/oven.png',
      presets: [
        AppliancePreset(
          nameBn: 'মাইক্রোওয়েভ ওভেন',
          nameEn: 'Microwave Oven',
          defaultWatt: 1000,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ইলেকট্রিক ওভেন (OTG)',
          nameEn: 'Electric Oven / OTG',
          defaultWatt: 1200,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম ওভেন',
          nameEn: 'Custom Oven',
          defaultWatt: 1100,
          defaultIsAC: true,
        ),
      ],
    ),

    // ১১. ব্লেন্ডার
    CategoryConfig(
      key: 'blender',
      titleBn: 'ব্লেন্ডার',
      titleEn: 'Blender',
      svgPath: 'assets/icons/blender.png',
      presets: [
        AppliancePreset(
          nameBn: 'চপার / মিনি ব্লেন্ডার',
          nameEn: 'Chopper / Mini Blender',
          defaultWatt: 300,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'মিক্সার ও ব্লেন্ডার',
          nameEn: 'Mixer & Blender',
          defaultWatt: 550,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ভারী গ্রাইন্ডার',
          nameEn: 'Heavy Duty Grinder',
          defaultWatt: 750,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম ব্লেন্ডার',
          nameEn: 'Custom Blender',
          defaultWatt: 450,
          defaultIsAC: true,
        ),
      ],
    ),

    // ১২. অন্যান্য
    CategoryConfig(
      key: 'others',
      titleBn: 'অন্যান্য',
      titleEn: 'Others',
      svgPath: 'assets/icons/others.png',
      presets: [
        AppliancePreset(
          nameBn: 'ওয়াইফাই রাউটার ও ওএনইউ (AC)',
          nameEn: 'Wi-Fi Router & ONU (AC)',
          defaultWatt: 15,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ওয়াইফাই রাউটার (DC সোলার/মিনি ইউপিএস)',
          nameEn: 'Wi-Fi Router (DC 12V)',
          defaultWatt: 10,
          defaultIsAC: false,
        ),
        AppliancePreset(
          nameBn: 'সিসিটিভি ক্যামেরা সিস্টেম',
          nameEn: 'CCTV Camera Setup',
          defaultWatt: 40,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'মোবাইল চার্জার',
          nameEn: 'Mobile Charger',
          defaultWatt: 18,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'পানির পাম্প (০.৫ ঘোড়া)',
          nameEn: 'Water Pump (0.5 HP)',
          defaultWatt: 375,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'পানির পাম্প (১.০ ঘোড়া)',
          nameEn: 'Water Pump (1.0 HP)',
          defaultWatt: 750,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম উপকরণ',
          nameEn: 'Custom Appliance',
          defaultWatt: 50,
          defaultIsAC: true,
        ),
      ],
    ),
  ];
}
