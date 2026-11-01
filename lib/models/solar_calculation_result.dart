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
  });
}
