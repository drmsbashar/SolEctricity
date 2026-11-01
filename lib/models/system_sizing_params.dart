enum SolarSystemType {
  offGrid, // অফ-গ্রিড (কন্ট্রোলার + ব্যাটারি + ইনভার্টার)
  hybrid, // হাইব্রিড (বিল্ট-ইন কন্ট্রোলারযুক্ত ইনভার্টার + ব্যাটারি + গ্রিড ব্যাকআপ)
  gridTied, // গ্রিড-টাই / অন-গ্রিড (ব্যাটারিহীন নেট-মিটারিং সিস্টেম)
}

class SystemSizingParams {
  final SolarSystemType systemType;
  double peakSunHours;
  double systemVoltage;

  // প্যানেল স্পেসিফিকেশন
  double panelPmax;
  double panelVoc;
  double panelImp;
  double panelIsc;

  // ব্যাটারি স্পেসিফিকেশন
  double batteryCapacityAh;
  double batteryDod;
  double batteryEfficiency;
  int autonomyDays;

  // কন্ট্রোলার ও ইনভার্টার
  String controllerType; // 'pwm' অথবা 'mppt'
  double inverterEfficiency;
  double inverterPowerFactor;

  SystemSizingParams({
    this.systemType = SolarSystemType.offGrid,
    required this.peakSunHours,
    required this.systemVoltage,
    required this.panelPmax,
    required this.panelVoc,
    required this.panelImp,
    required this.panelIsc,
    required this.batteryCapacityAh,
    required this.batteryDod,
    required this.batteryEfficiency,
    required this.autonomyDays,
    this.controllerType = 'mppt',
    this.inverterEfficiency = 90.0,
    this.inverterPowerFactor = 0.85,
  });

  // Vmp স্বয়ংক্রিয় ক্যালকুলেশন
  double get panelVmp => (panelImp > 0)
      ? double.parse((panelPmax / panelImp).toStringAsFixed(2))
      : 0.0;

  // স্টেট আপডেটের জন্য copyWith মেথড
  SystemSizingParams copyWith({
    SolarSystemType? systemType,
    double? peakSunHours,
    double? systemVoltage,
    double? panelPmax,
    double? panelVoc,
    double? panelImp,
    double? panelIsc,
    double? batteryCapacityAh,
    double? batteryDod,
    double? batteryEfficiency,
    int? autonomyDays,
    String? controllerType,
    double? inverterEfficiency,
    double? inverterPowerFactor,
  }) {
    return SystemSizingParams(
      systemType: systemType ?? this.systemType,
      peakSunHours: peakSunHours ?? this.peakSunHours,
      systemVoltage: systemVoltage ?? this.systemVoltage,
      panelPmax: panelPmax ?? this.panelPmax,
      panelVoc: panelVoc ?? this.panelVoc,
      panelImp: panelImp ?? this.panelImp,
      panelIsc: panelIsc ?? this.panelIsc,
      batteryCapacityAh: batteryCapacityAh ?? this.batteryCapacityAh,
      batteryDod: batteryDod ?? this.batteryDod,
      batteryEfficiency: batteryEfficiency ?? this.batteryEfficiency,
      autonomyDays: autonomyDays ?? this.autonomyDays,
      controllerType: controllerType ?? this.controllerType,
      inverterEfficiency: inverterEfficiency ?? this.inverterEfficiency,
      inverterPowerFactor: inverterPowerFactor ?? this.inverterPowerFactor,
    );
  }

  factory SystemSizingParams.defaultForLoad(
    double dailyTotalWh,
    double acPeakWatt, {
    SolarSystemType systemType = SolarSystemType.offGrid,
  }) {
    double recVoltage = 12.0;
    if (dailyTotalWh > 3000 || acPeakWatt > 2500) {
      recVoltage = 48.0;
    } else if (dailyTotalWh > 1500 || acPeakWatt > 1000) {
      recVoltage = 24.0;
    }

    return SystemSizingParams(
      systemType: systemType,
      peakSunHours: 4.8,
      systemVoltage: recVoltage,
      panelPmax: 150.0,
      panelVoc: 22.70,
      panelImp: 8.20,
      panelIsc: 8.80,
      batteryCapacityAh: 150.0,
      batteryDod: 70.0,
      batteryEfficiency: 85.0,
      autonomyDays: 1,
      controllerType: 'mppt',
      inverterEfficiency: 90.0,
      inverterPowerFactor: 0.85,
    );
  }
}
