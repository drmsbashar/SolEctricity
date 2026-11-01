import 'package:flutter/material.dart';

import '../../models/solar_calculation_result.dart';
import '../../models/system_sizing_params.dart';

// ১. মূল ক্যানভাস ওয়্যারিং পেইন্টার
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

    // কম্পোনেন্ট বক্সগুলোর স্থানাঙ্ক
    const pvRect = Rect.fromLTWH(30, 60, 220, 180);
    const controllerRect = Rect.fromLTWH(360, 70, 220, 160);
    const batteryRect = Rect.fromLTWH(360, 390, 220, 160);
    const inverterRect = Rect.fromLTWH(660, 390, 210, 160);
    const dcLoadRect = Rect.fromLTWH(690, 70, 190, 140);
    const acLoadRect = Rect.fromLTWH(960, 390, 180, 160);

    // ১. পিভি টু চার্জ কন্ট্রোলার ওয়্যারিং (মিডল অ্যালাইনমেন্ট সহ)
    _drawPvWires(canvas, pvRect, controllerRect, pDcPos, pDcNeg);

    // ২. কন্ট্রোলার টু ব্যাটারি ওয়্যারিং
    _drawControllerToBatteryWires(
      canvas,
      controllerRect,
      batteryRect,
      pDcPos,
      pDcNeg,
    );

    // ৩. ব্যাটারি টু ইনভার্টার ও ইনভার্টার টু এসি লোড ওয়্যারিং
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
    }

    // ৪. কন্ট্রোলার টু ডিসি লোড ওয়্যারিং
    if (result.hasDcLoad) {
      _drawDcLoadWires(canvas, controllerRect, dcLoadRect, pDcPos, pDcNeg);
      _drawRealisticDcLoad(canvas, dcLoadRect);
    }

    // ৫. কম্পোনেন্ট বক্সসমূহ আঁকা
    _drawCleanPvArray(canvas, pvRect);
    _drawCleanController(canvas, controllerRect);
    _drawRealisticBatteryBank(canvas, batteryRect);

    if (result.hasAcLoad) {
      _drawRealisticInverter(canvas, inverterRect);
    }
  }

  // 👉 সোলার পিভি থেকে চার্জ কন্ট্রোলারের মধ্যবর্তী টেক্সট সেন্টার অ্যালাইনমেন্ট
  void _drawPvWires(Canvas canvas, Rect pv, Rect scc, Paint pPos, Paint pNeg) {
    final pathPos = Path()
      ..moveTo(pv.right, pv.top + 50)
      ..lineTo(scc.left, scc.top + 45);
    final pathNeg = Path()
      ..moveTo(pv.right, pv.top + 80)
      ..lineTo(scc.left, scc.top + 75);
    canvas.drawPath(pathPos, pPos);
    canvas.drawPath(pathNeg, pNeg);

    // দুটি বক্সের ঠিক মাঝখানের X স্থানাঙ্ক (Mid-point X)
    final double midX = (pv.right + scc.left) / 2;

    // ব্রেকার ব্যাজ ও ক্যাবল টেক্সট ঠিক মাঝখানে (Center-Aligned)
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

  void _drawRealisticInverter(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFF6D28D9),
      isBangla ? 'অফ-গ্রিড ইনভার্টার' : 'Off-grid Inverter',
    );

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
      'Pure Sine Wave',
      const TextStyle(
        color: Colors.purpleAccent,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 104),
      'Capacity: ≥ ${result.inverterCapacityVa.toInt()} VA',
      const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 16, rect.top + 124),
      'DC ${result.inverterVoltage.toInt()}V ➔ AC 220V 50Hz',
      const TextStyle(color: Colors.white70, fontSize: 10),
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

  // 👉 ব্রেকার ব্যাজ ও টেক্সট ঠিক কেন্দ্রবিন্দুতে বসানোর মেথড
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

    // টেক্সট মেপে ঠিক সেন্টারে ড্র করা
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

  // 👉 লেবেল টেক্সট ঠিক সেন্টারে বসানোর মেথড
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

    // ১. একক প্যানেল
    if (pvs == 1 && pvp == 1) {
      final pRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 - 20),
        width: 130,
        height: 160,
      );
      _drawPanel(canvas, pRect, 'PV-1');

      // পজিটিভ সোজা বাম দিক দিয়ে নিচে নামবে
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

      // নেগেটিভ সোজা ডান দিক দিয়ে নিচে নামবে
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
    }
    // ২. শুধু সিরিজ সংযোগ (১টি সারি: প্যানেল ১ ও ২)
    else if (pvs > 1 && pvp == 1) {
      final p1 = Rect.fromLTWH(size.width * 0.12, size.height * 0.18, 120, 150);
      final p2 = Rect.fromLTWH(size.width * 0.62, size.height * 0.18, 120, 150);

      _drawPanel(canvas, p1, 'Panel 1');
      _drawPanel(canvas, p2, 'Panel 2');

      // মাঝখানের পরিষ্কার সিরিজ জাম্পার: Panel 1 (-) থেকে Panel 2 (+)
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

      // Panel 1 (+) সোজা বাম দিক দিয়ে নিচে নামবে
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

      // Panel 2 (-) সোজা ডান দিক দিয়ে নিচে নামবে
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
    }
    // ৩. শুধু প্যারালাল সংযোগ (১টি সিরিজ কিন্তু ২টি সমান্তরাল স্ট্রিং)
    else if (pvs == 1 && pvp > 1) {
      final p1 = Rect.fromLTWH(size.width * 0.12, size.height * 0.15, 120, 150);
      final p2 = Rect.fromLTWH(size.width * 0.62, size.height * 0.15, 120, 150);

      _drawPanel(canvas, p1, 'String 1');
      _drawPanel(canvas, p2, 'String 2');

      // পজিটিভ বাস (বাম দিয়ে নিচে নেমে সোজা সংযুক্ত)
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

      // নেগেটিভ বাস (ডান দিয়ে নিচে নেমে সংযুক্ত)
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
    }
    // ৪. ২ সিরিজ × ২ প্যারালাল (৪টি প্যানেল - সম্পূর্ণ জটহীন ও ওভারল্যাপমুক্ত)
    else {
      // সারি ১ (উপরের দুটি প্যানেল)
      final p11 = Rect.fromLTWH(size.width * 0.18, 20, 105, 120);
      final p12 = Rect.fromLTWH(size.width * 0.54, 20, 105, 120);

      // সারি ২ (নিচের দুটি প্যানেল)
      final p21 = Rect.fromLTWH(size.width * 0.18, 180, 105, 120);
      final p22 = Rect.fromLTWH(size.width * 0.54, 180, 105, 120);

      _drawPanel(canvas, p11, 'S1 - Panel 1');
      _drawPanel(canvas, p12, 'S1 - Panel 2');
      _drawPanel(canvas, p21, 'S2 - Panel 1');
      _drawPanel(canvas, p22, 'S2 - Panel 2');

      // --- সিরিজ কানেকশন (মাঝখান দিয়ে হলুদ জাম্পার) ---
      // সারি ১ এর জাম্পার: P11 (-) থেকে P12 (+)
      final j1 = Path()
        ..moveTo(p11.right - 20, p11.bottom)
        ..lineTo(p11.right - 20, p11.bottom + 18)
        ..lineTo(p12.left + 20, p11.bottom + 18)
        ..lineTo(p12.left + 20, p12.bottom);
      canvas.drawPath(j1, pJumper);

      // সারি ২ এর জাম্পার: P21 (-) থেকে P22 (+)
      final j2 = Path()
        ..moveTo(p21.right - 20, p21.bottom)
        ..lineTo(p21.right - 20, p21.bottom + 18)
        ..lineTo(p22.left + 20, p21.bottom + 18)
        ..lineTo(p22.left + 20, p22.bottom);
      canvas.drawPath(j2, pJumper);

      // --- প্যারালাল কানেকশন (দুই পাশ দিয়ে আলাদা রুট, মাঝের কোনো তারকে ছোঁবে না) ---

      // ১. পজিটিভ প্যারালাল লাইন (বাম দিক দিয়ে সম্পূর্ণ উন্মুক্ত রুট)
      final posPath = Path()
        ..moveTo(p11.left + 20, p11.bottom)
        ..lineTo(p11.left - 25, p11.bottom) // বামে বাইরে বের হলো
        ..lineTo(p11.left - 25, p21.bottom + 35) // নিচে নেমে এলো
        ..lineTo(p21.left + 20, p21.bottom + 35) // P21 এর তারের সাথে জোড়া
        ..lineTo(p21.left + 20, p21.bottom);
      canvas.drawPath(posPath, pPos);

      // মূল পজিটিভ আউটপুট তার (নিচে ড্রপ)
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

      // ২. নেগেটিভ প্যারালাল লাইন (ডান দিক দিয়ে সম্পূর্ণ উন্মুক্ত রুট)
      final negPath = Path()
        ..moveTo(p12.right - 20, p12.bottom)
        ..lineTo(p12.right + 25, p12.bottom) // ডানে বাইরে বের হলো
        ..lineTo(p12.right + 25, p22.bottom + 35) // নিচে নেমে এলো
        ..lineTo(p22.right - 20, p22.bottom + 35) // P22 এর তারের সাথে জোড়া
        ..lineTo(p22.right - 20, p22.bottom);
      canvas.drawPath(negPath, pNeg);

      // মূল নেগেটিভ আউটপুট তার (নিচে ড্রপ)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
