import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/app_assets.dart';
import '../models/solar_calculation_result.dart';
import '../models/system_sizing_params.dart';

class PdfReportService {
  /// ১ নম্বর পৃষ্ঠার সম্পূর্ণ টেবিল ও তথ্যকে ফ্লাটার ক্যানভাস দিয়ে হাই-রেজোলিউশন ইমেজ হিসেবে তৈরি করা
  static Future<Uint8List> _renderPage1Image({
    required SolarCalculationResult result,
    required SystemSizingParams params,
    required bool isBangla,
    ui.Image? bcsirLogoUiImage,
  }) async {
    const double width = 1240.0; // A4 150 DPI Scale Width
    const double height = 1754.0; // A4 150 DPI Scale Height

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // সাদা ব্যাকগ্রাউন্ড
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );

    double curY = 60.0;
    const double marginX = 60.0;
    const double contentW = width - (marginX * 2);

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

    // --- হেডার সেকশন ---
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
      Offset(width - marginX, curY + 6),
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

    // সবুজ ডিভাইডার লাইন
    canvas.drawLine(
      Offset(marginX, curY),
      Offset(width - marginX, curY),
      Paint()
        ..color = const Color(0xFF15803D)
        ..strokeWidth = 3.0,
    );
    curY += 24;

    // --- টেবিল রেন্ডারিং হেল্পার মেথড ---
    void drawSectionTable(String title, List<List<String>> rows) {
      // সেকশন শিরোনাম
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

      final double rowHeight = 36.0;
      final double tableH = rows.length * rowHeight;
      final tableRect = Rect.fromLTWH(marginX, curY, contentW, tableH);

      // টেবিল আউটলাইন
      canvas.drawRect(
        tableRect,
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      for (int i = 0; i < rows.length; i++) {
        final rowY = curY + (i * rowHeight);

        // বিকল্প হালকা ব্যাকগ্রাউন্ড
        if (i % 2 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(marginX, rowY, contentW, rowHeight),
            Paint()..color = const Color(0xFFF8FAFC),
          );
        }

        // নিচের ডিভাইডার
        if (i < rows.length - 1) {
          canvas.drawLine(
            Offset(marginX, rowY + rowHeight),
            Offset(width - marginX, rowY + rowHeight),
            Paint()
              ..color = const Color(0xFFE2E8F0)
              ..strokeWidth = 1.0,
          );
        }

        // কলাম টেক্সট (বাম ও ডান)
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
          Offset(width - marginX - 16, rowY + 8),
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

    // ১. লোড ও ডিজাইন প্যারামিটার
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

    // ২. সোলার পিভি অ্যারে কনফিগারেশন
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

    // ৩. ব্যাটারি স্টোরেজ ব্যাংক
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

    // ৪. পাওয়ার ইলেকট্রনিক্স
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
              ? '${(result.inverterCapacityVa / 1000).toStringAsFixed(1)} kW (220V/50Hz On-Grid)'
              : '≥ ${result.inverterCapacityVa.toInt()} VA (${result.inverterVoltage.toInt()}V DC ➔ 220V AC)',
        ],
      ],
    );

    // ৫. সুরক্ষা ব্যবস্থা ও তারের সাইজ
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

    // --- ফুটার সেকশন (লোগো ও নাম) ---
    const double footerY = height - 70;
    canvas.drawLine(
      const Offset(marginX, footerY),
      const Offset(width - marginX, footerY),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 1.0,
    );

    if (bcsirLogoUiImage != null) {
      canvas.drawImageRect(
        bcsirLogoUiImage,
        Rect.fromLTWH(
          0,
          0,
          bcsirLogoUiImage.width.toDouble(),
          bcsirLogoUiImage.height.toDouble(),
        ),
        const Rect.fromLTWH(marginX, footerY + 12, 32, 32),
        Paint(),
      );
    }

    final instTitle = isBangla
        ? 'বাংলাদেশ বিজ্ঞান ও শিল্প গবেষণা পরিষদ (বিসিএসআইআর), বিজ্ঞান ও প্রযুক্তি মন্ত্রণালয়'
        : 'Bangladesh Council of Scientific and Industrial Research (BCSIR), Ministry of Science and Technology';

    _drawText(
      canvas,
      Offset(marginX + (bcsirLogoUiImage != null ? 42 : 0), footerY + 18),
      instTitle,
      const TextStyle(
        color: Color(0xFF14532D),
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
      ),
    );

    _drawTextRight(
      canvas,
      const Offset(width - marginX, footerY + 18),
      'SolEctricity Suite',
      const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
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

  static Future<Uint8List> generateReport({
    required SolarCalculationResult result,
    required SystemSizingParams params,
    required bool isBangla,
    Uint8List? diagramImageBytes,
  }) async {
    final pdf = pw.Document();

    // ১. বিসিএসআইআর লোগো দুই ফরম্যাটে লোড করা (ui.Image ক্যানভাসের জন্য এবং MemoryImage পিডিএফের জন্য)
    ui.Image? bcsirLogoUi;
    pw.MemoryImage? bcsirLogoPw;
    try {
      final logoData = await rootBundle.load(AppAssets.bcsirLogo);
      final bytes = logoData.buffer.asUint8List();
      bcsirLogoPw = pw.MemoryImage(bytes);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      bcsirLogoUi = frame.image;
    } catch (_) {}

    // ২. পেজ ১-কে নিখুঁত ফ্লাটার টেক্সট-শেপিং ক্যানভাসে ছবি হিসেবে তৈরি করা
    final page1Bytes = await _renderPage1Image(
      result: result,
      params: params,
      isBangla: isBangla,
      bcsirLogoUiImage: bcsirLogoUi,
    );
    final page1Image = pw.MemoryImage(page1Bytes);

    // 📄 পৃষ্ঠা ১ যোগ করা (A4 Full-bleed image)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(page1Image, fit: pw.BoxFit.fill),
          );
        },
      ),
    );

    // 🖼️ পৃষ্ঠা ২: ল্যান্ডস্কেপ ওয়্যারিং ডায়াগ্রাম
    if (diagramImageBytes != null) {
      final diagImg = pw.MemoryImage(diagramImageBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(28, 20, 28, 16),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      isBangla
                          ? 'SYSTEM SCHEMATIC WIRING BLUEPRINT'
                          : 'SYSTEM SCHEMATIC WIRING BLUEPRINT',
                      style: pw.TextStyle(
                        color: PdfColors.green900,
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Engineering Schematic',
                      style: const pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(diagImg, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildInstitutionalFooter(bcsirLogoPw, isBangla),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // পৃষ্ঠা ২ এর প্রাতিষ্ঠানিক ফুটার
  static pw.Widget _buildInstitutionalFooter(
    pw.MemoryImage? logo,
    bool isBangla,
  ) {
    const String instText =
        'Bangladesh Council of Scientific and Industrial Research (BCSIR), Ministry of Science and Technology';

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            children: [
              if (logo != null) ...[
                pw.Image(logo, width: 22, height: 22),
                pw.SizedBox(width: 8),
              ],
              pw.Text(
                instText,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
            ],
          ),
          pw.Text(
            'SolEctricity Design Suite',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
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
