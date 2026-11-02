import 'package:flutter/material.dart';

import '../../models/solar_calculation_result.dart';
import '../../models/system_sizing_params.dart';

// ১. মূল ক্যানভাস ওয়্যারিং পেইন্টার (অ্যাডাপ্টিভ আর্কিটেকচার)
class SolarRealisticWiringPainter extends CustomPainter {
  final SolarCalculationResult result;
  final SystemSizingParams params;
  final bool isBangla;

  SolarRealisticWiringPainter({
    required this.result,
    required this.params,
    required this.isBangla,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pDcPos = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    final pDcNeg = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    final pAcPhase = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    final pAcNeutral = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    final pGridLive = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    switch (params.systemType) {
      case SolarSystemType.gridTied:
        _paintGridTiedDiagram(
          canvas,
          pDcPos,
          pDcNeg,
          pAcPhase,
          pAcNeutral,
          pGridLive,
        );
        break;
      case SolarSystemType.hybrid:
        _paintHybridDiagram(
          canvas,
          pDcPos,
          pDcNeg,
          pAcPhase,
          pAcNeutral,
          pGridLive,
        );
        break;
      case SolarSystemType.offGrid:
        _paintOffGridDiagram(canvas, pDcPos, pDcNeg, pAcPhase, pAcNeutral);
        break;
    }
  }

  // =========================================================================
  // ⚡ ১. অফ-গ্রিড সিস্টেম ওয়্যারিং (Off-Grid)
  // =========================================================================
  void _paintOffGridDiagram(
    Canvas canvas,
    Paint pDcPos,
    Paint pDcNeg,
    Paint pAcPhase,
    Paint pAcNeutral,
  ) {
    const pvRect = Rect.fromLTWH(30, 60, 220, 180);
    const controllerRect = Rect.fromLTWH(360, 70, 220, 160);
    const batteryRect = Rect.fromLTWH(360, 390, 220, 160);
    const inverterRect = Rect.fromLTWH(660, 390, 210, 160);
    const dcLoadRect = Rect.fromLTWH(690, 70, 190, 140);
    const acLoadRect = Rect.fromLTWH(960, 390, 180, 160);

    // ওয়্যারিং রুট
    _drawPvWires(canvas, pvRect, controllerRect, pDcPos, pDcNeg);
    _drawControllerToBatteryWires(
      canvas,
      controllerRect,
      batteryRect,
      pDcPos,
      pDcNeg,
    );

    if (result.hasAcLoad) {
      _drawBatteryToInverterWires(
        canvas,
        batteryRect,
        inverterRect,
        pDcPos,
        pDcNeg,
      );
      _drawInverterToAcWires(
        canvas,
        inverterRect,
        acLoadRect,
        pAcPhase,
        pAcNeutral,
      );
      _drawRealisticAcLoad(canvas, acLoadRect);
      _drawRealisticInverter(
        canvas,
        inverterRect,
        title: isBangla ? 'অফ-গ্রিড ইনভার্টার' : 'Off-grid Inverter',
      );
    }

    if (result.hasDcLoad) {
      _drawDcLoadWires(canvas, controllerRect, dcLoadRect, pDcPos, pDcNeg);
      _drawRealisticDcLoad(canvas, dcLoadRect);
    }

    // বক্স রেন্ডারিং
    _drawCleanPvArray(canvas, pvRect);
    _drawCleanController(canvas, controllerRect);
    _drawRealisticBatteryBank(canvas, batteryRect);
  }

  // =========================================================================
  // 🔄 ২. হাইব্রিড সিস্টেম ওয়্যারিং (Hybrid Architecture)
  // =========================================================================
  void _paintHybridDiagram(
    Canvas canvas,
    Paint pDcPos,
    Paint pDcNeg,
    Paint pAcPhase,
    Paint pAcNeutral,
    Paint pGridLive,
  ) {
    const pvRect = Rect.fromLTWH(30, 70, 220, 180);
    const hybridInvRect = Rect.fromLTWH(
      380,
      150,
      260,
      260,
    ); // অল-ইন-ওয়ান হাইব্রিড ইনভার্টার
    const batteryRect = Rect.fromLTWH(30, 360, 220, 160); // পিভির নিচে ব্যাটারি
    const acLoadRect = Rect.fromLTWH(780, 80, 200, 150); // হোম এসি লোড
    const gridRect = Rect.fromLTWH(780, 330, 200, 150); // জাতীয় গ্রিড

    // ১. পিভি টু হাইব্রিড ইনভার্টার লাইন
    final pvPos = Path()
      ..moveTo(pvRect.right, pvRect.top + 50)
      ..lineTo(hybridInvRect.left, hybridInvRect.top + 45);
    final pvNeg = Path()
      ..moveTo(pvRect.right, pvRect.top + 80)
      ..lineTo(hybridInvRect.left, hybridInvRect.top + 75);
    canvas.drawPath(pvPos, pDcPos);
    canvas.drawPath(pvNeg, pDcNeg);
    final double midPvX = (pvRect.right + hybridInvRect.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midPvX, pvRect.top + 30),
      'DC MCB ≥ ${result.pvBreakerAmp.toInt()}A',
    );
    _drawLabel(
      canvas,
      Offset(midPvX, pvRect.top + 98),
      '${result.pvCableSizeMm} Cu',
    );

    // ২. ব্যাটারি টু হাইব্রিড ইনভার্টার লাইন
    final batPos = Path()
      ..moveTo(batteryRect.right, batteryRect.top + 50)
      ..lineTo(hybridInvRect.left, hybridInvRect.top + 160);
    final batNeg = Path()
      ..moveTo(batteryRect.right, batteryRect.top + 90)
      ..lineTo(hybridInvRect.left, hybridInvRect.top + 190);
    canvas.drawPath(batPos, pDcPos);
    canvas.drawPath(batNeg, pDcNeg);
    final double midBatX = (batteryRect.right + hybridInvRect.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midBatX, batteryRect.top + 45),
      'DC FUSE ≥ ${result.batteryFuseAmp.toInt()}A',
    );
    _drawLabel(
      canvas,
      Offset(midBatX, batteryRect.top + 108),
      '${result.batteryCableSizeMm} Cable',
    );

    // ৩. হাইব্রিড ইনভার্টার টু এসি লোড
    final acP = Path()
      ..moveTo(hybridInvRect.right, hybridInvRect.top + 50)
      ..lineTo(acLoadRect.left, acLoadRect.top + 50);
    final acN = Path()
      ..moveTo(hybridInvRect.right, hybridInvRect.top + 80)
      ..lineTo(acLoadRect.left, acLoadRect.top + 80);
    canvas.drawPath(acP, pAcPhase);
    canvas.drawPath(acN, pAcNeutral);
    final double midAcX = (hybridInvRect.right + acLoadRect.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midAcX, acLoadRect.top + 30),
      'AC MCB ≥ ${result.acBreakerAmp.toInt()}A',
    );

    // ৪. হাইব্রিড ইনভার্টার টু ন্যাশনাল গ্রিড (দ্বিমুখী ব্যাকআপ লাইন)
    final gridPath = Path()
      ..moveTo(hybridInvRect.right, hybridInvRect.top + 180)
      ..lineTo(gridRect.left, gridRect.top + 60);
    canvas.drawPath(gridPath, pGridLive);
    final double midGridX = (hybridInvRect.right + gridRect.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midGridX, gridRect.top + 30),
      isBangla ? 'গ্রিড সংযোগ' : 'Grid Connection',
    );

    // কম্পোনেন্ট বক্সসমূহ আঁকা
    _drawCleanPvArray(canvas, pvRect);
    _drawRealisticBatteryBank(canvas, batteryRect);
    _drawHybridInverterBox(canvas, hybridInvRect);
    _drawRealisticAcLoad(canvas, acLoadRect);
    _drawNationalGridBox(canvas, gridRect);
  }

  // =========================================================================
  // 🌐 ৩. গ্রিড-টাই / অন-গ্রিড ওয়্যারিং (Grid-Tied Net Metering)
  // =========================================================================
  void _paintGridTiedDiagram(
    Canvas canvas,
    Paint pDcPos,
    Paint pDcNeg,
    Paint pAcPhase,
    Paint pAcNeutral,
    Paint pGridLive,
  ) {
    const pvRect = Rect.fromLTWH(30, 180, 220, 180);
    const stringInvRect = Rect.fromLTWH(
      340,
      180,
      220,
      180,
    ); // অন-গ্রিড স্ট্রিং ইনভার্টার
    const netMeterRect = Rect.fromLTWH(
      640,
      190,
      190,
      160,
    ); // দ্বিমুখী নেট মিটার
    const acLoadRect = Rect.fromLTWH(920, 70, 190, 150); // হোম এসি লোড
    const gridRect = Rect.fromLTWH(920, 310, 190, 150); // জাতীয় পাওয়ার গ্রিড

    // ১. পিভি টু স্ট্রিং ইনভার্টার
    final pvPos = Path()
      ..moveTo(pvRect.right, pvRect.top + 50)
      ..lineTo(stringInvRect.left, stringInvRect.top + 50);
    final pvNeg = Path()
      ..moveTo(pvRect.right, pvRect.top + 80)
      ..lineTo(stringInvRect.left, stringInvRect.top + 80);
    canvas.drawPath(pvPos, pDcPos);
    canvas.drawPath(pvNeg, pDcNeg);
    final double midPvX = (pvRect.right + stringInvRect.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midPvX, pvRect.top + 30),
      'DC MCB ≥ ${result.pvBreakerAmp.toInt()}A',
    );
    _drawLabel(
      canvas,
      Offset(midPvX, pvRect.top + 98),
      '${result.pvCableSizeMm} Cu',
    );

    // ২. স্ট্রিং ইনভার্টার টু নেট মিটার (এসি আউটপুট)
    final invAcP = Path()
      ..moveTo(stringInvRect.right, stringInvRect.top + 50)
      ..lineTo(netMeterRect.left, netMeterRect.top + 50);
    final invAcN = Path()
      ..moveTo(stringInvRect.right, stringInvRect.top + 80)
      ..lineTo(netMeterRect.left, netMeterRect.top + 80);
    canvas.drawPath(invAcP, pAcPhase);
    canvas.drawPath(invAcN, pAcNeutral);
    final double midInvX = (stringInvRect.right + netMeterRect.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midInvX, netMeterRect.top + 30),
      'AC MCB ≥ ${result.acBreakerAmp.toInt()}A',
    );

    // ৩. নেট মিটার টু হোম এসি লোড
    final meterToLoad = Path()
      ..moveTo(netMeterRect.right, netMeterRect.top + 45)
      ..lineTo(netMeterRect.right + 35, netMeterRect.top + 45)
      ..lineTo(netMeterRect.right + 35, acLoadRect.top + 70)
      ..lineTo(acLoadRect.left, acLoadRect.top + 70);
    canvas.drawPath(meterToLoad, pAcPhase);

    // ৪. নেট মিটার টু ন্যাশনাল গ্রিড (দ্বিমুখী নেট মিটারিং লাইন)
    final meterToGrid = Path()
      ..moveTo(netMeterRect.right, netMeterRect.top + 105)
      ..lineTo(netMeterRect.right + 35, netMeterRect.top + 105)
      ..lineTo(netMeterRect.right + 35, gridRect.top + 70)
      ..lineTo(gridRect.left, gridRect.top + 70);
    canvas.drawPath(meterToGrid, pGridLive);
    _drawLabel(
      canvas,
      Offset(
        netMeterRect.right + 40,
        (netMeterRect.top + 105 + gridRect.top + 70) / 2,
      ),
      isBangla ? 'দ্বিমুখী প্রবাহ' : 'Bi-directional',
    );

    // বক্সসমূহ আঁকা
    _drawCleanPvArray(canvas, pvRect);
    _drawRealisticInverter(
      canvas,
      stringInvRect,
      title: isBangla ? 'অন-গ্রিড ইনভার্টার' : 'Grid-Tied Inverter',
    );
    _drawNetMeterBox(canvas, netMeterRect);
    _drawRealisticAcLoad(canvas, acLoadRect);
    _drawNationalGridBox(canvas, gridRect);
  }

  // =========================================================================
  // 📦 কম্পোনেন্ট বক্সসমূহ আঁকার পদ্ধতি
  // =========================================================================

  void _drawPvWires(Canvas canvas, Rect pv, Rect scc, Paint pPos, Paint pNeg) {
    final pathPos = Path()
      ..moveTo(pv.right, pv.top + 50)
      ..lineTo(scc.left, scc.top + 45);
    final pathNeg = Path()
      ..moveTo(pv.right, pv.top + 80)
      ..lineTo(scc.left, scc.top + 75);
    canvas.drawPath(pathPos, pPos);
    canvas.drawPath(pathNeg, pNeg);
    final double midX = (pv.right + scc.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midX, pv.top + 30),
      'DC MCB ≥ ${result.pvBreakerAmp.toInt()}A',
    );
    _drawLabel(canvas, Offset(midX, pv.top + 98), '${result.pvCableSizeMm} Cu');
  }

  void _drawControllerToBatteryWires(
    Canvas canvas,
    Rect scc,
    Rect bat,
    Paint pPos,
    Paint pNeg,
  ) {
    final pathPos = Path()
      ..moveTo(scc.left + 55, scc.bottom)
      ..lineTo(scc.left + 55, bat.top);
    final pathNeg = Path()
      ..moveTo(scc.left + 95, scc.bottom)
      ..lineTo(scc.left + 95, bat.top);
    canvas.drawPath(pathPos, pPos);
    canvas.drawPath(pathNeg, pNeg);
    final double midY = (scc.bottom + bat.top) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(scc.left + 75, midY),
      'DC MCB ≥ ${result.chargeControllerBreakerAmp.toInt()}A',
    );
  }

  void _drawBatteryToInverterWires(
    Canvas canvas,
    Rect bat,
    Rect inv,
    Paint pPos,
    Paint pNeg,
  ) {
    final pathPos = Path()
      ..moveTo(bat.right, bat.top + 50)
      ..lineTo(inv.left, inv.top + 50);
    final pathNeg = Path()
      ..moveTo(bat.right, bat.top + 90)
      ..lineTo(inv.left, inv.top + 90);
    canvas.drawPath(pathPos, pPos);
    canvas.drawPath(pathNeg, pNeg);
    final double midX = (bat.right + inv.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midX, bat.top + 45),
      'DC FUSE ≥ ${result.batteryFuseAmp.toInt()}A',
    );
    _drawLabel(
      canvas,
      Offset(midX, bat.top + 108),
      '${result.batteryCableSizeMm} Cable',
    );
  }

  void _drawInverterToAcWires(
    Canvas canvas,
    Rect inv,
    Rect acLoad,
    Paint pPhase,
    Paint pNeutral,
  ) {
    final pathPhase = Path()
      ..moveTo(inv.right, inv.top + 50)
      ..lineTo(acLoad.left, acLoad.top + 50);
    final pathNeutral = Path()
      ..moveTo(inv.right, inv.top + 80)
      ..lineTo(acLoad.left, acLoad.top + 80);
    canvas.drawPath(pathPhase, pPhase);
    canvas.drawPath(pathNeutral, pNeutral);
    final double midX = (inv.right + acLoad.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midX, inv.top + 30),
      'AC MCB ≥ ${result.acBreakerAmp.toInt()}A',
    );
  }

  void _drawDcLoadWires(
    Canvas canvas,
    Rect scc,
    Rect dc,
    Paint pPos,
    Paint pNeg,
  ) {
    final pathPos = Path()
      ..moveTo(scc.right, scc.top + 50)
      ..lineTo(dc.left, dc.top + 50);
    final pathNeg = Path()
      ..moveTo(scc.right, scc.top + 80)
      ..lineTo(dc.left, dc.top + 80);
    canvas.drawPath(pathPos, pPos);
    canvas.drawPath(pathNeg, pNeg);
  }

  void _drawCleanPvArray(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFF0369A1),
      isBangla ? 'সোলার পিভি অ্যারে' : 'Solar PV Array',
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 45),
      '${result.totalArrayWatt.toInt()} Wp',
      const TextStyle(
        color: Colors.cyanAccent,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 72),
      'মোট প্যানেল: ${result.totalPanels}টি (${params.panelPmax.toInt()}W)',
      const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 96),
      'বিন্যাস: ${result.panelsSeries} Series × ${result.panelsParallel} Parallel',
      const TextStyle(color: Colors.white70, fontSize: 11),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 118),
      'Vmp: ${result.arrayVmp.toStringAsFixed(1)}V | Imp: ${result.arrayImp.toStringAsFixed(1)}A',
      const TextStyle(color: Colors.white70, fontSize: 10.5),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 138),
      'Voc: ${result.arrayVoc.toStringAsFixed(1)}V | Isc: ${result.arrayIsc.toStringAsFixed(1)}A',
      const TextStyle(color: Colors.white60, fontSize: 10),
    );
  }

  void _drawCleanController(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFF15803D),
      isBangla ? 'চার্জ কন্ট্রোলার' : 'Charge Controller',
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 45),
      '${result.controllerType.toUpperCase()} Controller',
      const TextStyle(
        color: Colors.greenAccent,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 74),
      'সিস্টেম ভোল্টেজ: ${result.controllerVoltage.toInt()}V DC Bus',
      const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 98),
      'কারেন্ট রেটিং: ≥ ${result.controllerAmpere.toInt()}A',
      const TextStyle(
        color: Colors.white70,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 122),
      isBangla
          ? 'সোলার ও ব্যাটারি নিয়ন্ত্রণ হাব'
          : 'Solar & Battery Center Hub',
      const TextStyle(color: Colors.white60, fontSize: 10.5),
    );
  }

  void _drawRealisticBatteryBank(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFFB45309),
      isBangla ? 'ব্যাটারি ব্যাংক' : 'Battery Bank',
    );
    canvas.drawCircle(
      Offset(rect.left + 40, rect.top + 45),
      7,
      Paint()..color = const Color(0xFFEF4444),
    );
    canvas.drawCircle(
      Offset(rect.right - 40, rect.top + 45),
      7,
      Paint()..color = const Color(0xFF38BDF8),
    );
    _drawText(
      canvas,
      Offset(rect.left + 36, rect.top + 40),
      '+',
      const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.right - 43, rect.top + 40),
      '-',
      const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 75),
      '${result.batteryCapacityAh.toStringAsFixed(0)} Ah (${params.systemVoltage.toInt()}V)',
      const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 96),
      '${result.batteriesSeries} Series × ${result.batteriesParallel} Parallel',
      const TextStyle(color: Colors.amberAccent, fontSize: 10.5),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 115),
      'মোট: ${result.totalBatteries}টি (${params.batteryCapacityAh.toInt()}Ah @ 12V)',
      const TextStyle(color: Colors.white70, fontSize: 10),
    );
  }

  void _drawRealisticInverter(
    Canvas canvas,
    Rect rect, {
    required String title,
  }) {
    _drawDeviceBase(canvas, rect, const Color(0xFF6D28D9), title);
    final grillPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 2.0;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(rect.left + 20, rect.top + 45 + (i * 8)),
        Offset(rect.left + 70, rect.top + 45 + (i * 8)),
        grillPaint,
      );
    }
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 85),
      params.systemType == SolarSystemType.gridTied
          ? 'Grid-Synchronized'
          : 'Pure Sine Wave',
      const TextStyle(
        color: Colors.purpleAccent,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 104),
      'Capacity: ≥ ${params.systemType == SolarSystemType.gridTied ? (result.inverterCapacityVa / 1000).toStringAsFixed(1) : result.inverterCapacityVa.toInt()} ${params.systemType == SolarSystemType.gridTied ? "kW" : "VA"}',
      const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 124),
      params.systemType == SolarSystemType.gridTied
          ? 'PV DC ➔ 220V 50Hz AC'
          : 'DC ${result.inverterVoltage.toInt()}V ➔ AC 220V 50Hz',
      const TextStyle(color: Colors.white70, fontSize: 10),
    );
  }

  // 🔄 হাইব্রিড অল-ইন-ওয়ান ইনভার্টার বক্স
  void _drawHybridInverterBox(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFF8B5CF6),
      isBangla ? 'সোলার হাইব্রিড ইনভার্টার' : 'Solar Hybrid Inverter',
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 42),
      'All-in-One Smart Inverter',
      const TextStyle(
        color: Colors.purpleAccent,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 68),
      '• বিল্ট-ইন MPPT কন্ট্রোলার (≥ ${result.controllerAmpere.toInt()}A)',
      const TextStyle(
        color: Colors.greenAccent,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 92),
      '• ইনভার্টার ক্ষমতা: ≥ ${result.inverterCapacityVa.toInt()} VA',
      const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 116),
      '• ব্যাটারি বাস: ${params.systemVoltage.toInt()}V DC',
      const TextStyle(color: Colors.amberAccent, fontSize: 11),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 140),
      '• আউটপুট: 220V 50Hz Pure Sine Wave',
      const TextStyle(color: Colors.white70, fontSize: 10.5),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 164),
      '• দ্বিমুখী গ্রিড ও জেনারেটর সাপোর্ট',
      const TextStyle(color: Colors.white60, fontSize: 10),
    );
  }

  // 🌐 নেট মিটার বক্স
  void _drawNetMeterBox(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFF0D9488),
      isBangla ? 'দ্বিমুখী নেট মিটার' : 'Bi-directional Net Meter',
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 46),
      isBangla ? 'আমদানি/রপ্তানি রেকর্ডার' : 'Import / Export Meter',
      const TextStyle(
        color: Colors.tealAccent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 74),
      '220V / 230V 50Hz',
      const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 98),
      isBangla
          ? 'অতিরিক্ত বিদ্যুৎ গ্রিডে পাঠায়'
          : 'Exports excess solar to grid',
      const TextStyle(color: Colors.white70, fontSize: 9.5),
    );
  }

  // 🏢 জাতীয় পাওয়ার গ্রিড বক্স
  void _drawNationalGridBox(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFF10B981),
      isBangla ? 'জাতীয় পাওয়ার গ্রিড' : 'National Grid',
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 48),
      'Utility Grid (220V AC)',
      const TextStyle(
        color: Colors.greenAccent,
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 74),
      isBangla ? 'বিদ্যুৎ ক্রয় ও বিক্রয় লাইন' : 'Net-metering connection line',
      const TextStyle(color: Colors.white70, fontSize: 10),
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 98),
      isBangla ? 'সার্বক্ষণিক নিরবচ্ছিন্ন উৎস' : 'Continuous Utility Source',
      const TextStyle(color: Colors.white60, fontSize: 9.5),
    );
  }

  void _drawRealisticDcLoad(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFF0E7490),
      isBangla ? 'ডিসি লোড' : 'DC Loads',
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 48),
      '${params.systemVoltage.toInt()}V DC লোডসমূহ',
      const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 70),
      'শক্তি: ${result.dailyDcWh.toStringAsFixed(0)} Wh/day',
      const TextStyle(color: Colors.cyanAccent, fontSize: 10),
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 92),
      isBangla ? 'ডিসি ফ্যান ও এলইডি লাইট' : 'DC Fan & LED Lights',
      const TextStyle(color: Colors.white70, fontSize: 9.5),
    );
  }

  void _drawRealisticAcLoad(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFFD97706),
      isBangla ? 'এসি লোড' : 'AC Loads',
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 48),
      '220V 50Hz AC লোড',
      const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 70),
      'শক্তি: ${result.dailyAcWh.toStringAsFixed(0)} Wh/day',
      const TextStyle(color: Colors.amberAccent, fontSize: 10),
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 92),
      isBangla
          ? 'ফ্রিজ, টিভি, এসি ফ্যান ইত্যাদি'
          : 'Fridge, TV, Home appliances',
      const TextStyle(color: Colors.white70, fontSize: 9.5),
    );
  }

  void _drawDeviceBase(Canvas canvas, Rect rect, Color accent, String title) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
    _drawText(
      canvas,
      Offset(rect.left + 14, rect.top + 14),
      title,
      TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold),
    );
  }

  void _drawBreakerBadge(Canvas canvas, Offset center, String text) {
    const width = 118.0;
    const height = 24.0;
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFDC2626));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  void _drawLabel(Canvas canvas, Offset center, String text) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  void _drawText(Canvas canvas, Offset offset, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ২. সম্পূর্ণ ওভারল্যাপমুক্ত পরিষ্কার সোলার প্যানেল ড্রয়িং পেইন্টার
class CleanPanelVisualPainter extends CustomPainter {
  final int pvs;
  final int pvp;
  final bool isBangla;

  CleanPanelVisualPainter({
    required this.pvs,
    required this.pvp,
    required this.isBangla,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pPos = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;
    final pNeg = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;
    final pJumper = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    if (pvs == 1 && pvp == 1) {
      final pRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 - 20),
        width: 130,
        height: 160,
      );
      _drawPanel(canvas, pRect, 'PV-1');
      canvas.drawLine(
        Offset(pRect.left + 25, pRect.bottom),
        Offset(pRect.left + 25, pRect.bottom + 65),
        pPos,
      );
      _drawText(
        canvas,
        Offset(pRect.left + 10, pRect.bottom + 70),
        'PV (+)',
        const TextStyle(
          color: Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      canvas.drawLine(
        Offset(pRect.right - 25, pRect.bottom),
        Offset(pRect.right - 25, pRect.bottom + 65),
        pNeg,
      );
      _drawText(
        canvas,
        Offset(pRect.right - 35, pRect.bottom + 70),
        'PV (-)',
        const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (pvs > 1 && pvp == 1) {
      final p1 = Rect.fromLTWH(size.width * 0.12, size.height * 0.18, 120, 150);
      final p2 = Rect.fromLTWH(size.width * 0.62, size.height * 0.18, 120, 150);
      _drawPanel(canvas, p1, 'Panel 1');
      _drawPanel(canvas, p2, 'Panel 2');
      final jumperPath = Path()
        ..moveTo(p1.right - 25, p1.bottom)
        ..lineTo(p1.right - 25, p1.bottom + 30)
        ..lineTo(p2.left + 25, p1.bottom + 30)
        ..lineTo(p2.left + 25, p2.bottom);
      canvas.drawPath(jumperPath, pJumper);
      _drawText(
        canvas,
        Offset((p1.right + p2.left) / 2 - 40, p1.bottom + 12),
        isBangla ? 'সিরিজ জাম্পার (+/-)' : 'Series Wire',
        const TextStyle(color: Colors.amberAccent, fontSize: 10),
      );
      canvas.drawLine(
        Offset(p1.left + 25, p1.bottom),
        Offset(p1.left + 25, p1.bottom + 75),
        pPos,
      );
      _drawText(
        canvas,
        Offset(p1.left + 8, p1.bottom + 80),
        'Array (+)',
        const TextStyle(
          color: Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      canvas.drawLine(
        Offset(p2.right - 25, p2.bottom),
        Offset(p2.right - 25, p2.bottom + 75),
        pNeg,
      );
      _drawText(
        canvas,
        Offset(p2.right - 42, p2.bottom + 80),
        'Array (-)',
        const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (pvs == 1 && pvp > 1) {
      final p1 = Rect.fromLTWH(size.width * 0.12, size.height * 0.15, 120, 150);
      final p2 = Rect.fromLTWH(size.width * 0.62, size.height * 0.15, 120, 150);
      _drawPanel(canvas, p1, 'String 1');
      _drawPanel(canvas, p2, 'String 2');
      final posBus = Path()
        ..moveTo(p1.left + 25, p1.bottom)
        ..lineTo(p1.left + 25, p1.bottom + 30)
        ..lineTo(p2.left + 25, p1.bottom + 30)
        ..lineTo(p2.left + 25, p2.bottom);
      canvas.drawPath(posBus, pPos);
      canvas.drawLine(
        Offset(p1.left + 25, p1.bottom + 30),
        Offset(p1.left + 25, p1.bottom + 85),
        pPos,
      );
      _drawText(
        canvas,
        Offset(p1.left + 8, p1.bottom + 90),
        'Array (+)',
        const TextStyle(
          color: Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      final negBus = Path()
        ..moveTo(p1.right - 25, p1.bottom)
        ..lineTo(p1.right - 25, p1.bottom + 55)
        ..lineTo(p2.right - 25, p1.bottom + 55)
        ..lineTo(p2.right - 25, p2.bottom);
      canvas.drawPath(negBus, pNeg);
      canvas.drawLine(
        Offset(p2.right - 25, p2.bottom + 55),
        Offset(p2.right - 25, p2.bottom + 85),
        pNeg,
      );
      _drawText(
        canvas,
        Offset(p2.right - 42, p2.bottom + 90),
        'Array (-)',
        const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      final p11 = Rect.fromLTWH(size.width * 0.18, 20, 105, 120);
      final p12 = Rect.fromLTWH(size.width * 0.54, 20, 105, 120);
      final p21 = Rect.fromLTWH(size.width * 0.18, 180, 105, 120);
      final p22 = Rect.fromLTWH(size.width * 0.54, 180, 105, 120);
      _drawPanel(canvas, p11, 'S1 - Panel 1');
      _drawPanel(canvas, p12, 'S1 - Panel 2');
      _drawPanel(canvas, p21, 'S2 - Panel 1');
      _drawPanel(canvas, p22, 'S2 - Panel 2');
      final j1 = Path()
        ..moveTo(p11.right - 20, p11.bottom)
        ..lineTo(p11.right - 20, p11.bottom + 18)
        ..lineTo(p12.left + 20, p11.bottom + 18)
        ..lineTo(p12.left + 20, p12.bottom);
      canvas.drawPath(j1, pJumper);
      final j2 = Path()
        ..moveTo(p21.right - 20, p21.bottom)
        ..lineTo(p21.right - 20, p21.bottom + 18)
        ..lineTo(p22.left + 20, p21.bottom + 18)
        ..lineTo(p22.left + 20, p22.bottom);
      canvas.drawPath(j2, pJumper);
      final posPath = Path()
        ..moveTo(p11.left + 20, p11.bottom)
        ..lineTo(p11.left - 25, p11.bottom)
        ..lineTo(p11.left - 25, p21.bottom + 35)
        ..lineTo(p21.left + 20, p21.bottom + 35)
        ..lineTo(p21.left + 20, p21.bottom);
      canvas.drawPath(posPath, pPos);
      canvas.drawLine(
        Offset(p11.left - 25, p21.bottom + 35),
        Offset(p11.left - 25, p21.bottom + 75),
        pPos,
      );
      _drawText(
        canvas,
        Offset(p11.left - 45, p21.bottom + 80),
        'Array (+)',
        const TextStyle(
          color: Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      final negPath = Path()
        ..moveTo(p12.right - 20, p12.bottom)
        ..lineTo(p12.right + 25, p12.bottom)
        ..lineTo(p12.right + 25, p22.bottom + 35)
        ..lineTo(p22.right - 20, p22.bottom + 35)
        ..lineTo(p22.right - 20, p22.bottom);
      canvas.drawPath(negPath, pNeg);
      canvas.drawLine(
        Offset(p12.right + 25, p22.bottom + 35),
        Offset(p12.right + 25, p22.bottom + 75),
        pNeg,
      );
      _drawText(
        canvas,
        Offset(p12.right + 5, p22.bottom + 80),
        'Array (-)',
        const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  void _drawPanel(Canvas canvas, Rect r, String label) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(8)),
      Paint()..color = const Color(0xFF0369A1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(8)),
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke,
    );
    final lineP = Paint()
      ..color = Colors.cyanAccent.withAlpha(50)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(r.left + r.width / 2, r.top),
      Offset(r.left + r.width / 2, r.bottom),
      lineP,
    );
    canvas.drawLine(
      Offset(r.left, r.top + r.height / 2),
      Offset(r.right, r.top + r.height / 2),
      lineP,
    );
    _drawText(
      canvas,
      Offset(r.left + 8, r.top + 8),
      label,
      const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(r.left + 16, r.bottom - 20),
      '+',
      const TextStyle(
        color: Colors.redAccent,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(r.right - 24, r.bottom - 20),
      '-',
      const TextStyle(
        color: Colors.cyanAccent,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _drawText(Canvas canvas, Offset offset, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ৩. ওভারল্যাপমুক্ত পরিষ্কার ব্যাটারি ড্রয়িং পেইন্টার
class CleanBatteryVisualPainter extends CustomPainter {
  final int bs;
  final int bp;
  final int sysVolt;
  final bool isBangla;

  CleanBatteryVisualPainter({
    required this.bs,
    required this.bp,
    required this.sysVolt,
    required this.isBangla,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pPos = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;
    final pNeg = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;
    final pJumper = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    if (bs == 1 && bp == 1) {
      final bRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 130,
        height: 100,
      );
      _drawBattery(canvas, bRect, '12V Battery');
      canvas.drawLine(
        Offset(bRect.left + 25, bRect.top),
        Offset(bRect.left + 25, bRect.top - 40),
        pPos,
      );
      _drawText(
        canvas,
        Offset(bRect.left + 15, bRect.top - 55),
        '12V (+)',
        const TextStyle(
          color: Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      canvas.drawLine(
        Offset(bRect.right - 25, bRect.top),
        Offset(bRect.right - 25, bRect.top - 40),
        pNeg,
      );
      _drawText(
        canvas,
        Offset(bRect.right - 35, bRect.top - 55),
        '12V (-)',
        const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (bs > 1 && bp == 1) {
      final b1 = Rect.fromLTWH(size.width * 0.12, size.height * 0.30, 120, 100);
      final b2 = Rect.fromLTWH(size.width * 0.62, size.height * 0.30, 120, 100);
      _drawBattery(canvas, b1, 'Battery 1');
      _drawBattery(canvas, b2, 'Battery 2');
      final jPath = Path()
        ..moveTo(b1.right - 25, b1.top)
        ..lineTo(b1.right - 25, b1.top - 25)
        ..lineTo(b2.left + 25, b1.top - 25)
        ..lineTo(b2.left + 25, b2.top);
      canvas.drawPath(jPath, pJumper);
      _drawText(
        canvas,
        Offset((b1.right + b2.left) / 2 - 40, b1.top - 40),
        isBangla ? 'সিরিজ জাম্পার' : 'Series Jumper',
        const TextStyle(color: Colors.amberAccent, fontSize: 10),
      );
      canvas.drawLine(
        Offset(b1.left + 25, b1.top),
        Offset(b1.left + 25, b1.top - 55),
        pPos,
      );
      _drawText(
        canvas,
        Offset(b1.left + 8, b1.top - 70),
        '$sysVolt\V (+)',
        const TextStyle(
          color: Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      canvas.drawLine(
        Offset(b2.right - 25, b2.top),
        Offset(b2.right - 25, b2.top - 55),
        pNeg,
      );
      _drawText(
        canvas,
        Offset(b2.right - 42, b2.top - 70),
        '$sysVolt\V (-)',
        const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (bs == 1 && bp > 1) {
      final b1 = Rect.fromLTWH(size.width * 0.12, size.height * 0.30, 120, 100);
      final b2 = Rect.fromLTWH(size.width * 0.62, size.height * 0.30, 120, 100);
      _drawBattery(canvas, b1, 'Bat 1 (12V)');
      _drawBattery(canvas, b2, 'Bat 2 (12V)');
      final posPath = Path()
        ..moveTo(b1.left + 25, b1.top)
        ..lineTo(b1.left + 25, b1.top - 25)
        ..lineTo(b2.left + 25, b1.top - 25)
        ..lineTo(b2.left + 25, b2.top);
      canvas.drawPath(posPath, pPos);
      canvas.drawLine(
        Offset(b1.left + 25, b1.top - 25),
        Offset(b1.left + 25, b1.top - 60),
        pPos,
      );
      _drawText(
        canvas,
        Offset(b1.left + 8, b1.top - 75),
        '12V (+)',
        const TextStyle(
          color: Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      final negPath = Path()
        ..moveTo(b1.right - 25, b1.top)
        ..lineTo(b1.right - 25, b1.top - 48)
        ..lineTo(b2.right - 25, b1.top - 48)
        ..lineTo(b2.right - 25, b2.top);
      canvas.drawPath(negPath, pNeg);
      canvas.drawLine(
        Offset(b2.right - 25, b2.top - 48),
        Offset(b2.right - 25, b2.top - 60),
        pNeg,
      );
      _drawText(
        canvas,
        Offset(b2.right - 42, b2.top - 75),
        '12V (-)',
        const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      final b11 = Rect.fromLTWH(size.width * 0.08, 40, 105, 85);
      final b12 = Rect.fromLTWH(size.width * 0.44, 40, 105, 85);
      final b21 = Rect.fromLTWH(size.width * 0.08, 190, 105, 85);
      final b22 = Rect.fromLTWH(size.width * 0.44, 190, 105, 85);
      _drawBattery(canvas, b11, 'B1');
      _drawBattery(canvas, b12, 'B2');
      _drawBattery(canvas, b21, 'B3');
      _drawBattery(canvas, b22, 'B4');
      canvas.drawLine(
        Offset(b11.right - 20, b11.top),
        Offset(b12.left + 20, b12.top),
        pJumper,
      );
      canvas.drawLine(
        Offset(b21.right - 20, b21.top),
        Offset(b22.left + 20, b22.top),
        pJumper,
      );
      final pathParPos = Path()
        ..moveTo(b11.left + 20, b11.top)
        ..lineTo(size.width * 0.76, b11.top)
        ..lineTo(size.width * 0.76, b21.top)
        ..lineTo(b21.left + 20, b21.top);
      canvas.drawPath(pathParPos, pPos);
      canvas.drawLine(
        Offset(size.width * 0.76, (b11.top + b21.top) / 2),
        Offset(size.width * 0.90, (b11.top + b21.top) / 2),
        pPos,
      );
      _drawText(
        canvas,
        Offset(size.width * 0.78, (b11.top + b21.top) / 2 - 16),
        '$sysVolt\V (+)',
        const TextStyle(
          color: Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      final pathParNeg = Path()
        ..moveTo(b12.right - 20, b12.top)
        ..lineTo(size.width * 0.84, b12.top)
        ..lineTo(size.width * 0.84, b22.top)
        ..lineTo(b22.right - 20, b22.top);
      canvas.drawPath(pathParNeg, pNeg);
      canvas.drawLine(
        Offset(size.width * 0.84, (b12.top + b22.top) / 2 + 15),
        Offset(size.width * 0.90, (b12.top + b22.top) / 2 + 15),
        pNeg,
      );
      _drawText(
        canvas,
        Offset(size.width * 0.78, (b12.top + b22.top) / 2 + 20),
        '$sysVolt\V (-)',
        const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  void _drawBattery(Canvas canvas, Rect r, String label) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(8)),
      Paint()..color = const Color(0xFFB45309),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(8)),
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke,
    );
    _drawText(
      canvas,
      Offset(r.left + 8, r.bottom - 20),
      label,
      const TextStyle(
        color: Colors.white,
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
      ),
    );
    canvas.drawCircle(
      Offset(r.left + 20, r.top + 10),
      6,
      Paint()..color = Colors.redAccent,
    );
    canvas.drawCircle(
      Offset(r.right - 20, r.top + 10),
      6,
      Paint()..color = Colors.cyanAccent,
    );
    _drawText(
      canvas,
      Offset(r.left + 17, r.top + 5),
      '+',
      const TextStyle(color: Colors.white, fontSize: 10),
    );
    _drawText(
      canvas,
      Offset(r.right - 23, r.top + 3),
      '-',
      const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  void _drawText(Canvas canvas, Offset offset, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
