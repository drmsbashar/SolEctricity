import 'dart:math' as math;

import '../models/system_sizing_params.dart';
import '../models/solar_calculation_result.dart';

class SolarCalculationService {
  static const double bosEfficiency = 0.85;
  static const double tempDeratingFactor = 0.90;
  static const double nominalBatteryBlockVoltage = 12.0;

  static SolarCalculationResult calculate({
    required double dailyAcWh,
    required double dailyDcWh,
    required double acPeakWatt,
    required SystemSizingParams params,
  }) {
    final bool hasAc = dailyAcWh > 0 || acPeakWatt > 0;
    final bool hasDc = dailyDcWh > 0;

    final double inverterEff = (params.inverterEfficiency > 0)
        ? (params.inverterEfficiency / 100.0)
        : 0.90;
    final double effectiveAcWh = hasAc ? (dailyAcWh / inverterEff) : 0.0;
    final double totalDailyWh = dailyDcWh + effectiveAcWh;

    final double energyDemandAh = (params.systemVoltage > 0)
        ? (totalDailyWh / params.systemVoltage)
        : 0.0;

    final double batEff = (params.batteryEfficiency > 0)
        ? (params.batteryEfficiency / 100.0)
        : 0.85;
    final double overallGenEfficiency =
        batEff * bosEfficiency * tempDeratingFactor;

    final double psh = (params.peakSunHours > 0) ? params.peakSunHours : 4.5;
    final double requiredDailyWh = totalDailyWh / overallGenEfficiency;
    final double requiredPvWatt = requiredDailyWh / psh;

    int pvs = 1;
    final double panelVmp = params.panelVmp > 0 ? params.panelVmp : 18.0;

    if (params.controllerType == 'pwm') {
      pvs = math.max(
        1,
        (params.systemVoltage / nominalBatteryBlockVoltage).round(),
      );
      if (panelVmp > 30.0 && params.systemVoltage == 12.0) {
        pvs = 1;
      }
    } else {
      if (params.systemVoltage == 12.0) {
        pvs = (panelVmp < 25.0) ? 2 : 1;
      } else if (params.systemVoltage == 24.0) {
        pvs = (panelVmp < 25.0) ? 2 : 2;
      } else {
        pvs = (panelVmp < 25.0) ? 4 : 3;
      }
    }

    final int minPanels = (params.panelPmax > 0)
        ? (requiredPvWatt / params.panelPmax).ceil()
        : 1;

    int pvp = (minPanels / pvs).ceil();
    if (pvp < 1) pvp = 1;

    final int totalPanels = pvs * pvp;
    final double totalArrayWatt = totalPanels * params.panelPmax;

    final double arrayVmp = pvs * panelVmp;
    final double arrayVoc = pvs * params.panelVoc;
    final double arrayImp = pvp * params.panelImp;
    final double arrayIsc = pvp * params.panelIsc;

    final double dod = (params.batteryDod > 0)
        ? (params.batteryDod / 100.0)
        : 0.70;
    final double totalRequiredBatAh =
        (params.systemVoltage > 0 && dod > 0 && batEff > 0)
        ? ((totalDailyWh * params.autonomyDays) /
              (params.systemVoltage * dod * batEff))
        : 100.0;

    final int batSeries = math.max(
      1,
      (params.systemVoltage / nominalBatteryBlockVoltage).round(),
    );
    final double unitBatAh = (params.batteryCapacityAh > 0)
        ? params.batteryCapacityAh
        : 100.0;
    final int batParallel = math.max(
      1,
      (totalRequiredBatAh / unitBatAh).ceil(),
    );
    final int totalBatteries = batSeries * batParallel;

    double controllerAmpere = 0.0;
    if (params.controllerType == 'pwm') {
      controllerAmpere = arrayIsc * 1.25;
    } else {
      controllerAmpere = (totalArrayWatt / params.systemVoltage) * 1.25;
    }
    controllerAmpere = double.parse(controllerAmpere.toStringAsFixed(1));

    double inverterCapacityVa = 0.0;
    if (hasAc) {
      final double pf = (params.inverterPowerFactor > 0)
          ? params.inverterPowerFactor
          : 0.85;
      inverterCapacityVa = (acPeakWatt * 1.25) / pf;
      inverterCapacityVa = double.parse(inverterCapacityVa.toStringAsFixed(0));
    }

    return SolarCalculationResult(
      dailyAcWh: dailyAcWh,
      dailyDcWh: dailyDcWh,
      effectiveAcWh: effectiveAcWh,
      totalDailyWh: totalDailyWh,
      energyDemandAh: energyDemandAh,
      requiredPvWatt: requiredPvWatt,
      totalPanels: totalPanels,
      panelsSeries: pvs,
      panelsParallel: pvp,
      totalArrayWatt: totalArrayWatt,
      arrayVmp: arrayVmp,
      arrayVoc: arrayVoc,
      arrayImp: arrayImp,
      arrayIsc: arrayIsc,
      batteryCapacityAh: totalRequiredBatAh,
      batteriesSeries: batSeries,
      batteriesParallel: batParallel,
      totalBatteries: totalBatteries,
      controllerType: params.controllerType,
      controllerAmpere: controllerAmpere,
      controllerVoltage: params.systemVoltage,
      inverterCapacityVa: inverterCapacityVa,
      inverterVoltage: params.systemVoltage,
      hasAcLoad: hasAc,
      hasDcLoad: hasDc,
    );
  }
}
