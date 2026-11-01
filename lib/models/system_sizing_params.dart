class SystemSizingParams {
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

  factory SystemSizingParams.defaultForLoad(
    double dailyTotalWh,
    double acPeakWatt,
  ) {
    double recVoltage = 12.0;
    if (dailyTotalWh > 3000 || acPeakWatt > 2500) {
      recVoltage = 48.0;
    } else if (dailyTotalWh > 1500 || acPeakWatt > 1000) {
      recVoltage = 24.0;
    }

    return SystemSizingParams(
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
