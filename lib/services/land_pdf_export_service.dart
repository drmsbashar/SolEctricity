import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/system_sizing_params.dart';
import '../views/cost_based_solar_screen.dart'; // CurrencyFormatter ও BatteryChemistry ব্যবহারের জন্য

class LandPdfExportService {
  static String getBatteryTitle(BatteryChemistry chemistry, bool isBangla) {
    switch (chemistry) {
      case BatteryChemistry.leadAcid:
        return isBangla ? 'লেড-এসিড ব্যাটারি' : 'Lead-Acid Battery';
      case BatteryChemistry.tubular:
        return isBangla ? 'টিউবুলার ডিপ-সাইকেল' : 'Tubular Deep-Cycle';
      case BatteryChemistry.lithium:
        return isBangla ? 'লিথিয়াম LiFePO₄' : 'Lithium LiFePO4';
    }
  }

  // 🌟 ক্যানভাস-ভিত্তিক হাই-রেজোলিউশন বাংলা ইমেজ রেন্ডারার (A4 @ 150 DPI)
  static Future<Uint8List> renderLandReportImage({
    required ll.LatLng centroid,
    required String placeName,
    required double totalRoofSqFt,
    required double obstacleSqFt,
    required double netUsableSqFt,
    required double netUsableSqM,
    required double capacityKwp,
    required int totalPanels,
    required int rows,
    required int cols,
    required double optimalTilt,
    required double dailyGenKwh,
    required double monthlyGenKwh,
    required double estimatedBudget,
    required SolarSystemType systemType,
    required BatteryChemistry batteryChemistry,
    required int selectedModuleWatt,
    required double selectedModuleEfficiency,
    required double pricePerWatt,
    required double nasaPsh,
    required double ambientTemp,
    required bool isBangla,
  }) async {
    const double width = 1240.0;
    const double height = 1754.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bgPaint);

    void drawText(
      String text,
      double x,
      double y, {
      double fontSize = 20,
      FontWeight fontWeight = FontWeight.normal,
      Color color = const Color(0xFF0F172A),
      double maxWidth = 1100,
    }) {
      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: isBangla ? 'NotoSansBengali' : null,
          fontFamilyFallback: const [
            'NotoSansBengali',
            'Kalpurush',
            'SiyamRupali',
            'SolaimanLipi',
            'Roboto',
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      textPainter.paint(canvas, Offset(x, y));
    }

    // শীর্ষ হেডার ব্যানার
    final headerPaint = Paint()..color = const Color(0xFF0F766E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(60, 60, width - 120, 115),
        const Radius.circular(12),
      ),
      headerPaint,
    );

    drawText(
      isBangla
          ? 'সূর্য বিদ্যুৎ — ছাদ ও জমির সম্ভাব্যতা মূল্যায়ন রিপোর্ট'
          : 'SolEctricity — Land & Rooftop Solar Feasibility',
      90,
      80,
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    drawText(
      isBangla
          ? 'বাংলাদেশ বিজ্ঞান ও শিল্প গবেষণা পরিষদ (বিসিএসআইআর) | তারিখ: ${DateTime.now().toString().split(' ')[0]}'
          : 'BCSIR Renewable Energy Research Lab | Date: ${DateTime.now().toString().split(' ')[0]}',
      90,
      126,
      fontSize: 15,
      color: const Color(0xFFCCFBF1),
    );

    // ৪টি প্রধান মেট্রিক কার্ড
    final double cardY = 200;
    final double cardW = (width - 120 - 45) / 4;
    final metrics = [
      {
        't': isBangla ? 'কার্যকর সোলার এলাকা' : 'Net Solar Area',
        'v': '${netUsableSqFt.toStringAsFixed(0)} sq.ft',
        'c': const Color(0xFF059669),
      },
      {
        't': isBangla ? 'ইনস্টলযোগ্য ক্ষমতা' : 'DC Capacity',
        'v': '${capacityKwp.toStringAsFixed(2)} kWp',
        'c': const Color(0xFF0284C7),
      },
      {
        't': isBangla ? 'প্যানেল সংখ্যা' : 'Solar Modules',
        'v': isBangla ? '$totalPanels টি' : '$totalPanels pcs',
        'c': const Color(0xFFD97706),
      },
      {
        't': isBangla ? 'সম্ভাব্য বাজেট' : 'Estimated Cost',
        'v': CurrencyFormatter.format(estimatedBudget, isBangla),
        'c': const Color(0xFF7C3AED),
      },
    ];

    for (int i = 0; i < metrics.length; i++) {
      final x = 60 + i * (cardW + 15);
      final cardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, cardY, cardW, 100),
        const Radius.circular(10),
      );
      canvas.drawRRect(cardRect, Paint()..color = const Color(0xFFF8FAFC));
      canvas.drawRRect(
        cardRect,
        Paint()
          ..color = const Color(0xFFE2E8F0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      drawText(
        metrics[i]['t'] as String,
        x + 14,
        cardY + 16,
        fontSize: 13,
        color: const Color(0xFF64748B),
      );
      drawText(
        metrics[i]['v'] as String,
        x + 14,
        cardY + 46,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: metrics[i]['c'] as Color,
      );
    }

    // সেকশন ১: ভৌগোলিক বিবরণ
    double curY = 330;
    drawText(
      isBangla
          ? '১. ভৌগোলিক অবস্থান ও স্থান বিবরণ'
          : '1. Geographic & Location Attributes',
      60,
      curY,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0F766E),
    );
    curY += 34;

    final locRows = [
      [
        isBangla ? 'স্থানের নাম / ঠিকানা' : 'Location Place Name',
        placeName.isNotEmpty
            ? placeName
            : (isBangla ? 'চিহ্নিত ভৌগোলিক এলাকা' : 'Selected Map Polygon'),
      ],
      [
        isBangla ? 'ভৌগোলিক স্থানাঙ্ক (GPS)' : 'Geographic Coordinates',
        'Latitude: ${centroid.latitude.toStringAsFixed(6)}°, Longitude: ${centroid.longitude.toStringAsFixed(6)}°',
      ],
      [
        isBangla ? 'নাসা ক্লাইমেট ডেটা (PSH)' : 'NASA Solar Insolation (PSH)',
        '${nasaPsh.toStringAsFixed(2)} kWh/m²/day | গড় তাপমাত্রা: ${ambientTemp.toStringAsFixed(1)}°C',
      ],
    ];

    for (var r in locRows) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(60, curY, width - 120, 46),
          const Radius.circular(6),
        ),
        Paint()
          ..color = (locRows.indexOf(r) % 2 == 0)
              ? const Color(0xFFF1F5F9)
              : Colors.white,
      );
      drawText(
        r[0],
        76,
        curY + 12,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF334155),
      );
      drawText(
        r[1],
        460,
        curY + 12,
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
        maxWidth: 680,
      );
      curY += 50;
    }

    // সেকশন ২: ক্ষেত্রফল ও স্ট্রাকচারাল স্পেক্স
    curY += 15;
    drawText(
      isBangla
          ? '২. ক্ষেত্রফল ও প্রকৌশল বিন্যাস স্পেসিফিকেশন'
          : '2. Area Analysis & Structural Layout',
      60,
      curY,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0F766E),
    );
    curY += 34;

    String sysName;
    if (systemType == SolarSystemType.gridTied) {
      sysName = isBangla ? 'অন-গ্রিড (নেট-মিটারিং)' : 'Grid-Tied (Net-Metered)';
    } else if (systemType == SolarSystemType.hybrid) {
      sysName = isBangla
          ? 'হাইব্রিড (${getBatteryTitle(batteryChemistry, isBangla)})'
          : 'Hybrid (${getBatteryTitle(batteryChemistry, isBangla)})';
    } else {
      sysName = isBangla
          ? 'অফ-গ্রিড স্ট্যান্ডঅ্যালন (${getBatteryTitle(batteryChemistry, isBangla)})'
          : 'Off-Grid Standalone (${getBatteryTitle(batteryChemistry, isBangla)})';
    }

    final sysRows = [
      [
        isBangla ? 'মোট পরিমাপকৃত ছাদ/জমি' : 'Total Surveyed Roof Area',
        '${totalRoofSqFt.toStringAsFixed(0)} sq.ft (≈ ${(totalRoofSqFt / 10.7639).toStringAsFixed(1)} m²)',
      ],
      [
        isBangla ? 'বাধা ও ছায়াযুক্ত এলাকা' : 'Obstacle & Shaded Area',
        '-${obstacleSqFt > 0 ? obstacleSqFt.toStringAsFixed(0) : "0"} sq.ft (চিলেকোঠা/ছায়া বাদ)',
      ],
      [
        isBangla ? 'কার্যকর নিট সোলার এরিয়া' : 'Net Usable Solar Space',
        '${netUsableSqFt.toStringAsFixed(0)} sq.ft (≈ ${netUsableSqM.toStringAsFixed(1)} m²)',
      ],
      [
        isBangla ? 'প্যানেল সাইজ ও ক্ষমতা' : 'PV Module Power Rating',
        '$selectedModuleWatt Watt (${(selectedModuleEfficiency * 100).toStringAsFixed(1)}% Efficiency)',
      ],
      [
        isBangla ? 'সারি ও কলাম বিন্যাস' : 'Array Grid Layout',
        isBangla
            ? '$rows টি সারি × $cols টি কলাম (মোট $totalPanels টি প্যানেল)'
            : '$rows Rows × $cols Columns (Total: $totalPanels Modules)',
      ],
      [
        isBangla ? 'আদর্শ কাত কোণ ও দিকবিন্যাস' : 'Optimal Tilt & Azimuth',
        'Tilt: ${optimalTilt.toStringAsFixed(1)}° | Azimuth: 180° (দক্ষিণমুখী)',
      ],
      [
        isBangla ? 'প্রাক্কলিত বিদ্যুৎ উৎপাদন' : 'Estimated Energy Generation',
        isBangla
            ? 'দৈনিক: ${dailyGenKwh.toStringAsFixed(1)} kWh | মাসিক: ${monthlyGenKwh.toStringAsFixed(0)} ইউনিট'
            : 'Daily: ${dailyGenKwh.toStringAsFixed(1)} kWh | Monthly: ${monthlyGenKwh.toStringAsFixed(0)} Units',
      ],
      [
        isBangla ? 'সিস্টেম আর্কিটেকচার ও ব্যাটারি' : 'Architecture & Battery',
        sysName,
      ],
      [
        isBangla ? 'টার্নকি বাজেট দর' : 'Turnkey Rate',
        isBangla
            ? '৳ ${pricePerWatt.toStringAsFixed(0)} / Wp'
            : '\$ ${pricePerWatt.toStringAsFixed(2)} / Wp',
      ],
    ];

    for (var r in sysRows) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(60, curY, width - 120, 46),
          const Radius.circular(6),
        ),
        Paint()
          ..color = (sysRows.indexOf(r) % 2 == 0)
              ? const Color(0xFFF1F5F9)
              : Colors.white,
      );
      drawText(
        r[0],
        76,
        curY + 12,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF334155),
      );
      drawText(
        r[1],
        460,
        curY + 12,
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
        maxWidth: 680,
      );
      curY += 50;
    }

    // পরিবেশ ও প্রকৌশল নোট বক্স
    curY += 15;
    final noteRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(60, curY, width - 120, 105),
      const Radius.circular(10),
    );
    canvas.drawRRect(noteRect, Paint()..color = const Color(0xFFECFDF5));
    canvas.drawRRect(
      noteRect,
      Paint()
        ..color = const Color(0xFFA7F3D0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    drawText(
      isBangla
          ? 'প্রকৌশল ও পরিবেশগত স্বীকৃতি:'
          : 'Technical & Environmental Certification:',
      80,
      curY + 16,
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF065F46),
    );
    drawText(
      isBangla
          ? 'এই সিস্টেমে প্রতি বছর প্রায় ${(dailyGenKwh * 365 * 0.62).toStringAsFixed(0)} কেজি কার্বন নির্গমন প্রতিহত হবে যা বাৎসরিক প্রায় ${((dailyGenKwh * 365 * 0.62) / 20).round()} টি বৃক্ষরোপণের সমতুল্য। শীতকালীন ছায়া এড়াতে ২১ ডিসেম্বরের সর্বনিম্ন সৌর উচ্চতা অনুযায়ী সারি দূরত্ব নির্ধারিত হয়েছে।'
          : 'Annual carbon reduction of ${(dailyGenKwh * 365 * 0.62).toStringAsFixed(0)} kg CO2 (≈ ${((dailyGenKwh * 365 * 0.62) / 20).round()} trees planted). Row pitch includes Dec 21 shadow clearance.',
      80,
      curY + 44,
      fontSize: 13.5,
      color: const Color(0xFF047857),
      maxWidth: 1040,
    );

    // ফুটার
    drawText(
      isBangla
          ? 'SolEctricity — নবায়নযোগ্য শক্তি গবেষণা ও সোলার সাইজিং সফটওয়্যার | বিসিএসআইআর'
          : 'SolEctricity — Renewable Energy Engineering Research Software | BCSIR',
      60,
      height - 80,
      fontSize: 13,
      color: const Color(0xFF94A3B8),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // 📄 সম্পূর্ণ PDF জেনারেট করে শেয়ার করা
  static Future<void> generateAndSharePdf({
    required ll.LatLng centroid,
    required String placeName,
    required double totalRoofSqFt,
    required double obstacleSqFt,
    required double netUsableSqFt,
    required double netUsableSqM,
    required double capacityKwp,
    required int totalPanels,
    required int rows,
    required int cols,
    required double optimalTilt,
    required double dailyGenKwh,
    required double monthlyGenKwh,
    required double estimatedBudget,
    required SolarSystemType systemType,
    required BatteryChemistry batteryChemistry,
    required int selectedModuleWatt,
    required double selectedModuleEfficiency,
    required double pricePerWatt,
    required double nasaPsh,
    required double ambientTemp,
    required bool isBangla,
  }) async {
    final imgBytes = await renderLandReportImage(
      centroid: centroid,
      placeName: placeName,
      totalRoofSqFt: totalRoofSqFt,
      obstacleSqFt: obstacleSqFt,
      netUsableSqFt: netUsableSqFt,
      netUsableSqM: netUsableSqM,
      capacityKwp: capacityKwp,
      totalPanels: totalPanels,
      rows: rows,
      cols: cols,
      optimalTilt: optimalTilt,
      dailyGenKwh: dailyGenKwh,
      monthlyGenKwh: monthlyGenKwh,
      estimatedBudget: estimatedBudget,
      systemType: systemType,
      batteryChemistry: batteryChemistry,
      selectedModuleWatt: selectedModuleWatt,
      selectedModuleEfficiency: selectedModuleEfficiency,
      pricePerWatt: pricePerWatt,
      nasaPsh: nasaPsh,
      ambientTemp: ambientTemp,
      isBangla: isBangla,
    );

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(pw.MemoryImage(imgBytes), fit: pw.BoxFit.fill),
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'SolEctricity_Land_Report_${isBangla ? "BN" : "EN"}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
