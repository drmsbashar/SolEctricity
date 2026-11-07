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
    // ১. লাইটিং
    CategoryConfig(
      key: 'light',
      titleBn: 'লাইট',
      titleEn: 'Lighting',
      svgPath: 'assets/icons/light.png',
      presets: [
        AppliancePreset(
          nameBn: 'LED বাল্ব (সাধারণ)',
          nameEn: 'LED Bulb (9W-12W)',
          defaultWatt: 12,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'LED বাল্ব (উচ্চ আলো)',
          nameEn: 'LED Bulb (High Watt)',
          defaultWatt: 18,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'টিউবলাইট',
          nameEn: 'Tube Light',
          defaultWatt: 20,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ডাউনলাইট / স্পটলাইট',
          nameEn: 'Downlight / Spot',
          defaultWatt: 15,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ফ্লাডলাইট',
          nameEn: 'Floodlight',
          defaultWatt: 50,
          defaultIsAC: true,
        ),
      ],
    ),

    // ২. ফ্যান
    CategoryConfig(
      key: 'fan',
      titleBn: 'ফ্যান',
      titleEn: 'Fans',
      svgPath: 'assets/icons/fan.png',
      presets: [
        AppliancePreset(
          nameBn: 'বিএলডিসি সিলিং ফ্যান',
          nameEn: 'BLDC Ceiling Fan',
          defaultWatt: 35,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'সাধারণ সিলিং ফ্যান',
          nameEn: 'Standard Ceiling Fan',
          defaultWatt: 85,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'টেবিল / পেডেস্টাল ফ্যান',
          nameEn: 'Table / Pedestal Fan',
          defaultWatt: 55,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'নিষ্কাশন ফ্যান (Exhaust)',
          nameEn: 'Exhaust Fan',
          defaultWatt: 35,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৩. টেলিভিশন
    CategoryConfig(
      key: 'tv',
      titleBn: 'টেলিভিশন',
      titleEn: 'Television',
      svgPath: 'assets/icons/tv.png',
      presets: [
        AppliancePreset(
          nameBn: '৩২″ পর্যন্ত টিভি',
          nameEn: 'Up to 32" TV',
          defaultWatt: 35,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: '৪৩″–৫০″ স্মার্ট টিভি',
          nameEn: '43"-50" Smart TV',
          defaultWatt: 60,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: '৫৫″ বা তদূর্ধ্ব টিভি',
          nameEn: '55"+ Large TV',
          defaultWatt: 100,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৪. কম্পিউটার
    CategoryConfig(
      key: 'computer',
      titleBn: 'কম্পিউটার',
      titleEn: 'Computers',
      svgPath: 'assets/icons/computer.png',
      presets: [
        AppliancePreset(
          nameBn: 'ডেস্কটপ পিসি (মনিটরসহ)',
          nameEn: 'Desktop PC with Monitor',
          defaultWatt: 130,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'অল-ইন-ওয়ান পিসি',
          nameEn: 'All-in-One PC',
          defaultWatt: 85,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ওয়ার্কস্টেশন / গেমিং পিসি',
          nameEn: 'High-End Workstation',
          defaultWatt: 350,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'মিনি সার্ভার / নেটওয়ার্ক র্যাক',
          nameEn: 'Mini Server / Network Rack',
          defaultWatt: 180,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৫. ল্যাপটপ ও ট্যাবলেট
    CategoryConfig(
      key: 'laptop',
      titleBn: 'ল্যাপটপ',
      titleEn: 'Laptops & Tablets',
      svgPath: 'assets/icons/laptop.png',
      presets: [
        AppliancePreset(
          nameBn: 'সাধারণ ল্যাপটপ',
          nameEn: 'Standard Laptop',
          defaultWatt: 65,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'হেভি-ডিউটি ল্যাপটপ',
          nameEn: 'High-Performance Laptop',
          defaultWatt: 130,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ট্যাবলেট / আইপ্যাড',
          nameEn: 'Tablet / iPad',
          defaultWatt: 15,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'মোবাইল ফাস্ট চার্জার',
          nameEn: 'Mobile Fast Charger',
          defaultWatt: 25,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৬. প্রিন্টার
    CategoryConfig(
      key: 'printer',
      titleBn: 'প্রিন্টার',
      titleEn: 'Printers',
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
          defaultWatt: 450,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ফটোকপিয়ার মেশিন',
          nameEn: 'Photocopier Machine',
          defaultWatt: 900,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৭. কুলিং ও শীতাতপ নিয়ন্ত্রণ
    CategoryConfig(
      key: 'air_cooler',
      titleBn: 'এয়ারকুলার ও এসি',
      titleEn: 'Cooling & AC',
      svgPath: 'assets/icons/ac.png',
      presets: [
        AppliancePreset(
          nameBn: 'রুম এয়ারকুলার',
          nameEn: 'Air Cooler',
          defaultWatt: 120,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: '১.০ টন ইনভার্টার এসি',
          nameEn: '1.0 Ton Inverter AC',
          defaultWatt: 850,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: '১.৫ টন ইনভার্টার এসি',
          nameEn: '1.5 Ton Inverter AC',
          defaultWatt: 1350,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: '১.০ টন সাধারণ এসি',
          nameEn: '1.0 Ton Non-Inverter AC',
          defaultWatt: 1100,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: '১.৫ টন সাধারণ এসি',
          nameEn: '1.5 Ton Non-Inverter AC',
          defaultWatt: 1600,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৮. রেফ্রিজারেশন
    CategoryConfig(
      key: 'fridge',
      titleBn: 'ফ্রিজ',
      titleEn: 'Refrigeration',
      svgPath: 'assets/icons/fridge.png',
      presets: [
        AppliancePreset(
          nameBn: 'বেভারেজ ফ্রিজ',
          nameEn: 'Beverage Cooler',
          defaultWatt: 80,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ইনভার্টার রেফ্রিজারেটর',
          nameEn: 'Inverter Refrigerator',
          defaultWatt: 140,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'সাধারণ রেফ্রিজারেটর',
          nameEn: 'Non-Inverter Refrigerator',
          defaultWatt: 250,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ডিপ ফ্রিজার',
          nameEn: 'Chest / Deep Freezer',
          defaultWatt: 250,
          defaultIsAC: true,
        ),
      ],
    ),

    // ৯. রান্নার সরঞ্জাম
    CategoryConfig(
      key: 'cooker',
      titleBn: 'কুকার',
      titleEn: 'Electric Cooking',
      svgPath: 'assets/icons/cooker.png',
      presets: [
        AppliancePreset(
          nameBn: 'রাইস কুকার',
          nameEn: 'Rice Cooker',
          defaultWatt: 700,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ইলেকট্রিক কেটলি',
          nameEn: 'Electric Kettle',
          defaultWatt: 1200,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ইন্ডাকশন কুকার',
          nameEn: 'Induction Cooker',
          defaultWatt: 1400,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ইনফ্রারেড কুকার',
          nameEn: 'Infrared Cooker',
          defaultWatt: 1800,
          defaultIsAC: true,
        ),
      ],
    ),

    // ১০. ওভেন
    CategoryConfig(
      key: 'oven',
      titleBn: 'ওভেন',
      titleEn: 'Ovens',
      svgPath: 'assets/icons/oven.png',
      presets: [
        AppliancePreset(
          nameBn: 'মাইক্রোওয়েভ ওভেন',
          nameEn: 'Microwave Oven',
          defaultWatt: 900,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ইলেকট্রিক ওভেন / ওটিজি',
          nameEn: 'Electric Oven / OTG',
          defaultWatt: 1300,
          defaultIsAC: true,
        ),
      ],
    ),

    // ১১. ফুড প্রিপারেশন
    CategoryConfig(
      key: 'blender',
      titleBn: 'ব্লেন্ডার',
      titleEn: 'Food Preparation',
      svgPath: 'assets/icons/blender.png',
      presets: [
        AppliancePreset(
          nameBn: 'ব্লেন্ডার / চপার',
          nameEn: 'Blender / Chopper',
          defaultWatt: 400,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'হেভি-ডিউটি গ্রাইন্ডার',
          nameEn: 'Heavy-Duty Grinder',
          defaultWatt: 750,
          defaultIsAC: true,
        ),
      ],
    ),

    // ১২. অন্যান্য সাধারণ লোড
    CategoryConfig(
      key: 'others',
      titleBn: 'অন্যান্য',
      titleEn: 'General Utility',
      svgPath: 'assets/icons/others.png',
      presets: [
        AppliancePreset(
          nameBn: 'ওয়াইফাই রাউটার ও ওএনইউ',
          nameEn: 'Wi-Fi Router & ONU',
          defaultWatt: 15,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'সিসিটিভি ক্যামেরা সিস্টেম',
          nameEn: 'CCTV Setup',
          defaultWatt: 40,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'পানির পাম্প (০.৫ HP)',
          nameEn: 'Water Pump (0.5 HP)',
          defaultWatt: 450,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'পানির পাম্প (১.০ HP)',
          nameEn: 'Water Pump (1.0 HP)',
          defaultWatt: 900,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'পানির পাম্প (১.৫ HP)',
          nameEn: 'Water Pump (1.5 HP)',
          defaultWatt: 1400,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'ইলেকট্রিক আয়রন (ইস্ত্রি)',
          nameEn: 'Electric Iron',
          defaultWatt: 1000,
          defaultIsAC: true,
        ),
        AppliancePreset(
          nameBn: 'কাস্টম লোড',
          nameEn: 'Custom Load',
          defaultWatt: 100,
          defaultIsAC: true,
        ),
      ],
    ),
  ];
}
