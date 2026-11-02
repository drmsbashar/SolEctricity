import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/solar_calculation_result.dart';
import '../models/system_sizing_params.dart';

class PdfReportService {
  static Future<Uint8List> generateReport({
    required SolarCalculationResult result,
    required SystemSizingParams params,
    required bool isBangla,
    Uint8List? diagramImageBytes, // 👈 ডায়াগ্রামের ইমেজ বাইটস
  }) async {
    final pdf = pw.Document();

    String archName = 'Off-Grid Standalone System';
    if (params.systemType == SolarSystemType.gridTied) {
      archName = 'Grid-Tied (Net-Metering) System';
    } else if (params.systemType == SolarSystemType.hybrid) {
      archName = 'Hybrid Smart Solar System';
    }

    final isGridTied = params.systemType == SolarSystemType.gridTied;
    final isHybrid = params.systemType == SolarSystemType.hybrid;

    // 📄 পৃষ্ঠা ১: সাইজিং ও স্পেসিফিকেশন রিপোর্ট
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 14),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.green800, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SOLAR POWER SYSTEM SPECIFICATION',
                        style: pw.TextStyle(
                          color: PdfColors.green900,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        archName,
                        style: pw.TextStyle(
                          color: PdfColors.grey700,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    DateTime.now().toString().split(' ')[0],
                    style: const pw.TextStyle(
                      color: PdfColors.grey600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            _buildSectionHeader('1. Load & Design Parameters'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _buildTableRow(
                  'Total Daily Energy Load',
                  '${result.totalDailyWh.toStringAsFixed(0)} Wh/day',
                ),
                _buildTableRow(
                  'Peak Sun Hours (PSH)',
                  '${params.peakSunHours} Hours',
                ),
                if (!isGridTied)
                  _buildTableRow(
                    'System DC Voltage',
                    '${params.systemVoltage.toInt()} V DC',
                  ),
                if (!isGridTied)
                  _buildTableRow(
                    'Autonomy (Backup)',
                    '${params.autonomyDays} Day(s)',
                  ),
              ],
            ),
            pw.SizedBox(height: 14),

            _buildSectionHeader('2. Solar PV Array Configuration'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _buildTableRow(
                  'Total Array Capacity',
                  '${result.totalArrayWatt.toInt()} Wp',
                ),
                _buildTableRow(
                  'Solar Panels Required',
                  '${result.totalPanels} pcs (${params.panelPmax.toInt()}Wp each)',
                ),
                _buildTableRow(
                  'Array Configuration',
                  '${result.panelsSeries} Series x ${result.panelsParallel} Strings Parallel',
                ),
                _buildTableRow(
                  'Array Operating Vmp / Imp',
                  '${result.arrayVmp.toStringAsFixed(1)} V / ${result.arrayImp.toStringAsFixed(1)} A',
                ),
                _buildTableRow(
                  'Array Open Voc / Short Isc',
                  '${result.arrayVoc.toStringAsFixed(1)} V / ${result.arrayIsc.toStringAsFixed(1)} A',
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            if (!isGridTied) ...[
              _buildSectionHeader('3. Battery Storage Bank'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _buildTableRow(
                    'Total Bank Capacity',
                    '${result.batteryCapacityAh.toStringAsFixed(0)} Ah (${params.systemVoltage.toInt()}V)',
                  ),
                  _buildTableRow(
                    'Total Batteries Required',
                    '${result.totalBatteries} pcs (${params.batteryCapacityAh.toInt()}Ah @ 12V)',
                  ),
                  _buildTableRow(
                    'Battery Wiring',
                    '${result.batteriesSeries} Series x ${result.batteriesParallel} Parallel',
                  ),
                  _buildTableRow(
                    'Depth of Discharge (DoD)',
                    '${params.batteryDod.toInt()}%',
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
            ],

            _buildSectionHeader(
              isGridTied ? '3. Power Electronics' : '4. Power Electronics',
            ),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                if (!isGridTied && !isHybrid)
                  _buildTableRow(
                    'Charge Controller Rating',
                    '${result.controllerVoltage.toInt()}V, >= ${result.controllerAmpere.toInt()}A (${result.controllerType.toUpperCase()})',
                  ),
                if (isHybrid)
                  _buildTableRow(
                    'Hybrid Inverter (Built-in MPPT)',
                    '>= ${result.controllerAmpere.toInt()}A MPPT Controller Integrated',
                  ),
                _buildTableRow(
                  isGridTied
                      ? 'Grid-Tied String Inverter'
                      : 'Inverter Capacity',
                  isGridTied
                      ? '${(result.inverterCapacityVa / 1000).toStringAsFixed(1)} kW (220V/50Hz On-Grid)'
                      : '>= ${result.inverterCapacityVa.toInt()} VA (${result.inverterVoltage.toInt()}V DC to 220V AC)',
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            _buildSectionHeader(
              isGridTied
                  ? '4. Protection Devices & Cables'
                  : '5. Protection Devices & Cables',
            ),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _buildTableRow(
                  'PV Array DC Circuit Breaker',
                  '>= ${result.pvBreakerAmp.toInt()} A (DC MCB)',
                ),
                if (!isGridTied)
                  _buildTableRow(
                    'Battery Main DC Fuse',
                    '>= ${result.batteryFuseAmp.toInt()} A',
                  ),
                if (!isGridTied && !isHybrid)
                  _buildTableRow(
                    'Controller to Battery Breaker',
                    '>= ${result.chargeControllerBreakerAmp.toInt()} A',
                  ),
                _buildTableRow(
                  'AC Output Breaker',
                  '>= ${result.acBreakerAmp.toInt()} A (220V AC MCB)',
                ),
                _buildTableRow(
                  'PV Cable Minimum Size',
                  '${result.pvCableSizeMm} Copper',
                ),
                if (!isGridTied)
                  _buildTableRow(
                    'Battery Cable Minimum Size',
                    result.batteryCableSizeMm,
                  ),
              ],
            ),
          ];
        },
      ),
    );

    // 🖼️ পৃষ্ঠা ২: ওয়্যারিং ডায়াগ্রাম ব্লুপ্রিন্ট (Landscape Full-Page)
    if (diagramImageBytes != null) {
      final img = pw.MemoryImage(diagramImageBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'SYSTEM SCHEMATIC WIRING BLUEPRINT ($archName)',
                      style: pw.TextStyle(
                        color: PdfColors.green900,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Engineering Schematic',
                      style: const pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(img, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Generated via Solectricity System Designer',
                    style: const pw.TextStyle(
                      color: PdfColors.grey500,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.green900,
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.TableRow _buildTableRow(String title, String val) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(
            val,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
        ),
      ],
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
          'Solar_Wiring_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
