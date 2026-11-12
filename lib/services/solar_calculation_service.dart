import 'dart:math' as math;

import '../models/solar_calculation_result.dart';
import '../models/system_sizing_params.dart';

class SolarCalculationService {
  static const double bosEfficiency = 0.85;
  static const double tempDeratingFactor = 0.90;
  static const double nominalBatteryBlockVoltage = 12.0;

  // 🌍 প্যাকিং ফ্যাক্টর ক্যালকুলেশন
  static double calculateDynamicPackingFactor(double latitude) {
    final double absLat = latitude.abs();
    if (absLat <= 15.0) return 0.75;
    if (absLat <= 25.0) return 0.75 - ((absLat - 15.0) / 10.0) * 0.07;
    if (absLat <= 35.0) return 0.68 - ((absLat - 25.0) / 10.0) * 0.08;
    return 0.58;
  }

  // 🌡️ সেল তাপমাত্রা জনিত অপচয় (Temp Derate) ক্যালকুলেশন
  static double calculateTempDerateFactor(double ambientTemp) {
    const double noct = 45.0;
    const double tempCoeff = 0.0035;
    final double cellTemp = ambientTemp + (noct - 20.0);
    if (cellTemp <= 25.0) return 1.0;
    final double loss = (cellTemp - 25.0) * tempCoeff;
    return (1.0 - loss).clamp(0.75, 1.0);
  }

  // 📐 সর্বোত্তম কাত কোণ (Tilt Angle)
  static double calculateOptimalTilt(double latitude) {
    return (latitude.abs() * 0.90).clamp(10.0, 45.0);
  }

  static SolarCalculationResult calculate({
    required double dailyAcWh,
    required double dailyDcWh,
    required double acPeakWatt,
    required SystemSizingParams params,
  }) {
    final bool isGridTied = params.systemType == SolarSystemType.gridTied;
    final bool isHybrid = params.systemType == SolarSystemType.hybrid;

    final bool hasAc = dailyAcWh > 0 || acPeakWatt > 0 || isGridTied;
    final bool hasDc = dailyDcWh > 0 && !isGridTied;

    final double inverterEff = (params.inverterEfficiency > 0)
        ? (params.inverterEfficiency / 100.0)
        : 0.90;
    final double effectiveAcWh = hasAc ? (dailyAcWh / inverterEff) : 0.0;
    final double totalDailyWh = dailyDcWh + effectiveAcWh;

    final double validSysVolt = params.systemVoltage > 0
        ? params.systemVoltage
        : 12.0;

    final double energyDemandAh = (!isGridTied && validSysVolt > 0)
        ? (totalDailyWh / validSysVolt)
        : 0.0;

    final double batEff = (!isGridTied && params.batteryEfficiency > 0)
        ? (params.batteryEfficiency / 100.0)
        : 1.0;

    final double overallGenEfficiency =
        batEff * bosEfficiency * tempDeratingFactor;

    final double psh = (params.peakSunHours > 0) ? params.peakSunHours : 4.8;
    final double requiredDailyWh = totalDailyWh / overallGenEfficiency;
    final double requiredPvWatt = requiredDailyWh / psh;

    final int minPanels = (params.panelPmax > 0)
        ? (requiredPvWatt / params.panelPmax).ceil()
        : 1;

    int pvs = 1;
    final double panelVmp = params.panelVmp > 0 ? params.panelVmp : 18.0;

    if (isGridTied) {
      final int idealGridSeries = (panelVmp < 35.0) ? 6 : 4;
      pvs = math.max(1, math.min(minPanels, idealGridSeries));
    } else if (params.controllerType == 'pwm' && !isHybrid) {
      pvs = math.max(1, (validSysVolt / nominalBatteryBlockVoltage).round());
      if (panelVmp > 30.0 && validSysVolt == 12.0) {
        pvs = 1;
      }
    } else {
      if (validSysVolt == 12.0) {
        pvs = (panelVmp < 25.0) ? 2 : 1;
      } else if (validSysVolt == 24.0) {
        pvs = (panelVmp < 30.0) ? 2 : 1;
      } else {
        pvs = (panelVmp < 25.0) ? 4 : 2;
      }
      pvs = math.max(1, math.min(minPanels, pvs));
    }

    int pvp = (minPanels / pvs).ceil();
    if (pvp < 1) pvp = 1;

    final int totalPanels = pvs * pvp;
    final double totalArrayWatt = totalPanels * params.panelPmax;
    final double arrayVmp = pvs * panelVmp;
    final double arrayVoc = pvs * params.panelVoc;
    final double arrayImp = pvp * params.panelImp;
    final double arrayIsc = pvp * params.panelIsc;

    double totalRequiredBatAh = 0.0;
    int batSeries = 0;
    int batParallel = 0;
    int totalBatteries = 0;

    if (!isGridTied) {
      final double dod = (params.batteryDod > 0)
          ? (params.batteryDod / 100.0)
          : 0.70;

      totalRequiredBatAh = (validSysVolt > 0 && dod > 0 && batEff > 0)
          ? ((totalDailyWh * params.autonomyDays) /
                (validSysVolt * dod * batEff))
          : 100.0;

      batSeries = math.max(
        1,
        (validSysVolt / nominalBatteryBlockVoltage).round(),
      );

      final double unitBatAh = (params.batteryCapacityAh > 0)
          ? params.batteryCapacityAh
          : 100.0;

      batParallel = math.max(1, (totalRequiredBatAh / unitBatAh).ceil());
      totalBatteries = batSeries * batParallel;
    }

    double controllerAmpere = 0.0;
    if (!isGridTied) {
      if (params.controllerType == 'pwm' && !isHybrid) {
        controllerAmpere = arrayIsc * 1.25;
      } else {
        controllerAmpere = (totalArrayWatt / validSysVolt) * 1.25;
      }
      controllerAmpere = double.parse(controllerAmpere.toStringAsFixed(1));
    }

    double inverterCapacityVa = 0.0;
    final double pf = (params.inverterPowerFactor > 0)
        ? params.inverterPowerFactor
        : 0.85;

    if (isGridTied) {
      // অন-গ্রিড আর্কিটেকচারে আদর্শ ডিসি/এসি রেশিও ১.১৫
      inverterCapacityVa = (totalArrayWatt / 1.15);
    } else if (hasAc) {
      inverterCapacityVa = (acPeakWatt * 1.25) / pf;
    }
    inverterCapacityVa = double.parse(inverterCapacityVa.toStringAsFixed(0));

    final double calculatedPvBreaker = arrayIsc * 1.25;
    final double pvBreakerAmp = _getStandardBreakerRating(calculatedPvBreaker);

    final double chargeControllerBreakerAmp = (!isGridTied && !isHybrid)
        ? _getStandardBreakerRating(controllerAmpere * 1.15)
        : 0.0;

    double maxBatteryCurrent = 0.0;
    double batteryFuseAmp = 0.0;
    if (!isGridTied) {
      if (hasAc && validSysVolt > 0) {
        // ইনভার্টার অপচয় ও পাওয়ার ফ্যাক্টর সমন্বিত প্রকৃত ডিসি কারেন্ট
        final double maxDischargeCurrent =
            (inverterCapacityVa * 1.25) / (validSysVolt * inverterEff);
        batteryFuseAmp = _getStandardFuseRating(maxDischargeCurrent);
        maxBatteryCurrent = maxDischargeCurrent;
      } else {
        batteryFuseAmp = _getStandardFuseRating(controllerAmpere * 1.25);
        maxBatteryCurrent = controllerAmpere;
      }
    }

    double acBreakerAmp = 0.0;
    if (hasAc) {
      final double acCurrent = inverterCapacityVa / 220.0;
      acBreakerAmp = _getStandardBreakerRating(acCurrent * 1.25);
    }

    final String pvCableSizeMm = _determinePvCableSize(arrayIsc);
    final String batteryCableSizeMm = !isGridTied
        ? _determineBatteryCableSize(maxBatteryCurrent)
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
      controllerVoltage: isGridTied ? 0.0 : validSysVolt,
      inverterCapacityVa: inverterCapacityVa,
      inverterVoltage: isGridTied ? 220.0 : validSysVolt,
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

class ModuleDimensions {
  final double lengthM;
  final double widthM;

  const ModuleDimensions({required this.lengthM, required this.widthM});
}

extension SolarGeometryEngine on SolarCalculationService {
  static ModuleDimensions getModuleDimensions(int watt) {
    if (watt <= 50) return const ModuleDimensions(lengthM: 0.70, widthM: 0.53);
    if (watt <= 80) return const ModuleDimensions(lengthM: 0.85, widthM: 0.67);
    if (watt <= 100) return const ModuleDimensions(lengthM: 1.02, widthM: 0.67);
    if (watt <= 150) return const ModuleDimensions(lengthM: 1.20, widthM: 0.67);
    if (watt <= 200) return const ModuleDimensions(lengthM: 1.50, widthM: 0.67);
    if (watt <= 250) return const ModuleDimensions(lengthM: 1.65, widthM: 0.99);
    if (watt <= 330) return const ModuleDimensions(lengthM: 1.95, widthM: 0.99);
    if (watt <= 400) return const ModuleDimensions(lengthM: 2.00, widthM: 1.00);
    if (watt <= 450) return const ModuleDimensions(lengthM: 2.10, widthM: 1.04);
    if (watt <= 550) return const ModuleDimensions(lengthM: 2.27, widthM: 1.13);
    if (watt <= 620) return const ModuleDimensions(lengthM: 2.38, widthM: 1.13);
    return const ModuleDimensions(lengthM: 2.45, widthM: 1.15);
  }

  static double calculateRowPitch({
    required double latitude,
    required double tiltAngleDeg,
    required double moduleLengthM,
  }) {
    final double absLat = latitude.abs();
    final double solarAltitudeDeg = (90.0 - absLat - 23.45).clamp(10.0, 75.0);

    final double tiltRad = tiltAngleDeg * (math.pi / 180.0);
    final double altRad = solarAltitudeDeg * (math.pi / 180.0);

    final double panelHorizontalSpan = moduleLengthM * math.cos(tiltRad);
    final double panelVerticalHeight = moduleLengthM * math.sin(tiltRad);
    final double shadowLength = panelVerticalHeight / math.tan(altRad);

    return panelHorizontalSpan + shadowLength;
  }

  static Map<String, dynamic> calculateDiscreteLayout({
    required double northSouthSpanM,
    required double eastWestSpanM,
    required double netUsableAreaSqM,
    required double latitude,
    required int moduleWatt,
  }) {
    final dims = getModuleDimensions(moduleWatt);
    final tilt = SolarCalculationService.calculateOptimalTilt(latitude);
    final tiltRad = tilt * (math.pi / 180.0);
    final double singlePanelSpanNS = dims.lengthM * math.cos(tiltRad);

    final pitch = calculateRowPitch(
      latitude: latitude,
      tiltAngleDeg: tilt,
      moduleLengthM: dims.lengthM,
    );

    int possibleRows = 0;
    if (pitch > 0 && northSouthSpanM >= pitch) {
      possibleRows = (northSouthSpanM / pitch).floor();
    }

    if (possibleRows < 1 && northSouthSpanM >= singlePanelSpanNS) {
      possibleRows = 1;
    }

    int possibleCols = (dims.widthM > 0)
        ? (eastWestSpanM / dims.widthM).floor()
        : 0;

    int totalDiscretePanels = possibleRows * possibleCols;

    final double unitRequiredArea = (possibleRows > 1)
        ? (pitch * dims.widthM)
        : (singlePanelSpanNS * dims.widthM);

    if (unitRequiredArea > 0) {
      final int maxPanelsByArea = (netUsableAreaSqM / unitRequiredArea).floor();
      if (totalDiscretePanels > maxPanelsByArea && maxPanelsByArea > 0) {
        totalDiscretePanels = maxPanelsByArea;
        if (possibleCols > 0) {
          possibleRows = (totalDiscretePanels / possibleCols).floor();
          if (possibleRows < 1) possibleRows = 1;
        }
      }
    }

    const double maxHomeCapacityKwp = 50.0;
    double actualKwp = (totalDiscretePanels * moduleWatt) / 1000.0;
    if (actualKwp > maxHomeCapacityKwp) {
      totalDiscretePanels = (maxHomeCapacityKwp * 1000 / moduleWatt).floor();
      actualKwp = (totalDiscretePanels * moduleWatt) / 1000.0;
      if (possibleCols > 0) {
        possibleRows = (totalDiscretePanels / possibleCols).floor();
      }
    }

    return {
      'rows': possibleRows,
      'cols': possibleCols,
      'pitchM': pitch,
      'totalPanels': totalDiscretePanels,
      'actualKwp': actualKwp,
      'tiltDeg': tilt,
      'isSingleRow': possibleRows == 1,
    };
  }

  static int findOptimalModuleWatt({
    required double northSouthSpanM,
    required double eastWestSpanM,
    required double netUsableAreaSqM,
    required double latitude,
  }) {
    const candidateWatts = [
      700,
      620,
      550,
      450,
      400,
      330,
      250,
      200,
      150,
      100,
      80,
      50,
    ];
    int bestWatt = 550;
    double maxKwp = 0.0;
    int maxPanels = 0;

    for (final watt in candidateWatts) {
      final res = calculateDiscreteLayout(
        northSouthSpanM: northSouthSpanM,
        eastWestSpanM: eastWestSpanM,
        netUsableAreaSqM: netUsableAreaSqM,
        latitude: latitude,
        moduleWatt: watt,
      );

      final int panels = res['totalPanels'] as int;
      final double kwp = res['actualKwp'] as double;

      if (kwp > maxKwp) {
        maxKwp = kwp;
        maxPanels = panels;
        bestWatt = watt;
      }
    }

    if (maxPanels == 0) {
      for (final watt in candidateWatts.reversed) {
        final res = calculateDiscreteLayout(
          northSouthSpanM: northSouthSpanM,
          eastWestSpanM: eastWestSpanM,
          netUsableAreaSqM: netUsableAreaSqM,
          latitude: latitude,
          moduleWatt: watt,
        );
        if ((res['totalPanels'] as int) > 0) {
          return watt;
        }
      }
    }

    return bestWatt;
  }
}
