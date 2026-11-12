import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/app_colors.dart';
import '../models/system_sizing_params.dart';
import '../services/solar_calculation_service.dart';
import '../services/solar_radiation_service.dart';
import '../services/tariff_config_service.dart';
import '../widgets/theme_toggle_button.dart';
import 'budget_load_planner_screen.dart';
import '../widgets/app_bar_title.dart';

enum BatteryChemistry { leadAcid, tubular, lithium }

class CurrencyService {
  static double _cachedUsdToBdt = 120.0;
  static DateTime? _lastFetchTime;

  static Future<double> getUsdToBdtRate() async {
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inHours < 12) {
      return _cachedUsdToBdt;
    }

    try {
      final url = Uri.parse('https://open.er-api.com/v6/latest/USD');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = data['rates']?['BDT'];
        if (rate != null) {
          _cachedUsdToBdt = (rate as num).toDouble();
          _lastFetchTime = DateTime.now();
        }
      }
    } catch (_) {}
    return _cachedUsdToBdt;
  }
}

class CurrencyFormatter {
  static String formatBdt(num amount, {bool showSymbol = true}) {
    final int rounded = amount.round();
    final String str = rounded.toString();

    String formatted;
    if (str.length <= 3) {
      formatted = str;
    } else {
      final String lastThree = str.substring(str.length - 3);
      final String remaining = str.substring(0, str.length - 3);

      final String formattedRemaining = remaining.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      formatted = '$formattedRemaining,$lastThree';
    }

    return showSymbol ? '৳ $formatted' : formatted;
  }

  static String formatUsd(
    num amount, {
    bool showSymbol = true,
    int decimals = 0,
  }) {
    final String fixedStr = amount.toStringAsFixed(decimals);
    final List<String> parts = fixedStr.split('.');

    final String integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    final String formatted = parts.length > 1
        ? '$integerPart.${parts[1]}'
        : integerPart;
    return showSymbol ? '\$ $formatted' : formatted;
  }

  static String format(num amount, bool isBangla, {int decimals = 0}) {
    return isBangla ? formatBdt(amount) : formatUsd(amount, decimals: decimals);
  }
}

class MaxValueTextInputFormatter extends TextInputFormatter {
  final double maxValue;

  MaxValueTextInputFormatter(this.maxValue);

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

class CostBasedSolarScreen extends StatefulWidget {
  final bool isBangla;
  final VoidCallback? onToggleLanguage;

  const CostBasedSolarScreen({
    super.key,
    this.isBangla = true,
    this.onToggleLanguage,
  });

  @override
  State<CostBasedSolarScreen> createState() => _CostBasedSolarScreenState();
}

class _CostBasedSolarScreenState extends State<CostBasedSolarScreen> {
  late bool _isBangla;

  double _usdToBdtRate = 120.0;
  bool _isLoadingRate = false;
  bool _isExportingPdf = false;

  final TextEditingController _budgetController = TextEditingController();
  final FocusNode _budgetFocusNode = FocusNode();

  SolarSystemType _selectedSystemType = SolarSystemType.gridTied;
  BatteryChemistry _selectedBatteryChemistry = BatteryChemistry.tubular;
  double _costPerWatt = 75.0;

  double _selectedModuleEfficiency = 0.215;
  int _selectedModuleWatt = 550;
  bool _userManuallyChangedWatt = false;

  bool _isLoadingNasa = false;
  SolarRadiationResult? _climateData;
  TariffConfig _tariffConfig = TariffConfig.defaultConfig();

  List<PlannerApplianceItem>? _configuredPlannerItems;

  static const double _defaultLat = 23.8103;
  static const double _defaultLon = 90.4125;

  static const double minBudgetBdt = 5000.0;
  static const double maxBudgetBdt = 4000000.0;
  static const double minBudgetUsd = 40.0;
  static const double maxBudgetUsd = 35000.0;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _initDefaultValues();
    _initTariffAndData();

    _budgetFocusNode.addListener(() {
      if (!_budgetFocusNode.hasFocus) {
        _clampAndFormatInput();
      }
    });
  }

  void _initDefaultValues() {
    if (_isBangla) {
      _budgetController.text = '250000';
      _costPerWatt = _getDefaultRateForType(
        _selectedSystemType,
        _selectedBatteryChemistry,
        isBangla: true,
      );
    } else {
      _budgetController.text = '2000';
      _costPerWatt = _getDefaultRateForType(
        _selectedSystemType,
        _selectedBatteryChemistry,
        isBangla: false,
      );
    }
    _autoSuggestPanelWatt(250000);
  }

  Future<void> _initTariffAndData() async {
    final config = await TariffConfigService.getActiveConfig();
    if (mounted) {
      setState(() {
        _tariffConfig = config;
        _costPerWatt = _getDefaultRateForType(
          _selectedSystemType,
          _selectedBatteryChemistry,
          isBangla: _isBangla,
        );
      });
    }
    _fetchDynamicRateAndData();
  }

  void _autoSuggestPanelWatt(double budgetBdt) {
    if (_userManuallyChangedWatt) return;
    if (budgetBdt <= 30000) {
      _selectedModuleWatt = 50;
    } else if (budgetBdt <= 80000) {
      _selectedModuleWatt = 150;
    } else if (budgetBdt <= 200000) {
      _selectedModuleWatt = 330;
    } else {
      _selectedModuleWatt = 550;
    }
  }

  void _clampAndFormatInput() {
    final double currentVal =
        double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0.0;
    final double minVal = _isBangla ? minBudgetBdt : minBudgetUsd;
    final double maxVal = _isBangla ? maxBudgetBdt : maxBudgetUsd;

    if (currentVal < minVal) {
      setState(() {
        _budgetController.text = minVal.toStringAsFixed(0);
        final bdtVal = _isBangla ? minVal : minVal * _usdToBdtRate;
        _autoSuggestPanelWatt(bdtVal);
      });
    } else if (currentVal > maxVal) {
      setState(() {
        _budgetController.text = maxVal.toStringAsFixed(0);
        final bdtVal = _isBangla ? maxVal : maxVal * _usdToBdtRate;
        _autoSuggestPanelWatt(bdtVal);
      });
    }
  }

  Future<void> _fetchDynamicRateAndData() async {
    setState(() => _isLoadingRate = true);
    final rate = await CurrencyService.getUsdToBdtRate();
    if (mounted) {
      setState(() {
        _usdToBdtRate = rate;
        _isLoadingRate = false;
      });
    }
    _fetchLocationClimateData();
  }

  double _getDefaultRateForType(
    SolarSystemType type,
    BatteryChemistry chemistry, {
    required bool isBangla,
  }) {
    if (isBangla) {
      switch (type) {
        case SolarSystemType.gridTied:
          return _tariffConfig.costPerWatt > 0
              ? _tariffConfig.costPerWatt
              : 75.0;
        case SolarSystemType.hybrid:
          switch (chemistry) {
            case BatteryChemistry.leadAcid:
              return 95.0;
            case BatteryChemistry.tubular:
              return 105.0;
            case BatteryChemistry.lithium:
              return 135.0;
          }
        case SolarSystemType.offGrid:
          switch (chemistry) {
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
          switch (chemistry) {
            case BatteryChemistry.leadAcid:
              return 0.80;
            case BatteryChemistry.tubular:
              return 0.90;
            case BatteryChemistry.lithium:
              return 1.15;
          }
        case SolarSystemType.offGrid:
          switch (chemistry) {
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
    required SolarSystemType systemType,
    required BatteryChemistry chemistry,
  }) {
    if (baseAnnualSavings <= 0 || totalCost <= 0) return 0.0;

    double cumulativeSavings = 0.0;
    double currentYearSavings = baseAnnualSavings;

    double batteryUnitRatio;
    switch (chemistry) {
      case BatteryChemistry.leadAcid:
        batteryUnitRatio = systemType == SolarSystemType.hybrid ? 0.20 : 0.24;
        break;
      case BatteryChemistry.tubular:
        batteryUnitRatio = systemType == SolarSystemType.hybrid ? 0.24 : 0.28;
        break;
      case BatteryChemistry.lithium:
        batteryUnitRatio = systemType == SolarSystemType.hybrid ? 0.38 : 0.42;
        break;
    }
    final double batteryCost = totalCost * batteryUnitRatio;

    for (int year = 1; year <= 25; year++) {
      double yearNetSavings = currentYearSavings;

      if (systemType != SolarSystemType.gridTied) {
        if (chemistry == BatteryChemistry.leadAcid && (year % 3 == 0)) {
          yearNetSavings -= batteryCost * 0.70;
        } else if (chemistry == BatteryChemistry.tubular && (year % 4 == 0)) {
          yearNetSavings -= batteryCost * 0.70;
        } else if (chemistry == BatteryChemistry.lithium && year == 12) {
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
      currentYearSavings *= 0.995;
    }

    return 25.0;
  }

  void _onLanguageChanged() {
    setState(() {
      _isBangla = !_isBangla;
      final double currentBudget =
          double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0.0;
      if (_isBangla) {
        _budgetController.text = (currentBudget * _usdToBdtRate)
            .toStringAsFixed(0);
        _costPerWatt = _costPerWatt * _usdToBdtRate;
      } else {
        _budgetController.text = (currentBudget / _usdToBdtRate)
            .toStringAsFixed(0);
        _costPerWatt = _costPerWatt / _usdToBdtRate;
      }
    });
    widget.onToggleLanguage?.call();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _budgetFocusNode.dispose();
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

  String _getBatteryTitle() {
    switch (_selectedBatteryChemistry) {
      case BatteryChemistry.leadAcid:
        return _isBangla ? 'লেড-এসিড ব্যাটারি' : 'Lead-Acid Battery';
      case BatteryChemistry.tubular:
        return _isBangla ? 'টিউবুলার ডিপ-সাইকেল' : 'Tubular Deep-Cycle';
      case BatteryChemistry.lithium:
        return _isBangla ? 'লিথিয়াম LiFePO₄' : 'Lithium LiFePO4';
    }
  }

  // 🌟 ক্যানভাস-ভিত্তিক হাই-রেজোলিউশন বাংলা রেন্ডারার (ফন্ট মিসিং সমস্যা স্থায়ী সমাধান)
  Future<Uint8List> _renderCanvasReportImage({
    required double totalBudget,
    required double installableCapacityKwp,
    required int totalPanels,
    required double netAreaSqFt,
    required double netAreaSqM,
    required double dailyGenerationKwh,
    required double monthlyGenerationKwh,
    required double annualSavings,
    required double paybackYears,
    required double co2OffsetKg,
    required int equivalentTrees,
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
          ? 'সূর্য বিদ্যুৎ — বাজেটভিত্তিক সোলার সম্ভাব্যতা রিপোর্ট'
          : 'SolEctricity — Budget Sizing Feasibility Report',
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
        't': _isBangla ? 'বিনিয়োগ বাজেট' : 'Total Budget',
        'v': CurrencyFormatter.format(totalBudget, _isBangla),
        'c': const Color(0xFF0284C7),
      },
      {
        't': _isBangla ? 'সিস্টেম ক্ষমতা' : 'DC Capacity',
        'v': '${installableCapacityKwp.toStringAsFixed(2)} kWp',
        'c': const Color(0xFF0D9488),
      },
      {
        't': _isBangla ? 'দৈনিক উৎপাদন' : 'Daily Output',
        'v': '${dailyGenerationKwh.toStringAsFixed(1)} kWh',
        'c': const Color(0xFFD97706),
      },
      {
        't': _isBangla ? 'বিনিয়োগ ফেরত' : 'Payback Period',
        'v': paybackYears > 0
            ? '${paybackYears.toStringAsFixed(1)} ${_isBangla ? "বছর" : "Yrs"}'
            : 'N/A',
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
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: metrics[i]['c'] as Color,
      );
    }

    // টেবিল বিবরণ
    double curY = 340;
    drawText(
      _isBangla
          ? '১. সিস্টেম ডিজাইন ও সাইজিং স্পেসিফিকেশন'
          : '1. System Sizing & Technical Specifications',
      60,
      curY,
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0F766E),
    );
    curY += 38;

    String sysName;
    if (_selectedSystemType == SolarSystemType.gridTied) {
      sysName = _isBangla
          ? 'অন-গ্রিড (নেট-মিটারিং)'
          : 'Grid-Tied (Net-Metered)';
    } else if (_selectedSystemType == SolarSystemType.hybrid) {
      sysName = _isBangla
          ? 'হাইব্রিড (${_getBatteryTitle()})'
          : 'Hybrid (${_getBatteryTitle()})';
    } else {
      sysName = _isBangla
          ? 'অফ-গ্রিড স্ট্যান্ডঅ্যালন (${_getBatteryTitle()})'
          : 'Off-Grid (${_getBatteryTitle()})';
    }

    final rows = [
      [_isBangla ? 'সিস্টেম আর্কিটেকচার' : 'System Architecture', sysName],
      [
        _isBangla ? 'সোলার প্যানেলের একক ক্ষমতা' : 'PV Module Rating',
        '$_selectedModuleWatt Watt (${(_selectedModuleEfficiency * 100).toStringAsFixed(1)}% Efficiency)',
      ],
      [
        _isBangla ? 'মোট প্যানেল সংখ্যা' : 'Total Solar Modules',
        _isBangla ? '$totalPanels টি প্যানেল' : '$totalPanels Modules',
      ],
      if (_selectedSystemType != SolarSystemType.gridTied)
        [
          _isBangla ? 'ব্যাটারি প্রযুক্তি ও রসায়ন' : 'Battery Technology',
          _getBatteryTitle(),
        ],
      [
        _isBangla ? 'প্রয়োজনীয় ছাদ / জমির জায়গা' : 'Required Shadow-Free Area',
        '${netAreaSqFt.toStringAsFixed(0)} sq.ft (≈ ${netAreaSqM.toStringAsFixed(1)} m²)',
      ],
      [
        _isBangla ? 'মাসিক প্রাক্কলিত উৎপাদন' : 'Monthly Generation Yield',
        '${monthlyGenerationKwh.toStringAsFixed(0)} ${_isBangla ? "ইউনিট / মাস" : "kWh / Month"}',
      ],
      [
        _isBangla ? 'বাৎসরিক বিদ্যুৎ সাশ্রয়' : 'Annual Electricity Savings',
        CurrencyFormatter.format(annualSavings, _isBangla),
      ],
      [
        _isBangla ? 'টার্নকি বাজেট দর' : 'Turnkey Unit Rate',
        _isBangla
            ? '৳ ${_costPerWatt.toStringAsFixed(0)} / Wp'
            : '\$ ${_costPerWatt.toStringAsFixed(2)} / Wp',
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

    // উপাদানভিত্তিক খরচ বিভাজন
    curY += 15;
    drawText(
      _isBangla
          ? '২. টার্নকি বাজেটের উপাদানভিত্তিক খরচ বণ্টন (BOM)'
          : '2. Turnkey Bill of Materials Breakdown (BOM)',
      60,
      curY,
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0F766E),
    );
    curY += 38;

    double pRatio = 0.45;
    double invRatio = 0.20;
    double batRatio = 0.0;
    double bosRatio = 0.35;

    if (_selectedSystemType == SolarSystemType.hybrid) {
      switch (_selectedBatteryChemistry) {
        case BatteryChemistry.leadAcid:
          pRatio = 0.38;
          invRatio = 0.22;
          batRatio = 0.20;
          bosRatio = 0.20;
          break;
        case BatteryChemistry.tubular:
          pRatio = 0.36;
          invRatio = 0.22;
          batRatio = 0.24;
          bosRatio = 0.18;
          break;
        case BatteryChemistry.lithium:
          pRatio = 0.30;
          invRatio = 0.18;
          batRatio = 0.38;
          bosRatio = 0.14;
          break;
      }
    } else if (_selectedSystemType == SolarSystemType.offGrid) {
      switch (_selectedBatteryChemistry) {
        case BatteryChemistry.leadAcid:
          pRatio = 0.37;
          invRatio = 0.18;
          batRatio = 0.24;
          bosRatio = 0.21;
          break;
        case BatteryChemistry.tubular:
          pRatio = 0.35;
          invRatio = 0.18;
          batRatio = 0.28;
          bosRatio = 0.19;
          break;
        case BatteryChemistry.lithium:
          pRatio = 0.28;
          invRatio = 0.16;
          batRatio = 0.42;
          bosRatio = 0.14;
          break;
      }
    }

    final bomRows = [
      [
        _isBangla ? 'সোলার পিভি মডিউল' : 'Solar PV Modules',
        '${(pRatio * 100).toInt()}%',
        CurrencyFormatter.format(totalBudget * pRatio, _isBangla),
      ],
      [
        _isBangla ? 'ইনভার্টার ও প্রটেকশন ইউনিট' : 'Inverter & Protection',
        '${(invRatio * 100).toInt()}%',
        CurrencyFormatter.format(totalBudget * invRatio, _isBangla),
      ],
      if (_selectedSystemType != SolarSystemType.gridTied)
        [
          _isBangla ? 'ব্যাটারি স্টোরেজ ব্যাংক' : 'Battery Storage Bank',
          '${(batRatio * 100).toInt()}%',
          CurrencyFormatter.format(totalBudget * batRatio, _isBangla),
        ],
      [
        _isBangla
            ? 'মাউন্টিং স্ট্রাকচার, ওয়্যারিং ও লেবার'
            : 'Mounting, BOS & Labor',
        '${(bosRatio * 100).toInt()}%',
        CurrencyFormatter.format(totalBudget * bosRatio, _isBangla),
      ],
    ];

    for (var r in bomRows) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(60, curY, width - 120, 44),
          const Radius.circular(6),
        ),
        Paint()
          ..color = (bomRows.indexOf(r) % 2 == 0)
              ? const Color(0xFFF1F5F9)
              : Colors.white,
      );
      drawText(
        r[0],
        76,
        curY + 11,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF334155),
      );
      drawText(
        r[1],
        480,
        curY + 11,
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF64748B),
      );
      drawText(
        r[2],
        800,
        curY + 11,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF047857),
      );
      curY += 48;
    }

    // পরিবেশগত স্বীকৃতি বক্স
    curY += 15;
    final noteRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(60, curY, width - 120, 100),
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
          ? 'পরিবেশগত স্বীকৃতি ও কার্বন হ্রাস:'
          : 'Environmental & Carbon Offset Benefit:',
      80,
      curY + 16,
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF065F46),
    );
    drawText(
      _isBangla
          ? 'এই সিস্টেমে প্রতি বছর ${(co2OffsetKg).toStringAsFixed(0)} কেজি CO₂ গ্যাস নির্গমন বন্ধ হবে যা বাৎসরিক $equivalentTrees টি বৃক্ষরোপণের সমতুল্য। ব্যাটারি প্রতিস্থাপন প্রভিশন সমন্বয় করে পে-ব্যাক সময় নির্ধারিত হয়েছে।'
          : 'Estimated annual carbon offset is ${(co2OffsetKg).toStringAsFixed(0)} kg CO2, equivalent to planting $equivalentTrees trees. Battery life-cycle replacement provision has been factored into the payback calculation.',
      80,
      curY + 44,
      fontSize: 13,
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

  Future<void> _generateAndShareCostReport({
    required double totalBudget,
    required double installableCapacityKwp,
    required int totalPanels,
    required double netAreaSqFt,
    required double netAreaSqM,
    required double dailyGenerationKwh,
    required double monthlyGenerationKwh,
    required double annualSavings,
    required double paybackYears,
    required double co2OffsetKg,
    required int equivalentTrees,
  }) async {
    setState(() => _isExportingPdf = true);

    try {
      final imgBytes = await _renderCanvasReportImage(
        totalBudget: totalBudget,
        installableCapacityKwp: installableCapacityKwp,
        totalPanels: totalPanels,
        netAreaSqFt: netAreaSqFt,
        netAreaSqM: netAreaSqM,
        dailyGenerationKwh: dailyGenerationKwh,
        monthlyGenerationKwh: monthlyGenerationKwh,
        annualSavings: annualSavings,
        paybackYears: paybackYears,
        co2OffsetKg: co2OffsetKg,
        equivalentTrees: equivalentTrees,
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
            'SolEctricity_Budget_Report_${_isBangla ? "BN" : "EN"}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String currencySymbol = _isBangla ? '৳' : '\$';
    final double rawBudget =
        double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0.0;

    final double maxB = _isBangla ? maxBudgetBdt : maxBudgetUsd;
    final double totalBudget = rawBudget.clamp(0.0, maxB);

    final double budgetInBdt = _isBangla
        ? totalBudget
        : totalBudget * _usdToBdtRate;

    final double installableCapacityKwp = (_costPerWatt > 0 && totalBudget > 0)
        ? (totalBudget / _costPerWatt) / 1000.0
        : 0.0;

    final double totalSystemWatts = installableCapacityKwp * 1000.0;

    int calculatedPanels = 0;
    if (totalSystemWatts > 0) {
      calculatedPanels = (totalSystemWatts / _selectedModuleWatt).floor();
      if (calculatedPanels < 1 &&
          totalBudget >= (_isBangla ? minBudgetBdt : minBudgetUsd)) {
        calculatedPanels = 1;
      }
    }
    final int totalPanels = calculatedPanels;

    final double psh =
        _climateData?.peakSunHours ?? SolarRadiationService.defaultPsh;
    final double ambTemp = _climateData?.ambientTemp ?? 26.0;
    final double tempDerate = SolarCalculationService.calculateTempDerateFactor(
      ambTemp,
    );

    // ৩ ধরনের ব্যাটারি অনুযায়ী পারফরম্যান্স রেশিও (PR)
    double basePR = 0.80;
    if (_selectedSystemType != SolarSystemType.gridTied) {
      switch (_selectedBatteryChemistry) {
        case BatteryChemistry.leadAcid:
          basePR = 0.70;
          break;
        case BatteryChemistry.tubular:
          basePR = 0.74;
          break;
        case BatteryChemistry.lithium:
          basePR = 0.80;
          break;
      }
    }
    final double effectivePR = basePR * tempDerate;

    final double dailyGenerationKwh =
        installableCapacityKwp * psh * effectivePR;
    final double monthlyGenerationKwh = dailyGenerationKwh * 30;
    final double annualGenerationKwh = dailyGenerationKwh * 365;

    final double dynamicPF =
        SolarCalculationService.calculateDynamicPackingFactor(_defaultLat);
    final double netAreaSqM = installableCapacityKwp > 0
        ? (installableCapacityKwp / (_selectedModuleEfficiency * dynamicPF))
        : 0.0;
    final double netAreaSqFt = netAreaSqM * 10.7639;

    final double electricityTariff = _isBangla
        ? (_tariffConfig.residential > 0 ? _tariffConfig.residential : 8.50)
        : 0.12;
    final double annualSavings = annualGenerationKwh * electricityTariff;

    final double paybackYears = _calculateRealisticPayback(
      totalCost: totalBudget,
      baseAnnualSavings: annualSavings,
      systemType: _selectedSystemType,
      chemistry: _selectedBatteryChemistry,
    );

    return Scaffold(
      appBar: AppBar(
        title: TwoLineAppBarTitle(
          title: _isBangla ? 'বাজেটভিত্তিক সাইজিং' : 'Budget-Based Sizing',
          subtitle: _isBangla
              ? 'বিনিয়োগ অনুযায়ী সিস্টেম ও রিটার্ন'
              : 'Investment Sizing & ROI',
        ),
        actions: [
          IconButton(
            tooltip: _isBangla
                ? 'PDF রিপোর্ট ডাউনলোড/শেয়ার'
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
                : () => _generateAndShareCostReport(
                    totalBudget: totalBudget,
                    installableCapacityKwp: installableCapacityKwp,
                    totalPanels: totalPanels,
                    netAreaSqFt: netAreaSqFt,
                    netAreaSqM: netAreaSqM,
                    dailyGenerationKwh: dailyGenerationKwh,
                    monthlyGenerationKwh: monthlyGenerationKwh,
                    annualSavings: annualSavings,
                    paybackYears: paybackYears,
                    co2OffsetKg: annualGenerationKwh * 0.62,
                    equivalentTrees: ((annualGenerationKwh * 0.62) / 20.0)
                        .round(),
                  ),
          ),
          IconButton(
            onPressed: _onLanguageChanged,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isBangla ? 'ENG (\$)' : 'বাংলা (৳)',
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
              _buildBudgetInputCard(currencySymbol, isDark),
              const SizedBox(height: 14),
              _buildRateAndTypeCard(currencySymbol, isDark),
              const SizedBox(height: 14),
              _buildModuleSelectorCard(budgetInBdt, isDark),
              const SizedBox(height: 18),
              Text(
                _isBangla
                    ? 'বাজেট অনুযায়ী সম্ভাব্য সিস্টেম'
                    : 'Affordable Solar System',
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
                    title: _isBangla ? 'ইনস্টলযোগ্য ক্ষমতা' : 'System Capacity',
                    value: '${installableCapacityKwp.toStringAsFixed(2)} kWp',
                    subtitle: _isBangla
                        ? 'প্যানেল: $totalPanels টি ($_selectedModuleWatt W)'
                        : 'Panels: $totalPanels pcs ($_selectedModuleWatt W)',
                    icon: Icons.flash_on_rounded,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildResultStatCard(
                    title: _isBangla ? 'প্রয়োজনীয় ছাদ/জমি' : 'Required Area',
                    value: '${netAreaSqFt.toStringAsFixed(0)} sq.ft',
                    subtitle: '≈ ${netAreaSqM.toStringAsFixed(1)} m²',
                    icon: Icons.roofing_rounded,
                    color: isDark
                        ? AppColors.energyGreen
                        : const Color(0xFF059669),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildResultStatCard(
                    title: _isBangla ? 'দৈনিক উৎপাদন' : 'Daily Output',
                    value: '${dailyGenerationKwh.toStringAsFixed(1)} kWh',
                    subtitle: _isBangla
                        ? 'মাসিক: ${monthlyGenerationKwh.toStringAsFixed(0)} ইউনিট'
                        : 'Monthly: ${monthlyGenerationKwh.toStringAsFixed(0)} Units',
                    icon: Icons.wb_sunny_rounded,
                    color: AppColors.solarGold,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildResultStatCard(
                    title: _isBangla
                        ? 'বিনিয়োগ ফেরত (Payback)'
                        : 'Est. Payback Time',
                    value: paybackYears > 0
                        ? '${paybackYears.toStringAsFixed(1)} ${_isBangla ? "বছর" : "Years"}'
                        : 'N/A',
                    subtitle: _isBangla
                        ? 'বাৎসরিক সাশ্রয়: ${CurrencyFormatter.format(annualSavings, _isBangla)}'
                        : 'Annual Savings: ${CurrencyFormatter.format(annualSavings, _isBangla)}',
                    icon: Icons.savings_rounded,
                    color: isDark ? Colors.tealAccent : const Color(0xFF0D9488),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              InkWell(
                onTap: () async {
                  final double dailyWh = dailyGenerationKwh * 1000.0;
                  final result =
                      await Navigator.push<List<PlannerApplianceItem>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BudgetLoadPlannerScreen(
                            totalBudget: totalBudget,
                            capacityKwp: installableCapacityKwp,
                            dailyGenerationWh: dailyWh,
                            systemType: _selectedSystemType,
                            isBangla: _isBangla,
                            inverterEfficiencyPercent: 90.0,
                            initialItems: _configuredPlannerItems,
                          ),
                        ),
                      );
                  if (result != null) {
                    setState(() => _configuredPlannerItems = result);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkInputBg
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.energyGreen.withValues(alpha: 0.4)
                          : const Color(0xFF86EFAC),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.energyGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.checklist_rtl_rounded,
                          color: AppColors.energyGreen,
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
                                  ? 'এই বাজেটে লোড ব্যবহার পরিকল্পনা'
                                  : 'Plan Appliances for this Budget',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isBangla
                                  ? 'কোন কোন লাইট, ফ্যান, টিভি চলবে তা মেলাতে ট্যাপ করুন'
                                  : 'Tap to configure specific lights, fans & TV to run',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.energyGreen,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              if (paybackYears > 0 && paybackYears <= 25)
                _buildPaybackTimelineCard(paybackYears, isDark),
              const SizedBox(height: 14),
              _buildCostBreakdownCard(totalBudget, isDark),
              const SizedBox(height: 14),
              _buildEnvironmentalImpactCard(
                annualGenerationKwh * 0.62,
                ((annualGenerationKwh * 0.62) / 20.0).round(),
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClimateHeader(double psh, double ambTemp, bool isDark) {
    final String locationText =
        (_climateData != null && _climateData!.placeName.isNotEmpty)
        ? '📍 ${_climateData!.placeName}'
        : (_isBangla ? 'নাসা ক্লাইমেট ডেটা' : 'NASA Climate Data');

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.accentCyan
                                    : AppColors.energyGreen)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isLoadingRate
                            ? 'Syncing...'
                            : '1 USD ≈ ${_usdToBdtRate.toStringAsFixed(1)} BDT',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.accentCyan
                              : AppColors.energyGreen,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
              onPressed: _fetchDynamicRateAndData,
              tooltip: _isBangla ? 'রিফ্রেশ' : 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetInputCard(String currencySymbol, bool isDark) {
    final double currentVal =
        double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0.0;
    final double maxSliderVal = _isBangla ? maxBudgetBdt : maxBudgetUsd;
    final double minSliderVal = _isBangla ? minBudgetBdt : minBudgetUsd;

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
                _isBangla ? 'আপনার মোট বাজেট' : 'Total Investment Budget',
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
                  CurrencyFormatter.format(currentVal, _isBangla),
                  style: const TextStyle(
                    color: AppColors.energyGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _budgetController,
            focusNode: _budgetFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              MaxValueTextInputFormatter(maxSliderVal),
            ],
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val.replaceAll(',', '')) ?? 0.0;
              final bdtVal = _isBangla ? parsed : parsed * _usdToBdtRate;
              setState(() {
                _autoSuggestPanelWatt(bdtVal);
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
              errorText: (currentVal > 0 && currentVal < minSliderVal)
                  ? (_isBangla
                        ? 'বাজেট সর্বনিম্ন ৳ ${minSliderVal.toInt()} হতে হবে'
                        : 'Minimum budget is \$ ${minSliderVal.toInt()}')
                  : null,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Center(
                  widthFactor: 0.0,
                  child: Text(
                    currencySymbol,
                    style: const TextStyle(
                      color: AppColors.energyGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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
              activeTrackColor: AppColors.energyGreen,
              inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
              thumbColor: AppColors.energyGreen,
              trackHeight: 4,
            ),
            child: Slider(
              value: currentVal.clamp(minSliderVal, maxSliderVal),
              min: minSliderVal,
              max: maxSliderVal,
              onChanged: (v) {
                setState(() {
                  _budgetController.text = v.toStringAsFixed(0);
                  final bdtVal = _isBangla ? v : v * _usdToBdtRate;
                  _autoSuggestPanelWatt(bdtVal);
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla ? 'সর্বনিম্ন: ৳ ৫,০০০' : 'Min: \$ 40',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                _isBangla
                    ? 'সর্বোচ্চ: ৳ ৪০,০০,০০০ (SHS সীমা)'
                    : 'Max: \$ 35,000 (SHS Limit)',
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

  Widget _buildRateAndTypeCard(String currencySymbol, bool isDark) {
    final double minRate = _isBangla ? 50.0 : 0.40;
    final double maxRate = _isBangla ? 180.0 : 1.60;

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
                ? 'সিস্টেমের ধরন ও বাজারদর'
                : 'System Architecture & Market Rate',
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

          // 🔋 ৩ ধরনের ব্যাটারি নির্বাচন (হাইব্রিড বা অফ-গ্রিড মোডে)
          if (_selectedSystemType != SolarSystemType.gridTied) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isBangla
                      ? 'ব্যাটারির ধরন (Technology):'
                      : 'Battery Technology:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  _getBatteryTitle(),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.energyGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildBatteryChemistryChip(
                  BatteryChemistry.leadAcid,
                  _isBangla ? 'লেড-এসিড' : 'Lead-Acid',
                  _isBangla ? 'আয়ু ২-৩ বছর' : '2-3 yrs',
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildBatteryChemistryChip(
                  BatteryChemistry.tubular,
                  _isBangla ? 'টিউবুলার' : 'Tubular',
                  _isBangla ? 'আয়ু ৩-৪ বছর' : '3-4 yrs',
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildBatteryChemistryChip(
                  BatteryChemistry.lithium,
                  _isBangla ? 'লিথিয়াম LiFePO₄' : 'Lithium',
                  _isBangla ? 'আয়ু ১০+ বছর' : '10+ yrs',
                  isDark,
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'প্রতি ওয়াট সিস্টেম খরচ'
                    : 'Estimated Cost per Watt',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 11.5,
                ),
              ),
              Text(
                _isBangla
                    ? '${CurrencyFormatter.formatBdt(_costPerWatt)} / W'
                    : '${CurrencyFormatter.formatUsd(_costPerWatt, decimals: 2)} / W',
                style: TextStyle(
                  color: isDark
                      ? AppColors.accentCyan
                      : const Color(0xFF0284C7),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isDark
                  ? AppColors.accentCyan
                  : const Color(0xFF0284C7),
              inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
              thumbColor: isDark
                  ? AppColors.accentCyan
                  : const Color(0xFF0284C7),
              trackHeight: 3,
            ),
            child: Slider(
              value: _costPerWatt.clamp(minRate, maxRate),
              min: minRate,
              max: maxRate,
              onChanged: (v) => setState(() => _costPerWatt = v),
            ),
          ),
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
        onTap: () {
          setState(() {
            _selectedBatteryChemistry = chem;
            _costPerWatt = _getDefaultRateForType(
              _selectedSystemType,
              chem,
              isBangla: _isBangla,
            );
          });
        },
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

  Widget _buildModuleSelectorCard(double budgetBdt, bool isDark) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'প্যানেল নির্বাচন ও সাজেশন'
                    : 'Module Rating & Suggestion',
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
                  color: AppColors.solarGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isBangla
                      ? 'প্রস্তাবিত: $_selectedModuleWatt W'
                      : 'Suggested: $_selectedModuleWatt W',
                  style: const TextStyle(
                    color: AppColors.solarGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isBangla ? 'প্যানেলের ক্ষমতা (Watt)' : 'Panel Wattage',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isBangla ? 'প্যানেল দক্ষতা' : 'Panel Efficiency',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        child: DropdownButton<double>(
                          value: _selectedModuleEfficiency,
                          isExpanded: true,
                          dropdownColor: isDark
                              ? AppColors.darkInputBg
                              : AppColors.lightCardBg,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.accentCyan
                                : const Color(0xFF0284C7),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaybackTimelineCard(double paybackYears, bool isDark) {
    final double paybackRatio = (paybackYears / 25.0).clamp(0.05, 0.95);
    final double freeYears = 25.0 - paybackYears;

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
                    ? '২৫ বছরের রিটার্ন টাইমলাইন'
                    : '25-Year Lifecycle Return',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isBangla ? 'মোট আয়ুষ্কাল: ২৫ বছর' : 'Total Lifecycle: 25 yrs',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (paybackRatio * 100).round(),
                    child: Container(color: Colors.orangeAccent),
                  ),
                  Expanded(
                    flex: ((1.0 - paybackRatio) * 100).round(),
                    child: Container(color: AppColors.energyGreen),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'বিনিয়োগ রিকভারি: ${paybackYears.toStringAsFixed(1)} বছর'
                    : 'Investment Recovery: ${paybackYears.toStringAsFixed(1)} yrs',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 10,
                ),
              ),
              Text(
                _isBangla
                    ? '${freeYears.toStringAsFixed(1)} বছর বিনামূল্যে বিদ্যুৎ'
                    : '${freeYears.toStringAsFixed(1)} Yrs Free Power',
                style: const TextStyle(
                  color: AppColors.energyGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdownCard(double totalBudget, bool isDark) {
    double panelRatio = 0.45;
    double inverterRatio = 0.20;
    double batteryRatio = 0.0;
    double structureBosRatio = 0.35;

    if (_selectedSystemType == SolarSystemType.hybrid) {
      switch (_selectedBatteryChemistry) {
        case BatteryChemistry.leadAcid:
          panelRatio = 0.38;
          inverterRatio = 0.22;
          batteryRatio = 0.20;
          structureBosRatio = 0.20;
          break;
        case BatteryChemistry.tubular:
          panelRatio = 0.36;
          inverterRatio = 0.22;
          batteryRatio = 0.24;
          structureBosRatio = 0.18;
          break;
        case BatteryChemistry.lithium:
          panelRatio = 0.30;
          inverterRatio = 0.18;
          batteryRatio = 0.38;
          structureBosRatio = 0.14;
          break;
      }
    } else if (_selectedSystemType == SolarSystemType.offGrid) {
      switch (_selectedBatteryChemistry) {
        case BatteryChemistry.leadAcid:
          panelRatio = 0.37;
          inverterRatio = 0.18;
          batteryRatio = 0.24;
          structureBosRatio = 0.21;
          break;
        case BatteryChemistry.tubular:
          panelRatio = 0.35;
          inverterRatio = 0.18;
          batteryRatio = 0.28;
          structureBosRatio = 0.19;
          break;
        case BatteryChemistry.lithium:
          panelRatio = 0.28;
          inverterRatio = 0.16;
          batteryRatio = 0.42;
          structureBosRatio = 0.14;
          break;
      }
    }

    final double panelCost = totalBudget * panelRatio;
    final double inverterCost = totalBudget * inverterRatio;
    final double batteryCost = totalBudget * batteryRatio;
    final double structureAndBosCost = totalBudget * structureBosRatio;

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
                    ? 'বাজেট খরচের উপাদানভিত্তিক বিভাজন'
                    : 'Component-wise Cost Distribution',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isBangla ? 'বাজার অনুপাত' : 'Market Share',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            _isBangla ? 'সোলার পিভি প্যানেল' : 'Solar PV Modules',
            panelCost,
            '${(panelRatio * 100).toInt()}%',
            Colors.amberAccent,
            isDark,
          ),
          _buildBreakdownRow(
            _isBangla ? 'ইনভার্টার ও প্রটেকশন' : 'Inverter & Protection',
            inverterCost,
            '${(inverterRatio * 100).toInt()}%',
            Colors.cyanAccent,
            isDark,
          ),
          if (_selectedSystemType != SolarSystemType.gridTied)
            _buildBreakdownRow(
              _getBatteryTitle(),
              batteryCost,
              '${(batteryRatio * 100).toInt()}%',
              Colors.purpleAccent,
              isDark,
            ),
          _buildBreakdownRow(
            _isBangla
                ? 'মাউন্টিং স্ট্রাকচার, ওয়্যারিং ও লেবার'
                : 'Mounting, BOS & Labor',
            structureAndBosCost,
            '${(structureBosRatio * 100).toInt()}%',
            Colors.tealAccent,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double amount,
    String percentage,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '($percentage) ',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
              Text(
                CurrencyFormatter.format(amount, _isBangla),
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentalImpactCard(double co2Kg, int trees, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.energyGreen.withValues(alpha: isDark ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.energyGreen.withValues(alpha: isDark ? 0.2 : 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.energyGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.energyGreen,
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
                      ? 'পরিবেশগত অবদান (বাৎসরিক)'
                      : 'Annual Environmental Impact',
                  style: const TextStyle(
                    color: AppColors.energyGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isBangla
                      ? 'কার্বন হ্রাস: ${co2Kg.toStringAsFixed(0)} kg CO₂ | $trees টি বৃক্ষরোপণের সমতুল্য'
                      : 'CO₂ Offset: ${co2Kg.toStringAsFixed(0)} kg CO₂ | Planting $trees trees',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : AppColors.lightTextSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        onTap: () {
          setState(() {
            _selectedSystemType = type;
            _costPerWatt = _getDefaultRateForType(
              type,
              _selectedBatteryChemistry,
              isBangla: _isBangla,
            );
          });
        },
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
}
