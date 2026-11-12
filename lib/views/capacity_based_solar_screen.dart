import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/app_colors.dart';
import '../models/system_sizing_params.dart';
import '../services/solar_calculation_service.dart';
import '../services/solar_radiation_service.dart';
import '../services/tariff_config_service.dart';
import 'cost_based_solar_screen.dart';
import '../widgets/app_bar_title.dart';

class MaxDemandTextInputFormatter extends TextInputFormatter {
  final double maxValue;

  MaxDemandTextInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final double? enteredValue = double.tryParse(
      newValue.text.replaceAll(',', ''),
    );
    if (enteredValue == null || enteredValue > maxValue) {
      return oldValue;
    }
    return newValue;
  }
}

class CapacityBasedSolarScreen extends StatefulWidget {
  final bool isBangla;
  final VoidCallback? onToggleLanguage;

  const CapacityBasedSolarScreen({
    super.key,
    this.isBangla = true,
    this.onToggleLanguage,
  });

  @override
  State<CapacityBasedSolarScreen> createState() =>
      _CapacityBasedSolarScreenState();
}

class _CapacityBasedSolarScreenState extends State<CapacityBasedSolarScreen> {
  late bool _isBangla;

  final TextEditingController _demandController = TextEditingController(
    text: '20',
  );
  final FocusNode _demandFocusNode = FocusNode();

  SolarSystemType _selectedSystemType = SolarSystemType.gridTied;
  BatteryChemistry _selectedBatteryChemistry = BatteryChemistry.tubular;

  double _selectedModuleEfficiency = 0.215;
  int _selectedModuleWatt = 550;
  bool _userManuallyChangedWatt = false;

  int _backupHours = 4;
  double _dayLoadPercentage = 60.0;

  bool _isLoadingNasa = false;
  bool _isExportingPdf = false;
  SolarRadiationResult? _climateData;
  TariffConfig _tariffConfig = TariffConfig.defaultConfig();

  static const double _defaultLat = 23.8103;
  static const double _defaultLon = 90.4125;

  static const double minDailyKwh = 1.0;
  static const double maxDailyKwh = 200.0;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _autoSuggestPanelWatt(20.0);
    _initTariffConfig();
    _fetchLocationClimateData();

    _demandFocusNode.addListener(() {
      if (!_demandFocusNode.hasFocus) {
        _clampAndFormatInput();
      }
    });
  }

  Future<void> _initTariffConfig() async {
    final config = await TariffConfigService.getActiveConfig();
    if (mounted) {
      setState(() {
        _tariffConfig = config;
      });
    }
  }

  void _autoSuggestPanelWatt(double demandKwh) {
    if (_userManuallyChangedWatt) return;
    if (demandKwh <= 2.0) {
      _selectedModuleWatt = 80;
    } else if (demandKwh <= 6.0) {
      _selectedModuleWatt = 200;
    } else if (demandKwh <= 15.0) {
      _selectedModuleWatt = 330;
    } else {
      _selectedModuleWatt = 550;
    }
  }

  void _clampAndFormatInput() {
    final double currentVal =
        double.tryParse(_demandController.text.replaceAll(',', '')) ?? 0.0;
    if (currentVal < minDailyKwh) {
      setState(() {
        _demandController.text = minDailyKwh.toStringAsFixed(0);
        _autoSuggestPanelWatt(minDailyKwh);
      });
    } else if (currentVal > maxDailyKwh) {
      setState(() {
        _demandController.text = maxDailyKwh.toStringAsFixed(0);
        _autoSuggestPanelWatt(maxDailyKwh);
      });
    }
  }

  double _getDefaultTurnkeyRate(SolarSystemType type) {
    if (_isBangla) {
      switch (type) {
        case SolarSystemType.gridTied:
          return _tariffConfig.costPerWatt > 0
              ? _tariffConfig.costPerWatt
              : 75.0;
        case SolarSystemType.hybrid:
          switch (_selectedBatteryChemistry) {
            case BatteryChemistry.leadAcid:
              return 95.0;
            case BatteryChemistry.tubular:
              return 105.0;
            case BatteryChemistry.lithium:
              return 135.0;
          }
        case SolarSystemType.offGrid:
          switch (_selectedBatteryChemistry) {
            case BatteryChemistry.leadAcid:
              return 110.0;
            case BatteryChemistry.tubular:
              return 120.0;
            case BatteryChemistry.lithium:
              return 150.0;
          }
      }
    } else {
      switch (type) {
        case SolarSystemType.gridTied:
          return 0.65;
        case SolarSystemType.hybrid:
          switch (_selectedBatteryChemistry) {
            case BatteryChemistry.leadAcid:
              return 0.80;
            case BatteryChemistry.tubular:
              return 0.90;
            case BatteryChemistry.lithium:
              return 1.15;
          }
        case SolarSystemType.offGrid:
          switch (_selectedBatteryChemistry) {
            case BatteryChemistry.leadAcid:
              return 0.95;
            case BatteryChemistry.tubular:
              return 1.05;
            case BatteryChemistry.lithium:
              return 1.30;
          }
      }
    }
  }

  double _calculateRealisticPayback({
    required double totalCost,
    required double baseAnnualSavings,
  }) {
    if (baseAnnualSavings <= 0 || totalCost <= 0) return 0.0;

    double cumulativeSavings = 0.0;
    double currentYearSavings = baseAnnualSavings;

    double batteryUnitRatio = 0.0;
    if (_selectedSystemType != SolarSystemType.gridTied) {
      switch (_selectedBatteryChemistry) {
        case BatteryChemistry.leadAcid:
          batteryUnitRatio = _selectedSystemType == SolarSystemType.hybrid
              ? 0.20
              : 0.24;
          break;
        case BatteryChemistry.tubular:
          batteryUnitRatio = _selectedSystemType == SolarSystemType.hybrid
              ? 0.24
              : 0.28;
          break;
        case BatteryChemistry.lithium:
          batteryUnitRatio = _selectedSystemType == SolarSystemType.hybrid
              ? 0.38
              : 0.42;
          break;
      }
    }
    final double batteryCost = totalCost * batteryUnitRatio;

    for (int year = 1; year <= 25; year++) {
      double yearNetSavings = currentYearSavings;

      if (_selectedSystemType != SolarSystemType.gridTied) {
        if (_selectedBatteryChemistry == BatteryChemistry.leadAcid &&
            (year % 3 == 0)) {
          yearNetSavings -= batteryCost * 0.70;
        } else if (_selectedBatteryChemistry == BatteryChemistry.tubular &&
            (year % 4 == 0)) {
          yearNetSavings -= batteryCost * 0.70;
        } else if (_selectedBatteryChemistry == BatteryChemistry.lithium &&
            year == 12) {
          yearNetSavings -= batteryCost * 0.60;
        }
      }

      cumulativeSavings += yearNetSavings;
      if (cumulativeSavings >= totalCost) {
        final double prevSavings = cumulativeSavings - yearNetSavings;
        final double needed = totalCost - prevSavings;
        return (year - 1) +
            (needed / (yearNetSavings > 0 ? yearNetSavings : 1.0));
      }
      currentYearSavings *= 0.995; // বার্ষিক ০.৫% অবক্ষয়
    }

    return 25.0;
  }

  @override
  void dispose() {
    _demandController.dispose();
    _demandFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationClimateData() async {
    setState(() => _isLoadingNasa = true);
    try {
      final result = await SolarRadiationService.fetchPshByCoordinates(
        _defaultLat,
        _defaultLon,
      );
      if (mounted) setState(() => _climateData = result);
    } catch (_) {
      if (mounted) {
        setState(() {
          _climateData = SolarRadiationResult(
            peakSunHours: SolarRadiationService.defaultPsh,
            messageBn: 'ডিফল্ট সৌর বিকিরণ ব্যবহৃত হচ্ছে',
            messageEn: 'Using default solar radiation',
            isSuccess: false,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingNasa = false);
    }
  }

  Map<String, int> _calculateStringConfiguration(int totalPanels) {
    if (totalPanels <= 0) return {'strings': 0, 'panelsPerString': 0};
    if (totalPanels <= 8) return {'strings': 1, 'panelsPerString': totalPanels};

    int bestStrings = 1;
    int bestPanelsPerString = totalPanels;

    for (int s = 2; s <= 6; s++) {
      if (totalPanels % s == 0) {
        final p = totalPanels ~/ s;
        if (p >= 8 && p <= 24) {
          bestStrings = s;
          bestPanelsPerString = p;
          break;
        }
      }
    }
    return {'strings': bestStrings, 'panelsPerString': bestPanelsPerString};
  }

  // 🌟 ক্যানভাস-ভিত্তিক হাই-রেজোলিউশন বাংলা ইমেজ রেন্ডারার
  Future<Uint8List> _renderCanvasReportImage({
    required double dailyDemandKwh,
    required double requiredCapacityKwp,
    required int totalPanels,
    required double netRoofAreaSqFt,
    required double inverterKw,
    required double batteryBankKwh,
    required Map<String, int> stringConfig,
    required double psh,
    required double estimatedCost,
    required double annualSavings,
  }) async {
    const double width = 1240.0;
    const double height = 1754.0; // A4 Standard @ 150 DPI

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
          fontFamily: _isBangla ? 'NotoSansBengali' : null,
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

    // শীর্ষ ব্যানার
    final headerPaint = Paint()..color = const Color(0xFF0F766E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(60, 60, width - 120, 110),
        const Radius.circular(12),
      ),
      headerPaint,
    );

    drawText(
      _isBangla
          ? 'সূর্য বিদ্যুৎ — ক্ষমতাভিত্তিক সোলার সাইজিং রিপোর্ট'
          : 'SolEctricity — Capacity Sizing Proposal',
      90,
      82,
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    drawText(
      _isBangla
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
        't': _isBangla ? 'দৈনিক লক্ষ্যমাত্রা' : 'Daily Target',
        'v': '${dailyDemandKwh.toStringAsFixed(1)} kWh',
        'c': const Color(0xFF0284C7),
      },
      {
        't': _isBangla ? 'প্রয়োজনীয় ক্ষমতা' : 'DC Capacity',
        'v': '${requiredCapacityKwp.toStringAsFixed(2)} kWp',
        'c': const Color(0xFF0D9488),
      },
      {
        't': _isBangla ? 'প্যানেল সংখ্যা' : 'Solar Modules',
        'v': _isBangla ? '$totalPanels টি' : '$totalPanels pcs',
        'c': const Color(0xFFD97706),
      },
      {
        't': _isBangla ? 'সম্ভাব্য বাজেট' : 'Estimated Cost',
        'v': CurrencyFormatter.format(estimatedCost, _isBangla),
        'c': const Color(0xFF4F46E5),
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
        fontSize: 13.5,
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

    // টেবিল বিবরণ
    double curY = 340;
    drawText(
      _isBangla
          ? '১. প্রকৌশল সাইজিং ও সিস্টেম স্পেসিফিকেশন'
          : '1. Solar PV Sizing & Space Specifications',
      60,
      curY,
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0F766E),
    );
    curY += 38;

    final rows = [
      [
        _isBangla ? 'সিস্টেমের ধরন ও আর্কিটেকচার' : 'System Architecture',
        _selectedSystemType == SolarSystemType.gridTied
            ? (_isBangla ? 'অন-গ্রিড (নেট-মিটারিং)' : 'Grid-Tied (Net-Metered)')
            : (_selectedSystemType == SolarSystemType.hybrid
                  ? (_isBangla
                        ? 'হাইব্রিড (সোলার + ব্যাটারি + গ্রিড)'
                        : 'Hybrid (Solar + Battery + Grid)')
                  : (_isBangla
                        ? 'অফ-গ্রিড স্ট্যান্ডঅ্যালন'
                        : 'Off-Grid Standalone')),
      ],
      [
        _isBangla ? 'সোলার প্যানেলের একক ক্ষমতা' : 'PV Module Rating',
        '$_selectedModuleWatt Watt (${(_selectedModuleEfficiency * 100).toStringAsFixed(1)}% Efficiency)',
      ],
      [
        _isBangla ? 'স্ট্রিং ও প্যানেল বিন্যাস' : 'String Setup Configuration',
        _isBangla
            ? '${stringConfig['strings']} টি স্ট্রিং × ${stringConfig['panelsPerString']} টি প্যানেল'
            : '${stringConfig['strings']} Strings × ${stringConfig['panelsPerString']} Panels',
      ],
      [
        _isBangla ? 'প্রয়োজনীয় ছাদ / জমির জায়গা' : 'Required Shadow-Free Area',
        '${netRoofAreaSqFt.toStringAsFixed(0)} sq.ft (≈ ${(netRoofAreaSqFt / 10.7639).toStringAsFixed(1)} m²)',
      ],
      [
        _isBangla ? 'প্রস্তাবিত ইনভার্টার ক্ষমতা' : 'Recommended Inverter Size',
        _selectedSystemType == SolarSystemType.gridTied
            ? '${inverterKw.toStringAsFixed(1)} kW (DC/AC অনুপাত ≈ ১.১৫)'
            : '≥ ${(inverterKw * 1000).toInt()} VA Pure Sine Wave',
      ],
      if (_selectedSystemType != SolarSystemType.gridTied) ...[
        [
          _isBangla ? 'ব্যাটারি স্টোরেজ ব্যাংক' : 'Battery Storage Capacity',
          '${batteryBankKwh.toStringAsFixed(1)} kWh (48V ≈ ${(batteryBankKwh * 1000 / 48).toStringAsFixed(0)} Ah)',
        ],
        [
          _isBangla ? 'জরুরি ব্যাকআপ স্থায়িত্ব' : 'Autonomy Backup Duration',
          _isBangla
              ? '$_backupHours ঘণ্টা (DoD: ৮০%)'
              : '$_backupHours Hours (DoD: 80%)',
        ],
      ],
      [
        _isBangla ? 'বাৎসরিক বিদ্যুৎ সাশ্রয়' : 'Annual Electricity Savings',
        CurrencyFormatter.format(annualSavings, _isBangla),
      ],
      [
        _isBangla ? 'নাসা ক্লাইমেট ডেটা (PSH)' : 'NASA Climate Baseline (PSH)',
        '${psh.toStringAsFixed(2)} hrs/day',
      ],
    ];

    for (var r in rows) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(60, curY, width - 120, 48),
          const Radius.circular(6),
        ),
        Paint()
          ..color = (rows.indexOf(r) % 2 == 0)
              ? const Color(0xFFF1F5F9)
              : Colors.white,
      );
      drawText(
        r[0],
        76,
        curY + 13,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF334155),
      );
      drawText(
        r[1],
        480,
        curY + 13,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      );
      curY += 52;
    }

    // ফুটনোট বক্স
    curY += 20;
    final noteRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(60, curY, width - 120, 110),
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
      _isBangla
          ? 'পরিবেশগত ও প্রকৌশল নোট:'
          : 'Engineering & Environmental Note:',
      80,
      curY + 18,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF065F46),
    );
    drawText(
      _isBangla
          ? 'এই সিস্টেমে বাৎসরিক ${(dailyDemandKwh * 365 * 0.62).toStringAsFixed(0)} কেজি কার্বন নির্গমন হ্রাস পাবে যা প্রায় ${((dailyDemandKwh * 365 * 0.62) / 20).round()} টি গাছ লাগানোর সমতুল্য। শীতকালীন ছায়া কোণ ও তাপমাত্রা ডিরেটিং ফ্যাক্টর বিবেচনায় নিয়ে নেট এরিয়া প্রাক্কলন করা হয়েছে।'
          : 'Estimated annual carbon offset is ${(dailyDemandKwh * 365 * 0.62).toStringAsFixed(0)} kg CO2. All calculations account for winter shadow pitch and solar cell thermal derating.',
      80,
      curY + 48,
      fontSize: 13.5,
      color: const Color(0xFF047857),
      maxWidth: 1040,
    );

    // ফুটার
    drawText(
      _isBangla
          ? 'SolEctricity — নবায়নযোগ্য শক্তি প্রকৌশল গবেষণা সফটওয়্যার | বিসিএসআইআর'
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

  // 📄 পৃথক ক্যানভাস-ভিত্তিক PDF ফাইল জেনারেট ও শেয়ার
  Future<void> _generateDedicatedPdf({
    required double dailyDemandKwh,
    required double requiredCapacityKwp,
    required int totalPanels,
    required double netRoofAreaSqFt,
    required double inverterKw,
    required double batteryBankKwh,
    required Map<String, int> stringConfig,
    required double psh,
    required double estimatedCost,
    required double annualSavings,
  }) async {
    setState(() => _isExportingPdf = true);

    try {
      final imgBytes = await _renderCanvasReportImage(
        dailyDemandKwh: dailyDemandKwh,
        requiredCapacityKwp: requiredCapacityKwp,
        totalPanels: totalPanels,
        netRoofAreaSqFt: netRoofAreaSqFt,
        inverterKw: inverterKw,
        batteryBankKwh: batteryBankKwh,
        stringConfig: stringConfig,
        psh: psh,
        estimatedCost: estimatedCost,
        annualSavings: annualSavings,
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
            'SolEctricity_Capacity_Report_${_isBangla ? "BN" : "EN"}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double rawDemand =
        double.tryParse(_demandController.text.replaceAll(',', '')) ?? 0.0;
    final double dailyDemandKwh = rawDemand.clamp(minDailyKwh, maxDailyKwh);

    final double psh =
        _climateData?.peakSunHours ?? SolarRadiationService.defaultPsh;
    final double ambTemp = _climateData?.ambientTemp ?? 26.0;
    final double tempDerate = SolarCalculationService.calculateTempDerateFactor(
      ambTemp,
    );

    // ১. ব্যাটারির ধরন অনুযায়ী Performance Ratio (PR) ও DoD নির্ধারণ
    double basePR = 0.80;
    double batteryDod = 0.80;
    double batteryEff = 0.85;

    if (_selectedSystemType != SolarSystemType.gridTied) {
      switch (_selectedBatteryChemistry) {
        case BatteryChemistry.leadAcid:
          basePR = 0.70;
          batteryDod = 0.50; // লেড-এসিডের নিরাপদ DoD ৫০%
          batteryEff = 0.80;
          break;
        case BatteryChemistry.tubular:
          basePR = 0.74;
          batteryDod = 0.75; // টিউবুলারের DoD ৭৫%
          batteryEff = 0.85;
          break;
        case BatteryChemistry.lithium:
          basePR = 0.80;
          batteryDod = 0.85; // লিথিয়ামের DoD ৮৫%
          batteryEff = 0.95;
          break;
      }
    }
    final double effectivePR = basePR * tempDerate;

    final double requiredCapacityKwp = (psh > 0 && effectivePR > 0)
        ? (dailyDemandKwh / (psh * effectivePR))
        : 0.0;

    final int totalPanels = (requiredCapacityKwp > 0)
        ? ((requiredCapacityKwp * 1000) / _selectedModuleWatt).ceil()
        : 0;
    final stringConfig = _calculateStringConfiguration(totalPanels);

    final double dynamicPF =
        SolarCalculationService.calculateDynamicPackingFactor(_defaultLat);
    final double netRoofAreaSqM = (requiredCapacityKwp > 0)
        ? (requiredCapacityKwp / (_selectedModuleEfficiency * dynamicPF))
        : 0.0;
    final double netRoofAreaSqFt = netRoofAreaSqM * 10.7639;

    final double dayEnergyKwh = dailyDemandKwh * (_dayLoadPercentage / 100.0);
    final double nightEnergyKwh = dailyDemandKwh - dayEnergyKwh;

    final double batteryBankKwh =
        (_selectedSystemType != SolarSystemType.gridTied && dailyDemandKwh > 0)
        ? ((nightEnergyKwh * (_backupHours / 12.0).clamp(0.2, 1.0)) /
              (batteryDod * batteryEff))
        : 0.0;

    // 🌟 অন-গ্রিড আর্কিটেকচারে ডিসি/এসি অনুপাত ১.১৫ সিঙ্ক
    final double inverterKw = _selectedSystemType == SolarSystemType.gridTied
        ? (requiredCapacityKwp > 0 ? (requiredCapacityKwp / 1.15) : 0.0)
        : (requiredCapacityKwp > 0 ? (requiredCapacityKwp * 1.0) : 0.0);

    final double unitRate = _getDefaultTurnkeyRate(_selectedSystemType);
    final double estimatedCost = (requiredCapacityKwp * 1000.0) * unitRate;
    final double annualGenKwh = dailyDemandKwh * 365.0;

    // 🌟 রিমোট সিঙ্কড ট্যারিফ ও অবক্ষয় সমন্বিত বাস্তবসম্মত পে-ব্যাক
    final double tariffRate = _isBangla
        ? (_tariffConfig.residential > 0 ? _tariffConfig.residential : 8.50)
        : 0.12;
    final double annualSavings = annualGenKwh * tariffRate;
    final double paybackYears = _calculateRealisticPayback(
      totalCost: estimatedCost,
      baseAnnualSavings: annualSavings,
    );

    return Scaffold(
      appBar: AppBar(
        title: TwoLineAppBarTitle(
          title: _isBangla ? 'চাহিদাভিত্তিক সাইজিং' : 'Demand Sizing',
          subtitle: _isBangla
              ? 'দৈনিক বিদ্যুৎ চাহিদা অনুযায়ী'
              : 'Based on Daily Energy Target',
        ),
        actions: [
          IconButton(
            tooltip: _isBangla
                ? 'PDF রিপোর্ট ডাউনলোড/শেয়ার'
                : 'Share PDF Report',
            icon: _isExportingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _isExportingPdf
                ? null
                : () => _generateDedicatedPdf(
                    dailyDemandKwh: dailyDemandKwh,
                    requiredCapacityKwp: requiredCapacityKwp,
                    totalPanels: totalPanels,
                    netRoofAreaSqFt: netRoofAreaSqFt,
                    inverterKw: inverterKw,
                    batteryBankKwh: batteryBankKwh,
                    stringConfig: stringConfig,
                    psh: psh,
                    estimatedCost: estimatedCost,
                    annualSavings: annualSavings,
                  ),
          ),
          IconButton(
            tooltip: _isBangla ? 'প্রপোজাল সারাংশ' : 'Proposal Summary',
            icon: Icon(
              Icons.description_rounded,
              color: isDark ? AppColors.accentCyan : const Color(0xFF0284C7),
            ),
            onPressed: () => _showProposalSummaryDialog(
              dailyDemandKwh: dailyDemandKwh,
              capacityKwp: requiredCapacityKwp,
              totalPanels: totalPanels,
              roofAreaSqFt: netRoofAreaSqFt,
              inverterKw: inverterKw,
              batteryBankKwh: batteryBankKwh,
              strings: stringConfig['strings']!,
              panelsPerString: stringConfig['panelsPerString']!,
              isDark: isDark,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _isBangla = !_isBangla);
              widget.onToggleLanguage?.call();
            },
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isBangla ? 'ENG' : 'বাংলা',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: _isBangla ? 'হোম / ড্যাশবোর্ড' : 'Home',
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkBgTop, AppColors.darkBgBottom]
                : [AppColors.lightBgTop, AppColors.lightBgBottom],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClimateHeader(psh, ambTemp, isDark),
              const SizedBox(height: 14),
              _buildDemandInputCard(isDark),
              const SizedBox(height: 14),
              _buildDayNightSplitCard(dayEnergyKwh, nightEnergyKwh, isDark),
              const SizedBox(height: 14),
              _buildConfigurationCard(isDark),
              const SizedBox(height: 18),
              Text(
                _isBangla
                    ? 'প্রকৌশল সাইজিং ও ব্যয় ফলাফল'
                    : 'Engineering Sizing & Costing',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildResultStatCard(
                    title: _isBangla ? 'সিস্টেম ক্ষমতা' : 'DC Capacity',
                    value: '${requiredCapacityKwp.toStringAsFixed(2)} kWp',
                    subtitle: _isBangla
                        ? 'বাৎসরিক: ${annualGenKwh.toStringAsFixed(0)} kWh'
                        : 'Annual: ${annualGenKwh.toStringAsFixed(0)} kWh',
                    icon: Icons.flash_on_rounded,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildResultStatCard(
                    title: _isBangla ? 'প্যানেল সংখ্যা' : 'Total Panels',
                    value: _isBangla ? '$totalPanels টি' : '$totalPanels pcs',
                    subtitle: '$_selectedModuleWatt Watt Modules',
                    icon: Icons.grid_view_rounded,
                    color: AppColors.solarGold,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildResultStatCard(
                    title: _isBangla ? 'প্রয়োজনীয় ছাদ/জমি' : 'Required Space',
                    value: '${netRoofAreaSqFt.toStringAsFixed(0)} sq.ft',
                    subtitle: '≈ ${netRoofAreaSqM.toStringAsFixed(1)} m²',
                    icon: Icons.roofing_rounded,
                    color: isDark
                        ? AppColors.energyGreen
                        : const Color(0xFF059669),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildResultStatCard(
                    title: _isBangla
                        ? 'প্রস্তাবিত ইনভার্টার'
                        : 'Recommended Inverter',
                    value: _selectedSystemType == SolarSystemType.gridTied
                        ? '${inverterKw.toStringAsFixed(1)} kW'
                        : '≥ ${(inverterKw * 1000).toInt()} VA',
                    subtitle: _selectedSystemType == SolarSystemType.gridTied
                        ? 'DC/AC Ratio ≈ 1.15'
                        : 'Pure Sine Wave',
                    icon: Icons.developer_board_rounded,
                    color: isDark ? Colors.tealAccent : const Color(0xFF0D9488),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildResultStatCard(
                    title: _isBangla
                        ? 'সম্ভাব্য সিস্টেম বাজেট'
                        : 'Estimated Budget',
                    value: CurrencyFormatter.format(estimatedCost, _isBangla),
                    subtitle: _isBangla
                        ? '(@ ৳ ${unitRate.toInt()} / Wp টার্নকি)'
                        : '(@ \$ ${unitRate.toStringAsFixed(2)} / Wp Turnkey)',
                    icon: Icons.payments_rounded,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildResultStatCard(
                    title: _isBangla ? 'বিনিয়োগ ফেরত' : 'Est. Payback',
                    value: paybackYears > 0
                        ? '${paybackYears.toStringAsFixed(1)} ${_isBangla ? "বছর" : "Years"}'
                        : 'N/A',
                    subtitle: _isBangla
                        ? 'সাশ্রয়: ${CurrencyFormatter.format(annualSavings, _isBangla)}/বছর'
                        : 'Savings: ${CurrencyFormatter.format(annualSavings, _isBangla)}/yr',
                    icon: Icons.savings_rounded,
                    color: AppColors.solarGold,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildStringConfigCard(stringConfig, isDark),
              if (_selectedSystemType != SolarSystemType.gridTied) ...[
                const SizedBox(height: 10),
                _buildBatteryStorageCard(batteryBankKwh, isDark),
              ],
              const SizedBox(height: 16),
              if (_climateData != null && _climateData!.monthlyPsh.isNotEmpty)
                _buildSeasonalGenerationChart(
                  requiredCapacityKwp,
                  effectivePR,
                  dailyDemandKwh,
                  isDark,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStringConfigCard(Map<String, int> config, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cable_rounded,
            color: isDark ? AppColors.accentCyan : const Color(0xFF0284C7),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBangla
                      ? 'স্ট্রিং কনফিগারেশন সুপারিশ'
                      : 'Recommended Stringing',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isBangla
                      ? '${config['strings']} টি স্ট্রিং × ${config['panelsPerString']} টি প্যানেল'
                      : '${config['strings']} Strings × ${config['panelsPerString']} Panels',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.energyGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Voc Safe',
              style: TextStyle(
                color: AppColors.energyGreen,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryStorageCard(double batteryBankKwh, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.purpleAccent.withValues(alpha: isDark ? 0.3 : 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.battery_charging_full_rounded,
              color: Colors.purpleAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBangla
                      ? 'প্রস্তাবিত ব্যাটারি ব্যাংক'
                      : 'Battery Storage Bank',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${batteryBankKwh.toStringAsFixed(1)} kWh (48V ≈ ${(batteryBankKwh * 1000 / 48).toStringAsFixed(0)} Ah)',
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$_backupHours ${_isBangla ? "ঘণ্টা ব্যাকআপ" : "hrs backup"}',
            style: TextStyle(
              color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalGenerationChart(
    double capacityKwp,
    double effectivePR,
    double dailyDemandKwh,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'মাসভিত্তিক উৎপাদন বনাম চাহিদা'
                    : 'Monthly Generation vs Target',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isBangla ? 'উৎপাদন' : 'Gen',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 8, height: 2, color: AppColors.alertRed),
                  const SizedBox(width: 4),
                  Text(
                    _isBangla ? 'চাহিদা' : 'Target',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: SeasonalComparisonChart(
              monthlyPsh: _climateData!.monthlyPsh,
              capacityKwp: capacityKwp,
              effectivePR: effectivePR,
              targetDailyKwh: dailyDemandKwh,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayNightSplitCard(double dayKwh, double nightKwh, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla ? 'দিন ও রাতের লোড বণ্টন' : 'Day vs Night Load Split',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_dayLoadPercentage.toStringAsFixed(0)}% : ${(100 - _dayLoadPercentage).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: isDark
                      ? AppColors.accentCyan
                      : const Color(0xFF0284C7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.solarGold,
              inactiveTrackColor: Colors.indigoAccent.withValues(alpha: 0.4),
              thumbColor: AppColors.solarGold,
              trackHeight: 4,
            ),
            child: Slider(
              value: _dayLoadPercentage,
              min: 20,
              max: 90,
              divisions: 14,
              onChanged: (v) => setState(() => _dayLoadPercentage = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    size: 14,
                    color: AppColors.solarGold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isBangla
                        ? 'দিনের লোড: ${dayKwh.toStringAsFixed(1)} kWh'
                        : 'Day Load: ${dayKwh.toStringAsFixed(1)} kWh',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.nightlight_outlined,
                    size: 14,
                    color: Colors.indigoAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isBangla
                        ? 'রাতের লোড: ${nightKwh.toStringAsFixed(1)} kWh'
                        : 'Night Load: ${nightKwh.toStringAsFixed(1)} kWh',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClimateHeader(double psh, double ambTemp, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.satellite_alt_rounded,
            color: isDark ? AppColors.accentCyan : const Color(0xFF0284C7),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _climateData?.placeName.isNotEmpty == true
                      ? '📍 ${_climateData!.placeName}'
                      : (_isBangla
                            ? 'নাসা ক্লাইমেট ডেটা'
                            : 'NASA Climate Data'),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isBangla
                      ? 'PSH: ${psh.toStringAsFixed(2)} ঘণ্টা | গড় তাপমাত্রা: ${ambTemp.toStringAsFixed(1)}°C'
                      : 'PSH: ${psh.toStringAsFixed(2)} hrs | Avg Temp: ${ambTemp.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoadingNasa)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? AppColors.accentCyan : AppColors.energyGreen,
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                size: 18,
              ),
              onPressed: _fetchLocationClimateData,
              tooltip: _isBangla ? 'রিফ্রেশ' : 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildDemandInputCard(bool isDark) {
    final double currentVal =
        double.tryParse(_demandController.text.replaceAll(',', '')) ??
        minDailyKwh;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla ? 'দৈনিক বিদ্যুৎ চাহিদা' : 'Daily Energy Target',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.energyGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isBangla ? 'ইউনিট বা kWh' : 'Units or kWh',
                  style: const TextStyle(
                    color: AppColors.energyGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _demandController,
            focusNode: _demandFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              MaxDemandTextInputFormatter(maxDailyKwh),
            ],
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val.replaceAll(',', '')) ?? 0.0;
              setState(() {
                _autoSuggestPanelWatt(parsed);
              });
            },
            onEditingComplete: () {
              _clampAndFormatInput();
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? AppColors.darkInputBg
                  : AppColors.lightInputBg,
              prefixIcon: const Icon(
                Icons.bolt_rounded,
                color: AppColors.solarGold,
                size: 24,
              ),
              suffixText: _isBangla ? 'kWh / দিন' : 'kWh / Day',
              suffixStyle: TextStyle(
                color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                fontSize: 13,
              ),
              errorText: (currentVal > 0 && currentVal < minDailyKwh)
                  ? (_isBangla
                        ? 'চাহিদা সর্বনিম্ন ১ kWh হতে হবে'
                        : 'Minimum demand is 1 kWh')
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.solarGold,
              inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
              thumbColor: AppColors.solarGold,
              overlayColor: AppColors.solarGold.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: currentVal.clamp(minDailyKwh, maxDailyKwh),
              min: minDailyKwh,
              max: maxDailyKwh,
              onChanged: (v) {
                setState(() {
                  _demandController.text = v.toStringAsFixed(0);
                  _autoSuggestPanelWatt(v);
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla ? 'সর্বনিম্ন: ১ kWh/দিন' : 'Min: 1 kWh/day',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                _isBangla
                    ? 'সর্বোচ্চ: ২০০ kWh/দিন (SHS সীমা)'
                    : 'Max: 200 kWh/day (SHS Limit)',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationCard(bool isDark) {
    const candidateWatts = [
      20,
      50,
      80,
      100,
      150,
      200,
      250,
      330,
      400,
      450,
      550,
      650,
      700,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isBangla
                ? 'সিস্টেম ও প্যানেল কনফিগারেশন'
                : 'System & Module Configuration',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTypeRadio(
                SolarSystemType.gridTied,
                _isBangla ? 'অন-গ্রিড' : 'On-Grid',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildTypeRadio(
                SolarSystemType.hybrid,
                _isBangla ? 'হাইব্রিড' : 'Hybrid',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildTypeRadio(
                SolarSystemType.offGrid,
                _isBangla ? 'অফ-গ্রিড' : 'Off-Grid',
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isBangla ? 'প্যানেল দক্ষতা' : 'Efficiency',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightInputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: DropdownButton<double>(
                        value: _selectedModuleEfficiency,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightCardBg,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.accentCyan
                              : const Color(0xFF0284C7),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 0.170,
                            child: Text('17.0% (Poly)'),
                          ),
                          DropdownMenuItem(
                            value: 0.190,
                            child: Text('19.0% (Mono)'),
                          ),
                          DropdownMenuItem(
                            value: 0.215,
                            child: Text('21.5% (PERC)'),
                          ),
                          DropdownMenuItem(
                            value: 0.225,
                            child: Text('22.5% (TOPCon)'),
                          ),
                          DropdownMenuItem(
                            value: 0.235,
                            child: Text('23.5% (HJT)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedModuleEfficiency = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isBangla ? 'মডিউল ক্ষমতা' : 'Rating',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '($_selectedModuleWatt W)',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.solarGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightInputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: candidateWatts.contains(_selectedModuleWatt)
                              ? _selectedModuleWatt
                              : candidateWatts.first,
                          isExpanded: true,
                          dropdownColor: isDark
                              ? AppColors.darkInputBg
                              : AppColors.lightCardBg,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.accentCyan
                                : const Color(0xFF0284C7),
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                          items: candidateWatts.map((w) {
                            return DropdownMenuItem<int>(
                              value: w,
                              child: Text('$w Watt'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedModuleWatt = val;
                                _userManuallyChangedWatt = true;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedSystemType != SolarSystemType.gridTied) ...[
            const SizedBox(height: 14),
            Text(
              _isBangla ? 'ব্যাটারির ধরন (Technology):' : 'Battery Technology:',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildBatteryChemistryChip(
                  BatteryChemistry.leadAcid,
                  _isBangla ? 'লেড-এসিড' : 'Lead-Acid',
                  _isBangla ? 'DoD ৫০%' : '50% DoD',
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildBatteryChemistryChip(
                  BatteryChemistry.tubular,
                  _isBangla ? 'টিউবুলার' : 'Tubular',
                  _isBangla ? 'DoD ৭৫%' : '75% DoD',
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildBatteryChemistryChip(
                  BatteryChemistry.lithium,
                  _isBangla ? 'লিথিয়াম LiFePO₄' : 'Lithium',
                  _isBangla ? 'DoD ৮৫%' : '85% DoD',
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isBangla ? 'কাঙ্ক্ষিত ব্যাটারি ব্যাকআপ' : 'Required Backup',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '$_backupHours ${_isBangla ? "ঘণ্টা" : "Hours"}',
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.purpleAccent,
                thumbColor: Colors.purpleAccent,
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _backupHours.toDouble(),
                min: 2,
                max: 12,
                divisions: 10,
                onChanged: (v) => setState(() => _backupHours = v.round()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatteryChemistryChip(
    BatteryChemistry chem,
    String title,
    String subtitle,
    bool isDark,
  ) {
    final bool isSelected = _selectedBatteryChemistry == chem;
    final activeColor = isDark ? AppColors.accentCyan : AppColors.energyGreen;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedBatteryChemistry = chem),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.16)
                : (isDark ? AppColors.darkInputBg : AppColors.lightInputBg),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : activeColor)
                      : (isDark ? Colors.white70 : AppColors.lightTextPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeRadio(SolarSystemType type, String title, bool isDark) {
    final bool isSelected = _selectedSystemType == type;
    final Color activeColor = isDark
        ? AppColors.accentCyan
        : AppColors.energyGreen;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSystemType = type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : (isDark ? AppColors.darkInputBg : AppColors.lightInputBg),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkInputBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProposalSummaryDialog({
    required double dailyDemandKwh,
    required double capacityKwp,
    required int totalPanels,
    required double roofAreaSqFt,
    required double inverterKw,
    required double batteryBankKwh,
    required int strings,
    required int panelsPerString,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.solar_power_rounded,
              color: isDark ? AppColors.accentCyan : AppColors.energyGreen,
            ),
            const SizedBox(width: 8),
            Text(
              _isBangla ? 'সিস্টেম ডিজাইন প্রপোজাল' : 'System Design Proposal',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow(
                _isBangla ? 'দৈনিক লক্ষ্যমাত্রা' : 'Daily Target',
                '${dailyDemandKwh.toStringAsFixed(1)} kWh/day',
                isDark: isDark,
              ),
              _buildSummaryRow(
                _isBangla ? 'ডিসি ক্যাপাসিটি' : 'DC Solar Capacity',
                '${capacityKwp.toStringAsFixed(2)} kWp',
                isDark: isDark,
              ),
              _buildSummaryRow(
                _isBangla ? 'মডিউল স্পেসিফিকেশন' : 'Module Rating',
                '$totalPanels pcs × $_selectedModuleWatt W',
                isDark: isDark,
              ),
              _buildSummaryRow(
                _isBangla ? 'স্ট্রিং কনফিগারেশন' : 'String Setup',
                '$strings Strings × $panelsPerString Panels',
                isDark: isDark,
              ),
              _buildSummaryRow(
                _isBangla ? 'প্রস্তাবিত ইনভার্টার' : 'Inverter Capacity',
                _selectedSystemType == SolarSystemType.gridTied
                    ? '${inverterKw.toStringAsFixed(1)} kW (Grid-Tied)'
                    : '≥ ${(inverterKw * 1000).toInt()} VA',
                isDark: isDark,
              ),
              _buildSummaryRow(
                _isBangla ? 'প্রয়োজনীয় নেট জায়গা' : 'Required Net Area',
                '${roofAreaSqFt.toStringAsFixed(0)} sq.ft',
                isDark: isDark,
              ),
              if (_selectedSystemType != SolarSystemType.gridTied)
                _buildSummaryRow(
                  _isBangla ? 'ব্যাটারি ব্যাংক' : 'Battery Bank',
                  '${batteryBankKwh.toStringAsFixed(1)} kWh',
                  isDark: isDark,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _isBangla ? 'বন্ধ করুন' : 'Close',
              style: TextStyle(
                color: isDark ? AppColors.accentCyan : AppColors.energyGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class SeasonalComparisonChart extends StatelessWidget {
  final Map<String, double> monthlyPsh;
  final double capacityKwp;
  final double effectivePR;
  final double targetDailyKwh;
  final bool isDark;

  const SeasonalComparisonChart({
    super.key,
    required this.monthlyPsh,
    required this.capacityKwp,
    required this.effectivePR,
    required this.targetDailyKwh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, double> monthlyGen = {};
    for (var entry in monthlyPsh.entries) {
      monthlyGen[entry.key] = capacityKwp * entry.value * effectivePR;
    }

    final double maxVal = math.max(
      targetDailyKwh * 1.3,
      monthlyGen.values.isNotEmpty
          ? monthlyGen.values.reduce(math.max) * 1.15
          : 10.0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double targetY =
            constraints.maxHeight -
            18 -
            (targetDailyKwh / maxVal) * (constraints.maxHeight - 18);

        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: targetY.clamp(0.0, constraints.maxHeight - 20),
              child: CustomPaint(
                size: Size(constraints.maxWidth, 2),
                painter: DashedLinePainter(color: AppColors.alertRed),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: monthlyGen.entries.map((entry) {
                      final double barRatio = (entry.value / maxVal).clamp(
                        0.05,
                        1.0,
                      );
                      final bool isSurplus = entry.value >= targetDailyKwh;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                entry.value.toStringAsFixed(0),
                                style: TextStyle(
                                  color: isSurplus
                                      ? AppColors.energyGreen
                                      : AppColors.solarGold,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                height: (constraints.maxHeight - 32) * barRatio,
                                decoration: BoxDecoration(
                                  color: isSurplus
                                      ? (isDark
                                            ? AppColors.accentCyan
                                            : const Color(0xFF0284C7))
                                      : AppColors.solarGold.withValues(
                                          alpha: 0.8,
                                        ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: monthlyGen.keys.map((m) {
                    return Expanded(
                      child: Text(
                        m.substring(0, 1),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : AppColors.lightTextSecondary,
                          fontSize: 9,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    const double dashWidth = 4.0;
    const double dashSpace = 3.0;
    double startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
