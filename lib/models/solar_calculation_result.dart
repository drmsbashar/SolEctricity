class SolarCalculationResult {
  final double dailyAcWh;
  final double dailyDcWh;
  final double effectiveAcWh;
  final double totalDailyWh;
  final double energyDemandAh;

  final double requiredPvWatt;
  final int totalPanels;
  final int panelsSeries;
  final int panelsParallel;
  final double totalArrayWatt;
  final double arrayVmp;
  final double arrayVoc;
  final double arrayImp;
  final double arrayIsc;

  final double batteryCapacityAh;
  final int batteriesSeries;
  final int batteriesParallel;
  final int totalBatteries;

  final String controllerType;
  final double controllerAmpere;
  final double controllerVoltage;
  final double inverterCapacityVa;
  final double inverterVoltage;

  final bool hasAcLoad;
  final bool hasDcLoad;

  // 🛡️ নতুন যুক্ত সুরক্ষাব্যবস্থা ও তারের প্যারামিটার
  final double pvBreakerAmp; // সোলার পিভি ডিসি ব্রেকার (DC MCB)
  final double batteryFuseAmp; // ব্যাটারি ব্যাংক ডিসি ফিউজ (DC Fuse)
  final double chargeControllerBreakerAmp; // কন্ট্রোলার টু ব্যাটারি ব্রেকার
  final double acBreakerAmp; // ইনভার্টার এসি আউটপুট ব্রেকার (AC MCB)
  final String pvCableSizeMm; // প্যানেল থেকে কন্ট্রোলার তারের সাইজ (mm²)
  final String batteryCableSizeMm; // ব্যাটারি থেকে ইনভার্টার তারের সাইজ (mm²)

  SolarCalculationResult({
    required this.dailyAcWh,
    required this.dailyDcWh,
    required this.effectiveAcWh,
    required this.totalDailyWh,
    required this.energyDemandAh,
    required this.requiredPvWatt,
    required this.totalPanels,
    required this.panelsSeries,
    required this.panelsParallel,
    required this.totalArrayWatt,
    required this.arrayVmp,
    required this.arrayVoc,
    required this.arrayImp,
    required this.arrayIsc,
    required this.batteryCapacityAh,
    required this.batteriesSeries,
    required this.batteriesParallel,
    required this.totalBatteries,
    required this.controllerType,
    required this.controllerAmpere,
    required this.controllerVoltage,
    required this.inverterCapacityVa,
    required this.inverterVoltage,
    required this.hasAcLoad,
    required this.hasDcLoad,
    required this.pvBreakerAmp,
    required this.batteryFuseAmp,
    required this.chargeControllerBreakerAmp,
    required this.acBreakerAmp,
    required this.pvCableSizeMm,
    required this.batteryCableSizeMm,
  });
}
