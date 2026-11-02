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
    final bool isGridTied = params.systemType == SolarSystemType.gridTied;
    final bool isHybrid = params.systemType == SolarSystemType.hybrid;

    final bool hasAc = dailyAcWh > 0 || acPeakWatt > 0 || isGridTied;
    final bool hasDc =
        dailyDcWh > 0 &&
        !isGridTied; // অন-গ্রিডে সাধারণত সরাসরি ডিসি লোড থাকে না

    final double inverterEff = (params.inverterEfficiency > 0)
        ? (params.inverterEfficiency / 100.0)
        : 0.90;
    final double effectiveAcWh = hasAc ? (dailyAcWh / inverterEff) : 0.0;
    final double totalDailyWh = dailyDcWh + effectiveAcWh;

    final double energyDemandAh = (params.systemVoltage > 0)
        ? (totalDailyWh / params.systemVoltage)
        : 0.0;

    // ১. সৌর প্যানেলের মোট ক্ষমতা হিসাব
    final double batEff = (!isGridTied && params.batteryEfficiency > 0)
        ? (params.batteryEfficiency / 100.0)
        : 1.0; // অন-গ্রিডে ব্যাটারি না থাকায় ব্যাটারি লস ১.০

    final double overallGenEfficiency =
        batEff * bosEfficiency * tempDeratingFactor;

    final double psh = (params.peakSunHours > 0) ? params.peakSunHours : 4.8;
    final double requiredDailyWh = totalDailyWh / overallGenEfficiency;
    final double requiredPvWatt = requiredDailyWh / psh;

    // ২. প্যানেল সিরিজ ও প্যারালাল কনফিগারেশন
    int pvs = 1;
    final double panelVmp = params.panelVmp > 0 ? params.panelVmp : 18.0;

    if (isGridTied) {
      // অন-গ্রিড স্ট্রিং ইনভার্টারের জন্য সাধারণত উচ্চ ভোল্টেজ স্ট্রিং হয় (যেমন: Voc ১৫০V-৫০০V)
      pvs = (panelVmp < 35.0) ? 6 : 4;
    } else if (params.controllerType == 'pwm' && !isHybrid) {
      pvs = math.max(
        1,
        (params.systemVoltage / nominalBatteryBlockVoltage).round(),
      );
      if (panelVmp > 30.0 && params.systemVoltage == 12.0) {
        pvs = 1;
      }
    } else {
      // MPPT বা Hybrid ইনভার্টারের জন্য
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

    // ৩. ব্যাটারি ব্যাংক হিসাব (অন-গ্রিড হলে সম্পূর্ণ শূন্য)
    double totalRequiredBatAh = 0.0;
    int batSeries = 0;
    int batParallel = 0;
    int totalBatteries = 0;

    if (!isGridTied) {
      final double dod = (params.batteryDod > 0)
          ? (params.batteryDod / 100.0)
          : 0.70;

      totalRequiredBatAh = (params.systemVoltage > 0 && dod > 0 && batEff > 0)
          ? ((totalDailyWh * params.autonomyDays) /
                (params.systemVoltage * dod * batEff))
          : 100.0;

      batSeries = math.max(
        1,
        (params.systemVoltage / nominalBatteryBlockVoltage).round(),
      );

      final double unitBatAh = (params.batteryCapacityAh > 0)
          ? params.batteryCapacityAh
          : 100.0;

      batParallel = math.max(1, (totalRequiredBatAh / unitBatAh).ceil());
      totalBatteries = batSeries * batParallel;
    }

    // ৪. চার্জ কন্ট্রোলার হিসাব (অন-গ্রিড হলে প্রযোজ্য নয়)
    double controllerAmpere = 0.0;
    if (!isGridTied) {
      if (params.controllerType == 'pwm' && !isHybrid) {
        controllerAmpere = arrayIsc * 1.25;
      } else {
        controllerAmpere = (totalArrayWatt / params.systemVoltage) * 1.25;
      }
      controllerAmpere = double.parse(controllerAmpere.toStringAsFixed(1));
    }

    // ৫. ইনভার্টার ক্ষমতা নির্ধারণ
    double inverterCapacityVa = 0.0;
    final double pf = (params.inverterPowerFactor > 0)
        ? params.inverterPowerFactor
        : 0.85;

    if (isGridTied) {
      // অন-গ্রিড ইনভার্টার সাধারণত পিভি অ্যারের ক্ষমতা এবং লোডের সর্বোচ্চ মান অনুযায়ী হয়
      final double peakLoadVa = (acPeakWatt > 0) ? (acPeakWatt / pf) : 0.0;
      final double arrayVa = totalArrayWatt / pf;
      inverterCapacityVa = math.max(peakLoadVa * 1.25, arrayVa);
    } else if (hasAc) {
      inverterCapacityVa = (acPeakWatt * 1.25) / pf;
    }
    inverterCapacityVa = double.parse(inverterCapacityVa.toStringAsFixed(0));

    // ==========================================
    // 🛡️ সুরক্ষাব্যবস্থা হিসাব (Protection Sizing)
    // ==========================================
    // ১. পিভি ডিসি ব্রেকার (Isc * 1.25)
    final double calculatedPvBreaker = arrayIsc * 1.25;
    final double pvBreakerAmp = _getStandardBreakerRating(calculatedPvBreaker);

    // ২. কন্ট্রোলার টু ব্যাটারি ব্রেকার
    final double chargeControllerBreakerAmp = !isGridTied
        ? _getStandardBreakerRating(controllerAmpere * 1.15)
        : 0.0;

    // ৩. ব্যাটারি থেকে ইনভার্টার ফিউজ
    double batteryFuseAmp = 0.0;
    if (!isGridTied) {
      if (hasAc && params.systemVoltage > 0) {
        final double maxBatteryDischargeCurrent =
            (inverterCapacityVa * 1.25) / (params.systemVoltage * inverterEff);
        batteryFuseAmp = _getStandardFuseRating(maxBatteryDischargeCurrent);
      } else {
        batteryFuseAmp = _getStandardFuseRating(controllerAmpere * 1.25);
      }
    }

    // ৪. ইনভার্টার এসি আউটপুট ব্রেকার (220V AC)
    double acBreakerAmp = 0.0;
    if (hasAc) {
      final double acCurrent = inverterCapacityVa / 220.0;
      acBreakerAmp = _getStandardBreakerRating(acCurrent * 1.25);
    }

    // ৫. কপার ক্যাবল সাইজ নির্ধারণ (mm²)
    final String pvCableSizeMm = _determinePvCableSize(arrayIsc);
    final String batteryCableSizeMm = !isGridTied
        ? _determineBatteryCableSize(
            hasAc
                ? (inverterCapacityVa / params.systemVoltage)
                : controllerAmpere,
          )
        : 'N/A';

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
      controllerType: isGridTied
          ? 'N/A'
          : (isHybrid ? 'Built-in MPPT' : params.controllerType),
      controllerAmpere: controllerAmpere,
      controllerVoltage: isGridTied ? 0.0 : params.systemVoltage,
      inverterCapacityVa: inverterCapacityVa,
      inverterVoltage: isGridTied ? 220.0 : params.systemVoltage,
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

  static String _determinePvCableSize(double isc) {
    if (isc <= 15) return '4.0 mm²';
    if (isc <= 25) return '6.0 mm²';
    if (isc <= 40) return '10.0 mm²';
    return '16.0 mm²';
  }

  static String _determineBatteryCableSize(double maxCurrent) {
    if (maxCurrent <= 20) return '6.0 mm²';
    if (maxCurrent <= 40) return '10.0 mm²';
    if (maxCurrent <= 60) return '16.0 mm²';
    if (maxCurrent <= 90) return '25.0 mm²';
    if (maxCurrent <= 130) return '35.0 mm²';
    return '50.0 mm²';
  }
}
