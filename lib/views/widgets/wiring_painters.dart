import 'package:flutter/material.dart';

import '../../models/solar_calculation_result.dart';
import '../../models/system_sizing_params.dart';

class SolarRealisticWiringPainter extends CustomPainter {
  final SolarCalculationResult result;
  final SystemSizingParams params;
  final bool isBangla;
  final bool isDark;
  final bool isForPrint; // পিডিএফ-এ সাদা ব্যাকগ্রাউন্ড ও হাই-কনট্রাস্টের জন্য

  SolarRealisticWiringPainter({
    required this.result,
    required this.params,
    required this.isBangla,
    this.isDark = true,
    this.isForPrint = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // ব্যাকগ্রাউন্ড পেইন্ট
    final bgPaint = Paint()
      ..color = isForPrint
          ? Colors.white
          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(20),
      ),
      bgPaint,
    );

    // ১. ডিসি পজিটিভ (+) - লাল
    final pDcPos = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // ২. ডিসি নেগেটিভ (-) - গাঢ় রয়্যাল ব্লু
    final pDcNeg = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // ৩. এসি ফেজ / লাইভ (L) - অ্যাম্বার / কমলা
    final pAcPhase = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // ৪. এসি নিউট্রাল (N) - উজ্জ্বল আকাশি / সায়ান
    final pAcNeutral = Paint()
      ..color = const Color(0xFF06B6D4)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // ৫. গ্রিড লাইন - এমারেল্ড গ্রিন
    final pGridLive = Paint()
      ..color = const Color(0xFF059669)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    switch (params.systemType) {
      case SolarSystemType.gridTied:
        _paintGridTiedDiagram(
          canvas,
          w,
          h,
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
          w,
          h,
          pDcPos,
          pDcNeg,
          pAcPhase,
          pAcNeutral,
          pGridLive,
        );
        break;
      case SolarSystemType.offGrid:
        _paintOffGridDiagram(
          canvas,
          w,
          h,
          pDcPos,
          pDcNeg,
          pAcPhase,
          pAcNeutral,
        );
        break;
    }

    // ক্যানভাসের ভেতরেই স্থায়ী ক্যাবল নির্দেশিকা (পিডিএফ প্রিন্টেও আসবে)
    _drawCanvasCableLegend(canvas, w, h);
  }

  // =========================================================================
  // ⚡ ১. অফ-গ্রিড সিস্টেম ওয়্যারিং
  // =========================================================================
  void _paintOffGridDiagram(
    Canvas canvas,
    double w,
    double h,
    Paint pDcPos,
    Paint pDcNeg,
    Paint pAcPhase,
    Paint pAcNeutral,
  ) {
    final pvRect = Rect.fromLTWH(w * 0.025, h * 0.08, w * 0.20, h * 0.34);
    final controllerRect = Rect.fromLTWH(
      w * 0.31,
      h * 0.09,
      w * 0.20,
      h * 0.30,
    );
    final batteryRect = Rect.fromLTWH(w * 0.31, h * 0.55, w * 0.20, h * 0.30);
    final inverterRect = Rect.fromLTWH(w * 0.58, h * 0.55, w * 0.19, h * 0.30);
    final dcLoadRect = Rect.fromLTWH(w * 0.61, h * 0.09, w * 0.16, h * 0.27);
    final acLoadRect = Rect.fromLTWH(w * 0.83, h * 0.55, w * 0.15, h * 0.30);

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

    _drawCleanPvArray(canvas, pvRect);
    _drawCleanController(canvas, controllerRect);
    _drawRealisticBatteryBank(canvas, batteryRect);
  }

  // =========================================================================
  // 🔄 ২. হাইব্রিড সিস্টেম ওয়্যারিং
  // =========================================================================
  void _paintHybridDiagram(
    Canvas canvas,
    double w,
    double h,
    Paint pDcPos,
    Paint pDcNeg,
    Paint pAcPhase,
    Paint pAcNeutral,
    Paint pGridLive,
  ) {
    final pvRect = Rect.fromLTWH(w * 0.025, h * 0.09, w * 0.20, h * 0.34);
    final batteryRect = Rect.fromLTWH(w * 0.025, h * 0.52, w * 0.20, h * 0.30);
    final hybridInvRect = Rect.fromLTWH(w * 0.33, h * 0.20, w * 0.24, h * 0.52);
    final acLoadRect = Rect.fromLTWH(w * 0.68, h * 0.11, w * 0.18, h * 0.27);
    final gridRect = Rect.fromLTWH(w * 0.68, h * 0.50, w * 0.18, h * 0.27);

    final pvPos = Path()
      ..moveTo(pvRect.right, pvRect.top + pvRect.height * 0.28)
      ..lineTo(
        hybridInvRect.left,
        hybridInvRect.top + hybridInvRect.height * 0.18,
      );
    final pvNeg = Path()
      ..moveTo(pvRect.right, pvRect.top + pvRect.height * 0.44)
      ..lineTo(
        hybridInvRect.left,
        hybridInvRect.top + hybridInvRect.height * 0.30,
      );
    canvas.drawPath(pvPos, pDcPos);
    canvas.drawPath(pvNeg, pDcNeg);
    final double midPvX = (pvRect.right + hybridInvRect.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midPvX, pvRect.top + pvRect.height * 0.16),
      'DC MCB ≥ ${result.pvBreakerAmp.toInt()}A',
    );
    _drawLabel(
      canvas,
      Offset(midPvX, pvRect.top + pvRect.height * 0.55),
      '${result.pvCableSizeMm} Cu',
    );

    final double batPosY = batteryRect.top + batteryRect.height * 0.31;
    final double invPosY = hybridInvRect.top + hybridInvRect.height * 0.65;
    final double batNegY = batteryRect.top + batteryRect.height * 0.56;
    final double invNegY = hybridInvRect.top + hybridInvRect.height * 0.77;
    final double midBatX = (batteryRect.right + hybridInvRect.left) / 2;

    final pathBatPos = Path()
      ..moveTo(batteryRect.right, batPosY)
      ..lineTo(hybridInvRect.left, invPosY);
    canvas.drawPath(pathBatPos, pDcPos);

    final pathBatNeg = Path()
      ..moveTo(batteryRect.right, batNegY)
      ..lineTo(hybridInvRect.left, invNegY);
    canvas.drawPath(pathBatNeg, pDcNeg);

    _drawBreakerBadge(
      canvas,
      Offset(midBatX, (batPosY + invPosY) / 2 - 18),
      'DC FUSE ≥ ${result.batteryFuseAmp.toInt()}A',
    );
    _drawLabel(
      canvas,
      Offset(midBatX, (batNegY + invNegY) / 2 + 16),
      '${result.batteryCableSizeMm} Cable',
    );

    final acP = Path()
      ..moveTo(
        hybridInvRect.right,
        hybridInvRect.top + hybridInvRect.height * 0.20,
      )
      ..lineTo(acLoadRect.left, acLoadRect.top + acLoadRect.height * 0.33);
    final acN = Path()
      ..moveTo(
        hybridInvRect.right,
        hybridInvRect.top + hybridInvRect.height * 0.32,
      )
      ..lineTo(acLoadRect.left, acLoadRect.top + acLoadRect.height * 0.53);
    canvas.drawPath(acP, pAcPhase);
    canvas.drawPath(acN, pAcNeutral);
    final double midAcX = (hybridInvRect.right + acLoadRect.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midAcX, acLoadRect.top + acLoadRect.height * 0.20),
      'AC MCB ≥ ${result.acBreakerAmp.toInt()}A',
    );

    final gridPath = Path()
      ..moveTo(
        hybridInvRect.right,
        hybridInvRect.top + hybridInvRect.height * 0.72,
      )
      ..lineTo(gridRect.left, gridRect.top + gridRect.height * 0.40);
    canvas.drawPath(gridPath, pGridLive);
    final double midGridX = (hybridInvRect.right + gridRect.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midGridX, gridRect.top + gridRect.height * 0.20),
      isBangla ? 'গ্রিড সংযোগ' : 'Grid Connection',
    );

    _drawCleanPvArray(canvas, pvRect);
    _drawRealisticBatteryBank(canvas, batteryRect);
    _drawHybridInverterBox(canvas, hybridInvRect);
    _drawRealisticAcLoad(canvas, acLoadRect);
    _drawNationalGridBox(canvas, gridRect);
  }

  // =========================================================================
  // 🌐 ৩. গ্রিড-টাই / অন-গ্রিড ওয়্যারিং
  // =========================================================================
  void _paintGridTiedDiagram(
    Canvas canvas,
    double w,
    double h,
    Paint pDcPos,
    Paint pDcNeg,
    Paint pAcPhase,
    Paint pAcNeutral,
    Paint pGridLive,
  ) {
    final pvRect = Rect.fromLTWH(w * 0.025, h * 0.24, w * 0.20, h * 0.36);
    final stringInvRect = Rect.fromLTWH(w * 0.29, h * 0.24, w * 0.20, h * 0.36);
    final netMeterRect = Rect.fromLTWH(w * 0.55, h * 0.26, w * 0.17, h * 0.32);
    final acLoadRect = Rect.fromLTWH(w * 0.79, h * 0.10, w * 0.18, h * 0.27);
    final gridRect = Rect.fromLTWH(w * 0.79, h * 0.49, w * 0.18, h * 0.27);

    final pvPos = Path()
      ..moveTo(pvRect.right, pvRect.top + pvRect.height * 0.28)
      ..lineTo(
        stringInvRect.left,
        stringInvRect.top + stringInvRect.height * 0.28,
      );
    final pvNeg = Path()
      ..moveTo(pvRect.right, pvRect.top + pvRect.height * 0.44)
      ..lineTo(
        stringInvRect.left,
        stringInvRect.top + stringInvRect.height * 0.44,
      );
    canvas.drawPath(pvPos, pDcPos);
    canvas.drawPath(pvNeg, pDcNeg);
    final double midPvX = (pvRect.right + stringInvRect.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midPvX, pvRect.top + pvRect.height * 0.16),
      'DC MCB ≥ ${result.pvBreakerAmp.toInt()}A',
    );
    _drawLabel(
      canvas,
      Offset(midPvX, pvRect.top + pvRect.height * 0.55),
      '${result.pvCableSizeMm} Cu',
    );

    final invAcP = Path()
      ..moveTo(
        stringInvRect.right,
        stringInvRect.top + stringInvRect.height * 0.28,
      )
      ..lineTo(
        netMeterRect.left,
        netMeterRect.top + netMeterRect.height * 0.31,
      );
    final invAcN = Path()
      ..moveTo(
        stringInvRect.right,
        stringInvRect.top + stringInvRect.height * 0.44,
      )
      ..lineTo(
        netMeterRect.left,
        netMeterRect.top + netMeterRect.height * 0.50,
      );
    canvas.drawPath(invAcP, pAcPhase);
    canvas.drawPath(invAcN, pAcNeutral);
    final double midInvX = (stringInvRect.right + netMeterRect.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midInvX, netMeterRect.top + netMeterRect.height * 0.18),
      'AC MCB ≥ ${result.acBreakerAmp.toInt()}A',
    );

    final meterToLoad = Path()
      ..moveTo(
        netMeterRect.right,
        netMeterRect.top + netMeterRect.height * 0.28,
      )
      ..lineTo(
        netMeterRect.right + w * 0.03,
        netMeterRect.top + netMeterRect.height * 0.28,
      )
      ..lineTo(
        netMeterRect.right + w * 0.03,
        acLoadRect.top + acLoadRect.height * 0.46,
      )
      ..lineTo(acLoadRect.left, acLoadRect.top + acLoadRect.height * 0.46);
    canvas.drawPath(meterToLoad, pAcPhase);

    final meterToGrid = Path()
      ..moveTo(
        netMeterRect.right,
        netMeterRect.top + netMeterRect.height * 0.65,
      )
      ..lineTo(
        netMeterRect.right + w * 0.03,
        netMeterRect.top + netMeterRect.height * 0.65,
      )
      ..lineTo(
        netMeterRect.right + w * 0.03,
        gridRect.top + gridRect.height * 0.46,
      )
      ..lineTo(gridRect.left, gridRect.top + gridRect.height * 0.46);
    canvas.drawPath(meterToGrid, pGridLive);
    _drawLabel(
      canvas,
      Offset(
        netMeterRect.right + w * 0.035,
        (netMeterRect.top +
                netMeterRect.height * 0.65 +
                gridRect.top +
                gridRect.height * 0.46) /
            2,
      ),
      isBangla ? 'দ্বিমুখী প্রবাহ' : 'Bi-directional',
    );

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

  void _drawPvWires(Canvas canvas, Rect pv, Rect scc, Paint pPos, Paint pNeg) {
    final pathPos = Path()
      ..moveTo(pv.right, pv.top + pv.height * 0.28)
      ..lineTo(scc.left, scc.top + scc.height * 0.28);
    final pathNeg = Path()
      ..moveTo(pv.right, pv.top + pv.height * 0.44)
      ..lineTo(scc.left, scc.top + scc.height * 0.47);
    canvas.drawPath(pathPos, pPos);
    canvas.drawPath(pathNeg, pNeg);
    final double midX = (pv.right + scc.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midX, pv.top + pv.height * 0.16),
      'DC MCB ≥ ${result.pvBreakerAmp.toInt()}A',
    );
    _drawLabel(
      canvas,
      Offset(midX, pv.top + pv.height * 0.54),
      '${result.pvCableSizeMm} Cu',
    );
  }

  void _drawControllerToBatteryWires(
    Canvas canvas,
    Rect scc,
    Rect bat,
    Paint pPos,
    Paint pNeg,
  ) {
    final pathPos = Path()
      ..moveTo(scc.left + scc.width * 0.25, scc.bottom)
      ..lineTo(scc.left + scc.width * 0.25, bat.top);
    final pathNeg = Path()
      ..moveTo(scc.left + scc.width * 0.43, scc.bottom)
      ..lineTo(scc.left + scc.width * 0.43, bat.top);
    canvas.drawPath(pathPos, pPos);
    canvas.drawPath(pathNeg, pNeg);
    final double midY = (scc.bottom + bat.top) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(scc.left + scc.width * 0.34, midY),
      'DC MCB ≥ ${result.chargeControllerBreakerAmp.toInt()}A',
    );
  }

  // ব্যাটারি টু অফ-গ্রিড ইনভার্টার ওয়্যারিং (ইনভার্টার-এসি লোডের মতো ক্যাবলের ওপরে ফিউজ)
  void _drawBatteryToInverterWires(
    Canvas canvas,
    Rect bat,
    Rect inv,
    Paint pPos,
    Paint pNeg,
  ) {
    final double midX = (bat.right + inv.left) / 2;

    // ১. পজিটিভ ক্যাবল লাইন (সরাসরি অবিচ্ছিন্ন সংযোগ)
    final double posY = bat.top + bat.height * 0.31;
    final pathPos = Path()
      ..moveTo(bat.right, posY)
      ..lineTo(inv.left, posY);
    canvas.drawPath(pathPos, pPos);

    // ২. ফিউজ ব্যাজ (ইনভার্টার-এসি লোড স্টাইলে ক্যাবলের ওপরে স্পষ্ট অবস্থান)
    _drawBreakerBadge(
      canvas,
      Offset(midX, bat.top + bat.height * 0.15),
      'DC FUSE ≥ ${result.batteryFuseAmp.toInt()}A',
    );

    // ৩. নেগেটিভ ক্যাবল লাইন
    final double negY = bat.top + bat.height * 0.56;
    final pathNeg = Path()
      ..moveTo(bat.right, negY)
      ..lineTo(inv.left, negY);
    canvas.drawPath(pathNeg, pNeg);

    // ক্যাবল সাইজ লেবেল (নেগেটিভ ক্যাবলের নিচে)
    _drawLabel(
      canvas,
      Offset(midX, negY + 18),
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
      ..moveTo(inv.right, inv.top + inv.height * 0.31)
      ..lineTo(acLoad.left, acLoad.top + acLoad.height * 0.31);
    final pathNeutral = Path()
      ..moveTo(inv.right, inv.top + inv.height * 0.50)
      ..lineTo(acLoad.left, acLoad.top + acLoad.height * 0.50);
    canvas.drawPath(pathPhase, pPhase);
    canvas.drawPath(pathNeutral, pNeutral);
    final double midX = (inv.right + acLoad.left) / 2;
    _drawBreakerBadge(
      canvas,
      Offset(midX, inv.top + inv.height * 0.18),
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
      ..moveTo(scc.right, scc.top + scc.height * 0.31)
      ..lineTo(dc.left, dc.top + dc.height * 0.35);
    final pathNeg = Path()
      ..moveTo(scc.right, scc.top + scc.height * 0.50)
      ..lineTo(dc.left, dc.top + dc.height * 0.57);
    canvas.drawPath(pathPos, pPos);
    canvas.drawPath(pathNeg, pNeg);
  }

  Color get _textColor =>
      (isForPrint || !isDark) ? const Color(0xFF0F172A) : Colors.white;
  Color get _textMutedColor => (isForPrint || !isDark)
      ? const Color(0xFF334155)
      : const Color(0xFFCBD5E1);

  // --- ইনসাইড ব্লকের তথ্যাবলি (হাই-কনট্রাস্ট ও স্পষ্ট) ---
  void _drawCleanPvArray(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFF0369A1),
      isBangla ? 'সোলার পিভি অ্যারে' : 'Solar PV Array',
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 34),
      '${result.totalArrayWatt.toInt()} Wp (${params.panelPmax.toInt()}Wp each)',
      TextStyle(
        color: isForPrint
            ? const Color(0xFF0369A1)
            : (isDark ? Colors.cyanAccent : const Color(0xFF0369A1)),
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 58),
      isBangla
          ? 'মোট প্যানেল: ${result.totalPanels}টি'
          : 'Total Panels: ${result.totalPanels} pcs',
      TextStyle(color: _textColor, fontSize: 12.5, fontWeight: FontWeight.bold),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 80),
      isBangla
          ? 'বিন্যাস: ${result.panelsSeries}টি সিরিজ × ${result.panelsParallel}টি প্যারালাল'
          : 'Config: ${result.panelsSeries} Series × ${result.panelsParallel} Parallel',
      TextStyle(color: _textColor, fontSize: 11.5, fontWeight: FontWeight.w600),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 102),
      'Vmp: ${result.arrayVmp.toStringAsFixed(1)}V | Imp: ${result.arrayImp.toStringAsFixed(1)}A',
      TextStyle(
        color: _textMutedColor,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 122),
      'Voc: ${result.arrayVoc.toStringAsFixed(1)}V | Isc: ${result.arrayIsc.toStringAsFixed(1)}A',
      TextStyle(
        color: _textMutedColor,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
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
      Offset(rect.left + 12, rect.top + 36),
      '${result.controllerType.toUpperCase()} Technology',
      TextStyle(
        color: isForPrint
            ? const Color(0xFF15803D)
            : (isDark ? Colors.greenAccent : const Color(0xFF15803D)),
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 60),
      isBangla
          ? 'ভোল্টেজ: ${result.controllerVoltage.toInt()}V DC বাস'
          : 'Bus Voltage: ${result.controllerVoltage.toInt()}V DC',
      TextStyle(color: _textColor, fontSize: 12, fontWeight: FontWeight.bold),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 82),
      isBangla
          ? 'রেটিং ক্ষমতা: ≥ ${result.controllerAmpere.toInt()}A'
          : 'Rating Capacity: ≥ ${result.controllerAmpere.toInt()}A',
      TextStyle(color: _textColor, fontSize: 12, fontWeight: FontWeight.bold),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 104),
      isBangla
          ? 'অটো-কাট ও রিভার্স প্রটেকশন'
          : 'Auto Cut-off & Reverse Protection',
      TextStyle(
        color: _textMutedColor,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
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
      Offset(rect.left + 35, rect.top + 40),
      6,
      Paint()..color = const Color(0xFFEF4444),
    );
    canvas.drawCircle(
      Offset(rect.right - 35, rect.top + 40),
      6,
      Paint()..color = const Color(0xFF1D4ED8),
    );
    _drawText(
      canvas,
      Offset(rect.left + 32, rect.top + 36),
      '+',
      const TextStyle(
        color: Colors.white,
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.right - 38, rect.top + 36),
      '-',
      const TextStyle(
        color: Colors.white,
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
      ),
    );

    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 62),
      '${result.batteryCapacityAh.toStringAsFixed(0)} Ah (${params.systemVoltage.toInt()}V)',
      TextStyle(color: _textColor, fontSize: 13, fontWeight: FontWeight.bold),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 84),
      isBangla
          ? 'মোট: ${result.totalBatteries}টি (${params.batteryCapacityAh.toInt()}Ah @ 12V)'
          : 'Total: ${result.totalBatteries} pcs (${params.batteryCapacityAh.toInt()}Ah @ 12V)',
      TextStyle(color: _textColor, fontSize: 11.5, fontWeight: FontWeight.bold),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 106),
      isBangla
          ? 'সংযোগ: ${result.batteriesSeries}টি সিরিজ × ${result.batteriesParallel}টি প্যারালাল'
          : 'Wiring: ${result.batteriesSeries} Series × ${result.batteriesParallel} Parallel',
      TextStyle(
        color: isForPrint
            ? const Color(0xFFB45309)
            : (isDark ? Colors.amberAccent : const Color(0xFFB45309)),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _drawRealisticInverter(
    Canvas canvas,
    Rect rect, {
    required String title,
  }) {
    _drawDeviceBase(canvas, rect, const Color(0xFF6D28D9), title);
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 38),
      params.systemType == SolarSystemType.gridTied
          ? 'Grid-Tied Sync'
          : 'Pure Sine Wave',
      TextStyle(
        color: isForPrint
            ? const Color(0xFF6D28D9)
            : (isDark ? Colors.purpleAccent : const Color(0xFF6D28D9)),
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 62),
      '${isBangla ? "ক্ষমতা" : "Capacity"}: ≥ ${params.systemType == SolarSystemType.gridTied ? (result.inverterCapacityVa / 1000).toStringAsFixed(1) : result.inverterCapacityVa.toInt()} ${params.systemType == SolarSystemType.gridTied ? "kW" : "VA"}',
      TextStyle(color: _textColor, fontSize: 12.5, fontWeight: FontWeight.bold),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 84),
      params.systemType == SolarSystemType.gridTied
          ? 'ইনপুট: সোলার স্ট্রিং ডিসি'
          : 'ইনপুট: ${result.inverterVoltage.toInt()}V DC বাস',
      TextStyle(color: _textColor, fontSize: 11.5, fontWeight: FontWeight.w600),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 106),
      'আউটপুট: 220V 50Hz AC',
      TextStyle(
        color: _textMutedColor,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _drawHybridInverterBox(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFF7C3AED),
      isBangla ? 'সোলার হাইব্রিড ইনভার্টার' : 'Solar Hybrid Inverter',
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 34),
      'All-in-One Smart Inverter',
      TextStyle(
        color: isForPrint
            ? const Color(0xFF7C3AED)
            : (isDark ? Colors.purpleAccent : const Color(0xFF7C3AED)),
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 58),
      isBangla
          ? '• বিল্ট-ইন MPPT: ≥ ${result.controllerAmpere.toInt()}A'
          : '• Built-in MPPT: ≥ ${result.controllerAmpere.toInt()}A',
      TextStyle(
        color: isForPrint
            ? const Color(0xFF15803D)
            : (isDark ? Colors.greenAccent : const Color(0xFF15803D)),
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 80),
      isBangla
          ? '• রেটিং ক্ষমতা: ≥ ${result.inverterCapacityVa.toInt()} VA'
          : '• Capacity: ≥ ${result.inverterCapacityVa.toInt()} VA',
      TextStyle(color: _textColor, fontSize: 11.5, fontWeight: FontWeight.bold),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 102),
      isBangla
          ? '• ব্যাটারি বাস: ${params.systemVoltage.toInt()}V DC'
          : '• Battery Bus: ${params.systemVoltage.toInt()}V DC',
      TextStyle(color: _textColor, fontSize: 11, fontWeight: FontWeight.bold),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 122),
      '• Output: 220V AC Pure Sine Wave',
      TextStyle(
        color: _textMutedColor,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _drawNetMeterBox(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFF0D9488),
      isBangla ? 'দ্বিমুখী নেট মিটার' : 'Bi-directional Net Meter',
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 38),
      isBangla ? 'আমদানি/রপ্তানি রেকর্ডার' : 'Import/Export Meter',
      TextStyle(
        color: isForPrint
            ? const Color(0xFF0D9488)
            : (isDark ? Colors.tealAccent : const Color(0xFF0D9488)),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 64),
      '220V / 230V 50Hz AC',
      TextStyle(color: _textColor, fontSize: 11.5, fontWeight: FontWeight.bold),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 88),
      isBangla ? 'সোলার নেট ক্রেডিট হিসাব' : 'Solar Net Energy Accounting',
      TextStyle(color: _textMutedColor, fontSize: 10),
    );
  }

  void _drawNationalGridBox(Canvas canvas, Rect rect) {
    _drawDeviceBase(
      canvas,
      rect,
      const Color(0xFF10B981),
      isBangla ? 'জাতীয় পাওয়ার গ্রিড' : 'National Grid',
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 40),
      'Utility Grid (220V AC)',
      TextStyle(
        color: isForPrint
            ? const Color(0xFF059669)
            : (isDark ? Colors.greenAccent : const Color(0xFF059669)),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 66),
      isBangla ? 'বিদ্যুৎ ক্রয় ও বিক্রয় লাইন' : 'Net-metering grid line',
      TextStyle(color: _textColor, fontSize: 11, fontWeight: FontWeight.w600),
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
      Offset(rect.left + 12, rect.top + 40),
      '${params.systemVoltage.toInt()}V DC ${isBangla ? "লোডসমূহ" : "Loads"}',
      TextStyle(color: _textColor, fontSize: 12, fontWeight: FontWeight.bold),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 64),
      '${isBangla ? "চাহিদা" : "Demand"}: ${result.dailyDcWh.toStringAsFixed(0)} Wh/day',
      TextStyle(
        color: isForPrint
            ? const Color(0xFF0E7490)
            : (isDark ? Colors.cyanAccent : const Color(0xFF0E7490)),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
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
      Offset(rect.left + 12, rect.top + 40),
      '220V 50Hz AC ${isBangla ? "লোড" : "Loads"}',
      TextStyle(color: _textColor, fontSize: 12, fontWeight: FontWeight.bold),
    );
    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 64),
      '${isBangla ? "চাহিদা" : "Demand"}: ${result.dailyAcWh.toStringAsFixed(0)} Wh/day',
      TextStyle(
        color: isForPrint
            ? const Color(0xFFD97706)
            : (isDark ? Colors.amberAccent : const Color(0xFFD97706)),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ৩ডি ড্রপ-শ্যাডো
  void _drawDeviceBase(Canvas canvas, Rect rect, Color accent, String title) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    if (!isForPrint) {
      if (isDark) {
        final whiteShadowRect = rect.shift(const Offset(0, 5));
        final whiteShadowRrect = RRect.fromRectAndRadius(
          whiteShadowRect,
          const Radius.circular(14),
        );
        canvas.drawRRect(
          whiteShadowRrect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      } else {
        final darkShadowRect = rect.shift(const Offset(0, 6));
        final darkShadowRrect = RRect.fromRectAndRadius(
          darkShadowRect,
          const Radius.circular(14),
        );
        canvas.drawRRect(
          darkShadowRrect,
          Paint()
            ..color = const Color(0xFF0F172A).withValues(alpha: 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        );
      }
    }

    final boxBg = isForPrint
        ? const Color(0xFFF8FAFC)
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    canvas.drawRRect(rrect, Paint()..color = boxBg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    _drawText(
      canvas,
      Offset(rect.left + 12, rect.top + 10),
      title,
      TextStyle(color: accent, fontSize: 12.5, fontWeight: FontWeight.bold),
    );
  }

  void _drawBreakerBadge(Canvas canvas, Offset center, String text) {
    const width = 114.0;
    const height = 22.0;
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    if (!isForPrint) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 2)),
          const Radius.circular(6),
        ),
        Paint()..color = isDark ? Colors.white24 : Colors.black38,
      );
    }

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
        fontSize: 9,
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
      style: TextStyle(
        color: _textMutedColor,
        fontSize: 10,
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

  // =========================================================================
  // 🏷️ ক্যানভাসে স্থায়ী ক্যাবল ওয়্যারিং লেজেন্ড (পিডিএফ প্রিন্টেও আসবে)
  // =========================================================================
  void _drawCanvasCableLegend(Canvas canvas, double w, double h) {
    // h * 0.90 থেকে বাড়িয়ে h * 0.925 করা হলো, ফলে বারটি আরেকটু নিচে নেমে যাবে
    final legendRect = Rect.fromLTWH(w * 0.05, h * 0.925, w * 0.90, 38);
    final rrect = RRect.fromRectAndRadius(
      legendRect,
      const Radius.circular(10),
    );

    final legendBg = isForPrint
        ? const Color(0xFFF1F5F9)
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    canvas.drawRRect(rrect, Paint()..color = legendBg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isForPrint
            ? const Color(0xFF94A3B8)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    double curX = legendRect.left + 20;
    final double midY = legendRect.top + 21;

    void drawItem(Color color, String label) {
      canvas.drawCircle(Offset(curX + 6, midY), 5.5, Paint()..color = color);
      curX += 16;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: _textColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(curX, midY - tp.height / 2));
      curX += tp.width + 24;
    }

    drawItem(
      const Color(0xFFEF4444),
      isBangla ? 'ডিসি পজিটিভ (+)' : 'DC Positive (+)',
    );
    drawItem(
      const Color(0xFF1D4ED8),
      isBangla ? 'ডিসি নেগেটিভ (-)' : 'DC Negative (-)',
    );

    if (result.hasAcLoad || params.systemType == SolarSystemType.gridTied) {
      drawItem(
        const Color(0xFFD97706),
        isBangla ? 'এসি ফেজ (L)' : 'AC Live (L)',
      );
      drawItem(
        const Color(0xFF06B6D4),
        isBangla ? 'এসি নিউট্রাল (N)' : 'AC Neutral (N)',
      );
    }

    if (params.systemType != SolarSystemType.offGrid) {
      drawItem(const Color(0xFF059669), isBangla ? 'গ্রিড লাইন' : 'Grid Line');
    }
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

// ২. সোলার প্যানেল ড্রয়িং পেইন্টার
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
      ..color = const Color(0xFF1D4ED8)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;
    final pJumper = Paint()
      ..color = const Color(0xFFD97706)
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
          color: Color(0xFF1D4ED8),
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
        const TextStyle(
          color: Color(0xFFD97706),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
          color: Color(0xFF1D4ED8),
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
          color: Color(0xFF1D4ED8),
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
          color: Color(0xFF1D4ED8),
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
        color: Color(0xFF38BDF8),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ৩. ব্যাটারি ড্রয়িং পেইন্টার
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
      ..color = const Color(0xFF1D4ED8)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;
    final pJumper = Paint()
      ..color = const Color(0xFFD97706)
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
          color: Color(0xFF1D4ED8),
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
        const TextStyle(
          color: Color(0xFFD97706),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
          color: Color(0xFF1D4ED8),
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
          color: Color(0xFF1D4ED8),
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
          color: Color(0xFF1D4ED8),
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
      Paint()..color = const Color(0xFF1D4ED8),
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void _drawText(Canvas canvas, Offset offset, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }
}
