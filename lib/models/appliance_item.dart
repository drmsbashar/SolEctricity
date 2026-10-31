class ApplianceItem {
  final String id;
  final String categoryKey; // যেমন: 'light', 'fan', 'tv' ইত্যাদি
  String nameBn;
  String nameEn;
  bool isAC;
  double watt;
  int quantity;
  double hoursPerDay;

  ApplianceItem({
    required this.id,
    required this.categoryKey,
    required this.nameBn,
    required this.nameEn,
    required this.isAC,
    required this.watt,
    required this.quantity,
    required this.hoursPerDay,
  });

  // সংযুক্ত ক্ষমতা (Connected Power in Watts)
  double get totalWatt => watt * quantity;

  // দৈনিক শক্তি খরচ (Daily Energy in Watt-hours)
  double get dailyEnergyWh => totalWatt * hoursPerDay;
}

// সামগ্রিক ক্যালকুলেশন ইঞ্জিন
class LoadCalculationEngine {
  final List<ApplianceItem> items;

  LoadCalculationEngine(this.items);

  // এসি লোডের তালিকা
  List<ApplianceItem> get acItems => items.where((item) => item.isAC).toList();

  // ডিসি লোডের তালিকা
  List<ApplianceItem> get dcItems => items.where((item) => !item.isAC).toList();

  // ১. মোট ডিসি দৈনিক চাহিদা: ΣLdc (Wh/day)
  double get sigmaLdc =>
      dcItems.fold(0.0, (sum, item) => sum + item.dailyEnergyWh);

  // ২. মোট এসি দৈনিক চাহিদা: ΣLac (Wh/day)
  double get sigmaLac =>
      acItems.fold(0.0, (sum, item) => sum + item.dailyEnergyWh);

  // সর্বমোট দৈনিক শক্তি চাহিদা: ΣLtotal = ΣLac + ΣLdc (Wh/day)
  double get sigmaLtotal => sigmaLac + sigmaLdc;

  // ৩. ইনভার্টারের জন্য মোট এসি পিক লোড: ΣLa (Watts)
  double get sigmaLa => acItems.fold(0.0, (sum, item) => sum + item.totalWatt);

  // প্রস্তাবিত ইনভার্টারের সাইজ (1.25 সেফটি ফ্যাক্টর ধরে)
  double get recommendedInverterWatt => sigmaLa * 1.25;

  // এসি এনার্জির শতকরা অনুপাত
  double get acPercentage =>
      sigmaLtotal == 0 ? 0 : (sigmaLac / sigmaLtotal) * 100;

  // ডিসি এনার্জির শতকরা অনুপাত
  double get dcPercentage =>
      sigmaLtotal == 0 ? 0 : (sigmaLdc / sigmaLtotal) * 100;

  // কোনো নির্দিষ্ট ক্যাটাগরিতে মোট কয়টি আইটেম যোগ হয়েছে (ব্যাজের জন্য)
  int getCountByCategory(String categoryKey) {
    return items.where((item) => item.categoryKey == categoryKey).length;
  }
}
