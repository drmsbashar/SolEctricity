import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/app_assets.dart';
import '../models/solar_calculation_result.dart';
import '../models/system_sizing_params.dart';
import '../views/widgets/wiring_painters.dart';

class PdfReportService {
  // A4 স্ট্যান্ডার্ড পিক্সেল স্কেল (150 DPI)
  static const double a4PortraitW = 1240.0;
  static const double a4PortraitH = 1754.0;
  static const double a4LandscapeW = 1754.0;
  static const double a4LandscapeH = 1240.0;

  // =========================================================================
  // পৃষ্ঠা ১: সম্পূর্ণ স্পেসিফিকেশন রিপোর্ট (A4 Portrait)
  // =========================================================================
  static Future<Uint8List> _renderPage1Image({
    required SolarCalculationResult result,
    required SystemSizingParams params,
    required bool isBangla,
    ui.Image? bcsirLogoUiImage,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, a4PortraitW, a4PortraitH),
    );

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, a4PortraitW, a4PortraitH),
      Paint()..color = Colors.white,
    );

    double curY = 60.0;
    const double marginX = 60.0;
    const double contentW = a4PortraitW - (marginX * 2);

    String archName;
    if (params.systemType == SolarSystemType.gridTied) {
      archName = isBangla
          ? 'অন-গ্রিড (নেট-মিটারিং) সোলার সিস্টেম'
          : 'Grid-Tied (Net-Metering) System';
    } else if (params.systemType == SolarSystemType.hybrid) {
      archName = isBangla
          ? 'স্মার্ট হাইব্রিড সোলার সিস্টেম'
          : 'Hybrid Smart Solar System';
    } else {
      archName = isBangla
          ? 'স্ট্যান্ডঅ্যালন অফ-গ্রিড সোলার সিস্টেম'
          : 'Off-Grid Standalone System';
    }

    final isGridTied = params.systemType == SolarSystemType.gridTied;
    final isHybrid = params.systemType == SolarSystemType.hybrid;

    _drawText(
      canvas,
      Offset(marginX, curY),
      isBangla
          ? 'সোলার পাওয়ার সিস্টেম স্পেসিফিকেশন রিপোর্ট'
          : 'SOLAR POWER SYSTEM SPECIFICATION',
      const TextStyle(
        color: Color(0xFF14532D),
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
    );

    final dateStr = DateTime.now().toString().split(' ')[0];
    _drawTextRight(
      canvas,
      Offset(a4PortraitW - marginX, curY + 6),
      dateStr,
      const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
    curY += 38;

    _drawText(
      canvas,
      Offset(marginX, curY),
      archName,
      const TextStyle(
        color: Color(0xFF334155),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
    curY += 28;

    canvas.drawLine(
      Offset(marginX, curY),
      Offset(a4PortraitW - marginX, curY),
      Paint()
        ..color = const Color(0xFF15803D)
        ..strokeWidth = 3.0,
    );
    curY += 24;

    void drawSectionTable(String title, List<List<String>> rows) {
      _drawText(
        canvas,
        Offset(marginX, curY),
        title,
        const TextStyle(
          color: Color(0xFF15803D),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
      curY += 28;

      const double rowHeight = 36.0;
      final double tableH = rows.length * rowHeight;
      final tableRect = Rect.fromLTWH(marginX, curY, contentW, tableH);

      canvas.drawRect(
        tableRect,
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      for (int i = 0; i < rows.length; i++) {
        final rowY = curY + (i * rowHeight);

        if (i % 2 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(marginX, rowY, contentW, rowHeight),
            Paint()..color = const Color(0xFFF8FAFC),
          );
        }

        if (i < rows.length - 1) {
          canvas.drawLine(
            Offset(marginX, rowY + rowHeight),
            Offset(a4PortraitW - marginX, rowY + rowHeight),
            Paint()
              ..color = const Color(0xFFE2E8F0)
              ..strokeWidth = 1.0,
          );
        }

        _drawText(
          canvas,
          Offset(marginX + 16, rowY + 8),
          rows[i][0],
          const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        );

        _drawTextRight(
          canvas,
          Offset(a4PortraitW - marginX - 16, rowY + 8),
          rows[i][1],
          const TextStyle(
            color: Color(0xFF047857),
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
          ),
        );
      }
      curY += tableH + 22;
    }

    drawSectionTable(
      isBangla ? '১. লোড ও ডিজাইন প্যারামিটার' : '1. Load & Design Parameters',
      [
        [
          isBangla ? 'দৈনিক মোট শক্তি চাহিদা' : 'Total Daily Energy Load',
          '${result.totalDailyWh.toStringAsFixed(0)} ${isBangla ? "Wh/দিন" : "Wh/day"}',
        ],
        [
          isBangla ? 'পিক সান আওয়ার (PSH)' : 'Peak Sun Hours (PSH)',
          '${params.peakSunHours} ${isBangla ? "ঘণ্টা" : "Hours"}',
        ],
        if (!isGridTied)
          [
            isBangla ? 'সিস্টেম ডিসি ভোল্টেজ' : 'System DC Voltage',
            '${params.systemVoltage.toInt()} V DC',
          ],
        if (!isGridTied)
          [
            isBangla ? 'মেঘলা দিন ব্যাকআপ (Autonomy)' : 'Autonomy (Backup)',
            '${params.autonomyDays} ${isBangla ? "দিন" : "Day(s)"}',
          ],
      ],
    );

    drawSectionTable(
      isBangla
          ? '২. সোলার পিভি অ্যারে কনফিগারেশন'
          : '2. Solar PV Array Configuration',
      [
        [
          isBangla ? 'মোট অ্যারে ক্ষমতা' : 'Total Array Capacity',
          '${result.totalArrayWatt.toInt()} Wp',
        ],
        [
          isBangla ? 'প্রয়োজনীয় সোলার প্যানেল' : 'Solar Panels Required',
          '${result.totalPanels} ${isBangla ? "টি" : "pcs"} (${params.panelPmax.toInt()}Wp ${isBangla ? "প্রতিটি" : "each"})',
        ],
        [
          isBangla ? 'অ্যারে সংযোগ বিন্যাস' : 'Array Configuration',
          isBangla
              ? '${result.panelsSeries}টি সিরিজে × ${result.panelsParallel}টি স্ট্রিং প্যারালালে'
              : '${result.panelsSeries} Series x ${result.panelsParallel} Strings Parallel',
        ],
        [
          isBangla ? 'কার্যকর অপারেটিং Vmp / Imp' : 'Array Operating Vmp / Imp',
          '${result.arrayVmp.toStringAsFixed(1)} V / ${result.arrayImp.toStringAsFixed(1)} A',
        ],
        [
          isBangla
              ? 'ওপেন সার্কিট Voc / শর্ট সার্কিট Isc'
              : 'Array Open Voc / Short Isc',
          '${result.arrayVoc.toStringAsFixed(1)} V / ${result.arrayIsc.toStringAsFixed(1)} A',
        ],
      ],
    );

    if (!isGridTied) {
      drawSectionTable(
        isBangla ? '৩. ব্যাটারি স্টোরেজ ব্যাংক' : '3. Battery Storage Bank',
        [
          [
            isBangla ? 'মোট ব্যাংক ক্যাপাসিটি' : 'Total Bank Capacity',
            '${result.batteryCapacityAh.toStringAsFixed(0)} Ah (${params.systemVoltage.toInt()}V)',
          ],
          [
            isBangla ? 'মোট প্রয়োজনীয় ব্যাটারি' : 'Total Batteries Required',
            '${result.totalBatteries} ${isBangla ? "টি" : "pcs"} (${params.batteryCapacityAh.toInt()}Ah @ 12V)',
          ],
          [
            isBangla ? 'ব্যাটারি সংযোগ' : 'Battery Wiring',
            isBangla
                ? '${result.batteriesSeries}টি সিরিজে × ${result.batteriesParallel}টি প্যারালালে'
                : '${result.batteriesSeries} Series x ${result.batteriesParallel} Parallel',
          ],
          [
            isBangla
                ? 'ব্যবহারের সীমা (Depth of Discharge)'
                : 'Depth of Discharge (DoD)',
            '${params.batteryDod.toInt()}%',
          ],
        ],
      );
    }

    drawSectionTable(
      isGridTied
          ? (isBangla ? '৩. পাওয়ার ইলেকট্রনিক্স' : '3. Power Electronics')
          : (isBangla ? '৪. পাওয়ার ইলেকট্রনিক্স' : '4. Power Electronics'),
      [
        if (!isGridTied && !isHybrid)
          [
            isBangla ? 'চার্জ কন্ট্রোলার রেটিং' : 'Charge Controller Rating',
            '${result.controllerVoltage.toInt()}V, ≥ ${result.controllerAmpere.toInt()}A (${result.controllerType.toUpperCase()})',
          ],
        if (isHybrid)
          [
            isBangla
                ? 'হাইব্রিড ইনভার্টার (বিল্ট-ইন MPPT)'
                : 'Hybrid Inverter (Built-in MPPT)',
            '≥ ${result.controllerAmpere.toInt()}A MPPT Controller',
          ],
        [
          isGridTied
              ? (isBangla
                    ? 'অন-গ্রিড স্ট্রিং ইনভার্টার'
                    : 'Grid-Tied String Inverter')
              : (isBangla ? 'ইনভার্টার ক্ষমতা' : 'Inverter Capacity'),
          isGridTied
              ? '${(result.inverterCapacityVa / 1000).toStringAsFixed(1)} kW (220V/50Hz On-Grid, DC/AC ≈ 1.15)'
              : '≥ ${result.inverterCapacityVa.toInt()} VA (${result.inverterVoltage.toInt()}V DC ➔ 220V AC)',
        ],
      ],
    );

    drawSectionTable(
      isGridTied
          ? (isBangla
                ? '৪. সুরক্ষা ব্যবস্থা ও তারের সাইজ'
                : '4. Protection Devices & Cables')
          : (isBangla
                ? '৫. সুরক্ষা ব্যবস্থা ও তারের সাইজ'
                : '5. Protection Devices & Cables'),
      [
        [
          isBangla
              ? 'পিভি অ্যারে ডিসি সার্কিট ব্রেকার'
              : 'PV Array DC Circuit Breaker',
          '≥ ${result.pvBreakerAmp.toInt()} A (DC MCB)',
        ],
        if (!isGridTied)
          [
            isBangla ? 'ব্যাটারি প্রধান ডিসি ফিউজ' : 'Battery Main DC Fuse',
            '≥ ${result.batteryFuseAmp.toInt()} A',
          ],
        if (!isGridTied && !isHybrid)
          [
            isBangla
                ? 'কন্ট্রোলার টু ব্যাটারি ব্রেকার'
                : 'Controller to Battery Breaker',
            '≥ ${result.chargeControllerBreakerAmp.toInt()} A',
          ],
        [
          isBangla ? 'এসি আউটপুট ব্রেকার' : 'AC Output Breaker',
          '≥ ${result.acBreakerAmp.toInt()} A (220V AC MCB)',
        ],
        [
          isBangla ? 'পিভি তারের ন্যূনতম সাইজ' : 'PV Cable Minimum Size',
          '${result.pvCableSizeMm} Copper',
        ],
        if (!isGridTied)
          [
            isBangla
                ? 'ব্যাটারি তারের ন্যূনতম সাইজ'
                : 'Battery Cable Minimum Size',
            result.batteryCableSizeMm,
          ],
      ],
    );

    _drawCanvasFooter(
      canvas,
      a4PortraitW,
      a4PortraitH,
      bcsirLogoUiImage,
      isBangla,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(a4PortraitW.toInt(), a4PortraitH.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // =========================================================================
  // পৃষ্ঠা ২: সামগ্রিক সিস্টেম ওয়্যারিং (Full A4 Landscape ক্যানভাস)
  // =========================================================================
  static Future<Uint8List> _renderPage2SchematicImage({
    required SolarCalculationResult result,
    required SystemSizingParams params,
    required bool isBangla,
    ui.Image? bcsirLogoUiImage,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, a4LandscapeW, a4LandscapeH),
    );

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, a4LandscapeW, a4LandscapeH),
      Paint()..color = Colors.white,
    );

    const double marginX = 50.0;
    _drawText(
      canvas,
      const Offset(marginX, 35),
      isBangla
          ? 'সিস্টেম ওয়্যারিং ডায়াগ্রাম (SYSTEM SCHEMATIC BLUEPRINT)'
          : 'SYSTEM SCHEMATIC WIRING BLUEPRINT',
      const TextStyle(
        color: Color(0xFF14532D),
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawTextRight(
      canvas,
      const Offset(a4LandscapeW - marginX, 40),
      'Engineering Overall Blueprint',
      const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );

    canvas.drawLine(
      const Offset(marginX, 75),
      const Offset(a4LandscapeW - marginX, 75),
      Paint()
        ..color = const Color(0xFF15803D)
        ..strokeWidth = 2.5,
    );

    const double targetW = a4LandscapeW - (marginX * 2);
    const double targetH = a4LandscapeH - 180.0;
    const double origW = 1140.0;
    const double origH = 620.0;

    final double scale = math.min(targetW / origW, targetH / origH);
    final double offsetX = marginX + (targetW - (origW * scale)) / 2;
    final double offsetY = 90.0 + (targetH - (origH * scale)) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    final painter = SolarRealisticWiringPainter(
      result: result,
      params: params,
      isBangla: isBangla,
      isDark: false,
      isForPrint: true,
    );
    painter.paint(canvas, const Size(origW, origH));
    canvas.restore();

    _drawCanvasFooter(
      canvas,
      a4LandscapeW,
      a4LandscapeH,
      bcsirLogoUiImage,
      isBangla,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      a4LandscapeW.toInt(),
      a4LandscapeH.toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // =========================================================================
  // পৃষ্ঠা ৩: সোলার প্যানেল বাস্তব সংযোগ (Full A4 Landscape ক্যানভাস)
  // =========================================================================
  static Future<Uint8List> _renderPage3PvDetailImage({
    required SolarCalculationResult result,
    required bool isBangla,
    ui.Image? bcsirLogoUiImage,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, a4LandscapeW, a4LandscapeH),
    );

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, a4LandscapeW, a4LandscapeH),
      Paint()..color = Colors.white,
    );

    const double marginX = 50.0;
    _drawText(
      canvas,
      const Offset(marginX, 35),
      isBangla
          ? 'সোলার পিভি অ্যারে বাস্তব স্ট্রিং বিন্যাস (PV ARRAY BLUEPRINT)'
          : 'SOLAR PV ARRAY STRING WIRING BLUEPRINT',
      const TextStyle(
        color: Color(0xFF0369A1),
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawTextRight(
      canvas,
      const Offset(a4LandscapeW - marginX, 40),
      isBangla
          ? 'মোট: ${result.totalPanels}টি প্যানেল (${result.panelsSeries}S × ${result.panelsParallel}P)'
          : 'Config: ${result.totalPanels} Panels (${result.panelsSeries}S × ${result.panelsParallel}P)',
      const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );

    canvas.drawLine(
      const Offset(marginX, 75),
      const Offset(a4LandscapeW - marginX, 75),
      Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = 2.5,
    );

    // 🌟 স্কেলিং বাউন্ডিং লজিক সিঙ্ক (CleanPanelVisualPainter-এর সঠিক অনুপাত)
    final int pvs = result.panelsSeries;
    final int pvp = result.panelsParallel;
    final double innerScale = pvs <= 3 ? 1.0 : (pvs <= 6 ? 0.82 : 0.68);
    final double rawGridW = ((pvs * 95.0) + ((pvs - 1) * 35.0)) * innerScale;
    final double rawW = math.max(650.0, rawGridW + 280.0);
    final double rawH = math.max(380.0, 110.0 + (pvp * (180.0 * innerScale)));

    const double targetW = a4LandscapeW - (marginX * 2);
    const double targetH = a4LandscapeH - 180.0;
    final double scale = math.min(targetW / rawW, targetH / rawH);
    final double offsetX = marginX + (targetW - (rawW * scale)) / 2;
    final double offsetY = 95.0 + (targetH - (rawH * scale)) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    final painter = CleanPanelVisualPainter(
      pvs: pvs,
      pvp: pvp,
      isBangla: isBangla,
    );
    painter.paint(canvas, Size(rawW, rawH));
    canvas.restore();

    _drawCanvasFooter(
      canvas,
      a4LandscapeW,
      a4LandscapeH,
      bcsirLogoUiImage,
      isBangla,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      a4LandscapeW.toInt(),
      a4LandscapeH.toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // =========================================================================
  // পৃষ্ঠা ৪: ব্যাটারি ব্যাংক বাস্তব সংযোগ (Full A4 Landscape ক্যানভাস)
  // =========================================================================
  static Future<Uint8List> _renderPage4BatteryDetailImage({
    required SolarCalculationResult result,
    required SystemSizingParams params,
    required bool isBangla,
    ui.Image? bcsirLogoUiImage,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, a4LandscapeW, a4LandscapeH),
    );

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, a4LandscapeW, a4LandscapeH),
      Paint()..color = Colors.white,
    );

    const double marginX = 50.0;
    _drawText(
      canvas,
      const Offset(marginX, 35),
      isBangla
          ? 'ব্যাটারি ব্যাংক টার্মিনাল ও জাম্পার সংযোগ বিন্যাস (BATTERY BANK BLUEPRINT)'
          : 'BATTERY BANK TERMINAL & JUMPER WIRING BLUEPRINT',
      const TextStyle(
        color: Color(0xFFB45309),
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
    _drawTextRight(
      canvas,
      const Offset(a4LandscapeW - marginX, 40),
      isBangla
          ? 'মোট: ${result.totalBatteries}টি ব্যাটারি (${result.batteriesSeries}S × ${result.batteriesParallel}P = ${params.systemVoltage.toInt()}V)'
          : 'Config: ${result.totalBatteries} Batteries (${result.batteriesSeries}S × ${result.batteriesParallel}P = ${params.systemVoltage.toInt()}V)',
      const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );

    canvas.drawLine(
      const Offset(marginX, 75),
      const Offset(a4LandscapeW - marginX, 75),
      Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 2.5,
    );

    // 🌟 স্কেলিং বাউন্ডিং লজিক সিঙ্ক (CleanBatteryVisualPainter-এর সঠিক অনুপাত)
    final int bs = result.batteriesSeries;
    final int bp = result.batteriesParallel;
    final double innerScale = bs <= 2 ? 1.0 : (bs <= 4 ? 0.85 : 0.70);
    final double rawGridW = ((bs * 105.0) + ((bs - 1) * 35.0)) * innerScale;
    final double rawW = math.max(650.0, rawGridW + 280.0);
    final double rawH = math.max(380.0, 110.0 + (bp * (140.0 * innerScale)));

    const double targetW = a4LandscapeW - (marginX * 2);
    const double targetH = a4LandscapeH - 180.0;
    final double scale = math.min(targetW / rawW, targetH / rawH);
    final double offsetX = marginX + (targetW - (rawW * scale)) / 2;
    final double offsetY = 95.0 + (targetH - (rawH * scale)) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    final painter = CleanBatteryVisualPainter(
      bs: bs,
      bp: bp,
      sysVolt: params.systemVoltage.toInt(),
      isBangla: isBangla,
    );
    painter.paint(canvas, Size(rawW, rawH));
    canvas.restore();

    _drawCanvasFooter(
      canvas,
      a4LandscapeW,
      a4LandscapeH,
      bcsirLogoUiImage,
      isBangla,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      a4LandscapeW.toInt(),
      a4LandscapeH.toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // =========================================================================
  // ক্যানভাস ফুটার রেন্ডারিং (বিসিএসআইআর ব্র্যান্ডিং)
  // =========================================================================
  static void _drawCanvasFooter(
    Canvas canvas,
    double w,
    double h,
    ui.Image? logo,
    bool isBangla,
  ) {
    const double marginX = 50.0;
    final double footerY = h - 65.0;

    canvas.drawLine(
      Offset(marginX, footerY),
      Offset(w - marginX, footerY),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 1.0,
    );

    if (logo != null) {
      canvas.drawImageRect(
        logo,
        Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
        Rect.fromLTWH(marginX, footerY + 12, 32, 32),
        Paint(),
      );
    }

    final instTitle = isBangla
        ? 'বাংলাদেশ বিজ্ঞান ও শিল্প গবেষণা পরিষদ (বিসিএসআইআর), বিজ্ঞান ও প্রযুক্তি মন্ত্রণালয়'
        : 'Bangladesh Council of Scientific and Industrial Research (BCSIR), Ministry of Science and Technology';

    _drawText(
      canvas,
      Offset(marginX + (logo != null ? 42 : 0), footerY + 18),
      instTitle,
      const TextStyle(
        color: Color(0xFF14532D),
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
      ),
    );

    _drawTextRight(
      canvas,
      Offset(w - marginX, footerY + 18),
      'SolEctricity Suite',
      const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static void _drawText(
    Canvas canvas,
    Offset offset,
    String text,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  static void _drawTextRight(
    Canvas canvas,
    Offset rightOffset,
    String text,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(rightOffset.dx - tp.width, rightOffset.dy));
  }

  // =========================================================================
  // সম্পূর্ণ রিপোর্ট জেনারেট (৪টি পূর্ণাঙ্গ পেইজ)
  // =========================================================================
  static Future<Uint8List> generateReport({
    required SolarCalculationResult result,
    required SystemSizingParams params,
    required bool isBangla,
    Uint8List? diagramImageBytes,
  }) async {
    final pdf = pw.Document();

    ui.Image? bcsirLogoUi;
    try {
      final logoData = await rootBundle.load(AppAssets.bcsirLogo);
      final bytes = logoData.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      bcsirLogoUi = frame.image;
    } catch (_) {}

    // 📄 পৃষ্ঠা ১: স্পেসিফিকেশন রিপোর্ট (A4 Portrait Full Bleed)
    final page1Bytes = await _renderPage1Image(
      result: result,
      params: params,
      isBangla: isBangla,
      bcsirLogoUiImage: bcsirLogoUi,
    );
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(pw.MemoryImage(page1Bytes), fit: pw.BoxFit.fill),
        ),
      ),
    );

    // 🖼️ পৃষ্ঠা ২: ওভারঅল সিস্টেম ওয়্যারিং (A4 Landscape Full Bleed)
    final page2Bytes = await _renderPage2SchematicImage(
      result: result,
      params: params,
      isBangla: isBangla,
      bcsirLogoUiImage: bcsirLogoUi,
    );
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(pw.MemoryImage(page2Bytes), fit: pw.BoxFit.fill),
        ),
      ),
    );

    // ⚡ পৃষ্ঠা ৩: পিভি অ্যারে বাস্তব স্ট্রিং ওয়্যারিং (A4 Landscape Full Bleed)
    final page3Bytes = await _renderPage3PvDetailImage(
      result: result,
      isBangla: isBangla,
      bcsirLogoUiImage: bcsirLogoUi,
    );
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(pw.MemoryImage(page3Bytes), fit: pw.BoxFit.fill),
        ),
      ),
    );

    // 🔋 পৃষ্ঠা ৪: ব্যাটারি ব্যাংক বাস্তব জাম্পার ওয়্যারিং (A4 Landscape Full Bleed)
    if (params.systemType != SolarSystemType.gridTied &&
        result.totalBatteries > 0) {
      final page4Bytes = await _renderPage4BatteryDetailImage(
        result: result,
        params: params,
        isBangla: isBangla,
        bcsirLogoUiImage: bcsirLogoUi,
      );
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(pw.MemoryImage(page4Bytes), fit: pw.BoxFit.fill),
          ),
        ),
      );
    }

    return pdf.save();
  }

  static Future<void> shareOrPrintReport(
    SolarCalculationResult result,
    SystemSizingParams params,
    bool isBangla, {
    Uint8List? diagramImageBytes,
  }) async {
    final pdfBytes = await generateReport(
      result: result,
      params: params,
      isBangla: isBangla,
      diagramImageBytes: diagramImageBytes,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'Solar_Report_${isBangla ? "BN" : "EN"}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
