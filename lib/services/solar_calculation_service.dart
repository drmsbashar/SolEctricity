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

    // ==========================================
    // 🛡️ সুরক্ষাব্যবস্থা হিসাব (Protection Sizing)
    // ==========================================

    // ১. পিভি ডিসি ব্রেকার (Isc * 1.25, স্ট্যান্ডার্ড সাইজ নির্ধারণ)
    final double calculatedPvBreaker = arrayIsc * 1.25;
    final double pvBreakerAmp = _getStandardBreakerRating(calculatedPvBreaker);

    // ২. কন্ট্রোলার টু ব্যাটারি ব্রেকার
    final double chargeControllerBreakerAmp = _getStandardBreakerRating(
      controllerAmpere * 1.15,
    );

    // ৩. ব্যাটারি থেকে ইনভার্টার সর্বোচ্চ কারেন্ট ও ফিউজ
    double batteryFuseAmp = 0.0;
    if (hasAc && params.systemVoltage > 0) {
      final double maxBatteryDischargeCurrent =
          (inverterCapacityVa * 1.25) / (params.systemVoltage * inverterEff);
      batteryFuseAmp = _getStandardFuseRating(maxBatteryDischargeCurrent);
    } else {
      batteryFuseAmp = _getStandardFuseRating(controllerAmpere * 1.25);
    }

    // ৪. ইনভার্টার এসি আউটপুট ব্রেকার (220V AC)
    double acBreakerAmp = 0.0;
    if (hasAc) {
      final double acCurrent = inverterCapacityVa / 220.0;
      acBreakerAmp = _getStandardBreakerRating(acCurrent * 1.25);
    }

    // ৫. কপার ক্যাবল সাইজ নির্ধারণ (mm²)
    final String pvCableSizeMm = _determinePvCableSize(arrayIsc);
    final String batteryCableSizeMm = _determineBatteryCableSize(
      hasAc ? (inverterCapacityVa / params.systemVoltage) : controllerAmpere,
    );

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
      pvBreakerAmp: pvBreakerAmp,
      batteryFuseAmp: batteryFuseAmp,
      chargeControllerBreakerAmp: chargeControllerBreakerAmp,
      acBreakerAmp: acBreakerAmp,
      pvCableSizeMm: pvCableSizeMm,
      batteryCableSizeMm: batteryCableSizeMm,
    );
  }

  // স্ট্যান্ডার্ড ব্রেকার রেটিং (A)
  static double _getStandardBreakerRating(double current) {
    const standards = [
      6.0,
      10.0,
      16.0,
      20.0,
      25.0,
      32.0,
      40.0,
      50.0,
      63.0,
      80.0,
      100.0,
      125.0,
    ];
    for (var rating in standards) {
      if (rating >= current) return rating;
    }
    return (current / 10).ceil() * 10.0;
  }

  // স্ট্যান্ডার্ড ফিউজ রেটিং (A)
  static double _getStandardFuseRating(double current) {
    const standards = [
      30.0,
      40.0,
      50.0,
      60.0,
      80.0,
      100.0,
      125.0,
      150.0,
      200.0,
      250.0,
      300.0,
    ];
    for (var rating in standards) {
      if (rating >= current) return rating;
    }
    return (current / 25).ceil() * 25.0;
  }

  // পিভি তারের সাইজ (কারেন্ট ও ড্রপ বিবেচনায় mm²)
  static String _determinePvCableSize(double isc) {
    if (isc <= 15) return '4.0 mm²';
    if (isc <= 25) return '6.0 mm²';
    if (isc <= 40) return '10.0 mm²';
    return '16.0 mm²';
  }

  // ব্যাটারি তারের সাইজ (উচ্চ ডিসি অ্যাম্পিয়ারের জন্য)
  static String _determineBatteryCableSize(double maxCurrent) {
    if (maxCurrent <= 20) return '6.0 mm²';
    if (maxCurrent <= 40) return '10.0 mm²';
    if (maxCurrent <= 60) return '16.0 mm²';
    if (maxCurrent <= 90) return '25.0 mm²';
    if (maxCurrent <= 130) return '35.0 mm²';
    return '50.0 mm²';
  }
}
