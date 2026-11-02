import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../models/solar_calculation_result.dart';
import '../models/system_sizing_params.dart';
import '../services/pdf_report_service.dart';
import 'widgets/wiring_painters.dart';

class SystemDiagramScreen extends StatefulWidget {
  final SolarCalculationResult result;
  final SystemSizingParams params;
  final bool isBangla;

  const SystemDiagramScreen({
    super.key,
    required this.result,
    required this.params,
    this.isBangla = true,
  });

  @override
  State<SystemDiagramScreen> createState() => _SystemDiagramScreenState();
}

class _SystemDiagramScreenState extends State<SystemDiagramScreen> {
  late bool _isBangla;
  final TransformationController _mainCanvasController =
      TransformationController();
  final GlobalKey _diagramCanvasKey = GlobalKey(); // 👈 ক্যানভাস ক্যাপচার কী
  bool _isLandscape = false;
  bool _isExporting = false;

  static const double vWidth = 1140.0;
  static const double vHeight = 620.0;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
      if (_isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });
  }

  void _resetZoom() {
    _mainCanvasController.value = Matrix4.identity();
  }

  // 📸 ডায়াগ্রাম ক্যানভাসকে ছবিতে ক্যাপচার করার মেথড
  Future<Uint8List?> _captureDiagramPng() async {
    try {
      final boundary =
          _diagramCanvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(
        pixelRatio: 2.0,
      ); // 2x শার্প রেজোলিউশন
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _handlePdfExport() async {
    setState(() => _isExporting = true);
    final diagramBytes = await _captureDiagramPng();
    if (mounted) {
      setState(() => _isExporting = false);
      await PdfReportService.shareOrPrintReport(
        widget.result,
        widget.params,
        _isBangla,
        diagramImageBytes: diagramBytes,
      );
    }
  }

  void _showDetailModal({
    required String title,
    required Widget content,
    Color headerColor = const Color(0xFF10B981),
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'WiringDetail',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Icon(Icons.hub_outlined, color: headerColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(child: content),
        );
      },
    );
  }

  void _openPvWiringGuide() {
    final result = widget.result;
    final int pvs = result.panelsSeries;
    final int pvp = result.panelsParallel;
    String modeText;
    if (pvs == 1 && pvp == 1) {
      modeText = _isBangla ? 'একক প্যানেল সংযোগ' : 'Single Panel Setup';
    } else if (pvs > 1 && pvp == 1) {
      modeText = _isBangla
          ? 'সিরিজ সংযোগ ($pvsটি প্যানেল)'
          : 'Pure Series ($pvs Panels)';
    } else if (pvs == 1 && pvp > 1) {
      modeText = _isBangla
          ? 'প্যারালাল সংযোগ ($pvpটি সারি)'
          : 'Pure Parallel ($pvp Strings)';
    } else {
      modeText = _isBangla
          ? 'মিশ্র সংযোগ ($pvs সিরিজ × $pvp প্যারালাল)'
          : 'Series-Parallel ($pvs Series × $pvp Strings)';
    }

    final double canvasWidth = (pvs > 1 && pvp > 1) ? 750 : 600;
    final double canvasHeight = (pvs > 1 && pvp > 1) ? 460 : 380;

    _showDetailModal(
      title: _isBangla
          ? 'সোলার প্যানেল বাস্তব সংযোগ চিত্র'
          : 'Solar PV Wiring Blueprint',
      headerColor: const Color(0xFF0284C7),
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF131D31),
            child: Row(
              children: [
                const Icon(
                  Icons.solar_power_rounded,
                  color: Colors.cyanAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$modeText (${result.totalPanels} ${_isBangla ? "টি" : "Panels"})',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Container(
                    width: canvasWidth,
                    height: canvasHeight,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090E17),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: CustomPaint(
                      painter: CleanPanelVisualPainter(
                        pvs: pvs,
                        pvp: pvp,
                        isBangla: _isBangla,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildBottomGuideText(
            isSeries: pvs > 1,
            isParallel: pvp > 1,
            componentType: 'panel',
          ),
        ],
      ),
    );
  }

  void _openBatteryWiringGuide() {
    final result = widget.result;
    final int bs = result.batteriesSeries;
    final int bp = result.batteriesParallel;
    String modeText;
    if (bs == 1 && bp == 1) {
      modeText = _isBangla ? 'একক ১২V ব্যাটারি' : 'Single 12V Battery';
    } else if (bs > 1 && bp == 1) {
      modeText = _isBangla
          ? 'সিরিজ সংযোগ ($bsটি ব্যাটারি = ${widget.params.systemVoltage.toInt()}V)'
          : 'Series Setup ($bs x 12V = ${widget.params.systemVoltage.toInt()}V)';
    } else if (bs == 1 && bp > 1) {
      modeText = _isBangla
          ? 'প্যারালাল সংযোগ ($bpটি প্যারালাল)'
          : 'Parallel Setup ($bp Strings)';
    } else {
      modeText = _isBangla
          ? 'মিশ্র সংযোগ ($bs সিরিজ × $bp প্যারালাল)'
          : 'Series-Parallel ($bs Series × $bp Strings)';
    }

    final double canvasWidth = (bs > 1 && bp > 1) ? 750 : 600;
    final double canvasHeight = (bs > 1 && bp > 1) ? 460 : 380;

    _showDetailModal(
      title: _isBangla
          ? 'ব্যাটারি ব্যাংক বাস্তব সংযোগ চিত্র'
          : 'Battery Bank Wiring Blueprint',
      headerColor: const Color(0xFFEAB308),
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF131D31),
            child: Row(
              children: [
                const Icon(
                  Icons.battery_charging_full_rounded,
                  color: Colors.amberAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$modeText (${result.totalBatteries} ${_isBangla ? "টি" : "Units"})',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Container(
                    width: canvasWidth,
                    height: canvasHeight,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090E17),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: CustomPaint(
                      painter: CleanBatteryVisualPainter(
                        bs: bs,
                        bp: bp,
                        sysVolt: widget.params.systemVoltage.toInt(),
                        isBangla: _isBangla,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildBottomGuideText(
            isSeries: bs > 1,
            isParallel: bp > 1,
            componentType: 'battery',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomGuideText({
    required bool isSeries,
    required bool isParallel,
    required String componentType,
  }) {
    String text = '';
    if (!isSeries && !isParallel) {
      text = _isBangla
          ? 'একক সংযোগ: লাল তার পজিটিভে (+) এবং নীল তার নেগেটিভে (-) সরাসরি মূল লাইনে যুক্ত হবে।'
          : 'Single Unit: Wire (+) and (-) directly to system.';
    } else if (isSeries && !isParallel) {
      text = _isBangla
          ? (componentType == 'panel'
                ? 'সিরিজ সংযোগ: প্যানেল-১ এর (-) তার প্যানেল-২ এর (+) তারে যুক্ত করুন (হলুদ জাম্পার তার)। মুক্ত দুই প্রান্তদ্বয় (+ এবং -) সরাসরি কন্ট্রোলারে যাবে।'
                : 'সিরিজ সংযোগ: ১ম ব্যাটারির (+) টার্মিনাল ২য় ব্যাটারির (-) টার্মিনালে হলুদ জাম্পার দিয়ে জুড়ুন। মুক্ত দুই প্রান্তদ্বয় থেকে মূল সিস্টেমে লাইন যাবে।')
          : 'Series: Wire (+) of one unit to (-) of next. Free ends go to system.';
    } else if (!isSeries && isParallel) {
      text = _isBangla
          ? 'প্যারালাল সংযোগ: সবগুলোর (+) একসাথে ও সবগুলোর (-) একসাথে সমান্তরালে জোড়া দিন (MC4 Y-Branch কানেক্টর দিয়ে)।'
          : 'Parallel: Join all (+) together and all (-) together in parallel.';
    } else {
      text = _isBangla
          ? 'মিশ্র সংযোগ: প্রথমে প্রতি সারিতে সিরিজ সম্পন্ন করুন, তারপর সারিগুলোর আউটপুট সমান্তরালে জুড়ুন।'
          : 'Series-Parallel: Wire series strings first, then join strings in parallel.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1E293B),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  void _openControllerGuide() {
    _showDetailModal(
      title: _isBangla
          ? 'চার্জ কন্ট্রোলার সংযোগ নির্দেশিকা'
          : 'Charge Controller Wiring Ports',
      headerColor: const Color(0xFF16A34A),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDC2626)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isBangla
                          ? 'সতর্কতা: সংযোগ দেওয়ার সময় প্রথমে ব্যাটারি সংযুক্ত করুন, তারপর সোলার প্যানেল! খোলার সময় আগে সোলার খুলুন, তারপর ব্যাটারি।'
                          : 'Golden Rule: Always connect Battery FIRST, then Solar Panels! When disconnecting, remove Solar FIRST.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildPortRow(
              'Port 1 & 2',
              _isBangla
                  ? 'সোলার প্যানেল ইনপুট (+ ও -)'
                  : 'Solar Array Input (+ & -)',
              Colors.cyanAccent,
            ),
            _buildPortRow(
              'Port 3 & 4',
              _isBangla
                  ? 'ব্যাটারি ব্যাংক টার্মিনাল (+ ও -)'
                  : 'Battery Bank (+ & -)',
              Colors.amberAccent,
            ),
            _buildPortRow(
              'Port 5 & 6',
              _isBangla
                  ? '১২V ডিসি লোড টার্মিনাল (+ ও -)'
                  : 'DC Load Terminal (+ & -)',
              Colors.greenAccent,
            ),
          ],
        ),
      ),
    );
  }

  void _openInverterGuide() {
    _showDetailModal(
      title: _isBangla ? 'ইনভার্টার সংযোগ নির্দেশিকা' : 'Inverter Wiring Guide',
      headerColor: const Color(0xFF8B5CF6),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.params.systemType == SolarSystemType.gridTied
              ? (_isBangla
                    ? '• অন-গ্রিড স্ট্রিং ইনভার্টার সোলার ডিসি ভোল্টেজকে সিনক্রোনাইজ করে ২২০V এসিতে রূপান্তর করে।\n• এর আউটপুট সরাসরি নেট-মিটার হয়ে মূল ডিস্ট্রিবিউশন বোর্ডে যুক্ত হয়।\n• গ্রিড অফ থাকলে নিরাপত্তা স্বার্থে এটি স্বয়ংক্রিয়ভাবে বন্ধ (Anti-Islanding) হয়ে যায়।'
                    : '• Grid-Tied Inverter synchronizes solar DC power to 220V grid AC.\n• Output directly connects to Net-Meter.\n• Features Anti-Islanding safety protection.')
              : (_isBangla
                    ? '• ইনভার্টারের ডিসি ইনপুট সরাসরি ব্যাটারি ব্যাংকে যুক্ত হবে (কন্ট্রোলারের ডিসি লোড পোর্টে কখনো ইনভার্টার লাগাবেন না)।\n• ব্যাটারির পজিティブ তারের সাথে ≥ ${widget.result.batteryFuseAmp.toInt()}A ডিসি ফিউজ লাগাতে হবে।\n• আউটপুট সকেট থেকে ঘরের ২২০V এসি লোড বক্সে সংযোগ যাবে।'
                    : '• Inverter DC input connects directly to the Battery Bank (NEVER into charge controller DC load port!).\n• Install a ≥ ${widget.result.batteryFuseAmp.toInt()}A DC Fuse on the battery positive line.\n• AC 220V output routes to your home AC loads.'),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  void _openHybridInverterGuide() {
    _showDetailModal(
      title: _isBangla
          ? 'হাইব্রিড ইনভার্টার নির্দেশিকা'
          : 'Hybrid Inverter Guide',
      headerColor: const Color(0xFF8B5CF6),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _isBangla
              ? '• এটি একটি অল-ইন-ওয়ান ইনভার্টার যার ভেতরে MPPT চার্জ কন্ট্রোলার বিল্ট-ইন থাকে।\n• সোলার প্যানেল এবং ব্যাটারি ব্যাংক উভয়ই সরাসরি ইনভার্টারের নির্ধারিত টার্মিনালে সংযুক্ত হয়।\n• একই সাথে এটি জাতীয় গ্রিডের সাথে যুক্ত হয়ে স্বয়ংক্রিয়ভাবে ব্যাকআপ পরিচালনা করে।'
              : '• All-in-One smart unit with integrated MPPT charge controller.\n• Solar array and battery bank connect directly to the inverter.\n• Manages solar, battery and grid inputs simultaneously.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  void _openNetMeterGuide() {
    _showDetailModal(
      title: _isBangla
          ? 'দ্বিমুখী নেট মিটার নির্দেশিকা'
          : 'Bi-directional Net Meter',
      headerColor: const Color(0xFF0D9488),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _isBangla
              ? '• নেট মিটারিং একটি বিশেষ দ্বিমুখী মিটার যা বিদ্যুৎ আমদানি (Import) এবং রপ্তানি (Export) উভয় হিসাব রাখে।\n• দিনের বেলা উৎপাদিত বাড়তি সোলার বিদ্যুৎ জাতীয় গ্রিডে রপ্তানি হয় এবং মাসের শেষে মোট বিল সমন্বয় করা হয়।'
              : '• Bi-directional meter records both electricity imported from and exported to the grid.\n• Excess solar electricity is sold back to the utility grid.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  void _openNationalGridGuide() {
    _showDetailModal(
      title: _isBangla ? 'জাতীয় পাওয়ার গ্রিড সংযোগ' : 'National Utility Grid',
      headerColor: const Color(0xFF10B981),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _isBangla
              ? '• জাতীয় গ্রিড ২৪ ঘণ্টা প্রধান শক্তি ভাণ্ডার হিসেবে কাজ করে।\n• অন-গ্রিড এবং হাইব্রিড সিস্টেমে সোলারের ঘাটতি সময়ে গ্রিড থেকে স্বয়ংক্রিয়ভাবে শক্তি সরবরাহ বজায় থাকে।'
              : '• 24/7 main utility grid source providing continuous power supply and absorbing excess solar power.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  void _openDcLoadGuide() {
    _showDetailModal(
      title: _isBangla ? 'ডিসি লোড সংযোগ নির্দেশিকা' : 'DC Loads Wiring Guide',
      headerColor: const Color(0xFF06B6D4),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _isBangla
              ? '• ১২V ডিসি লোডসমূহ (যেমন: ডিসি ফ্যান, এলইডি লাইট) সরাসরি চার্জ কন্ট্রোলারের ডিসি লোড পোর্ট থেকে চলবে।\n• এখানে ব্যাটারির ওভার-ডিসচার্জ প্রোটেকশন কন্ট্রোলার নিজেই নিয়ন্ত্রণ করে।'
              : '• DC loads (12V Fan, LED) run from Controller DC load port.\n• Battery low-voltage protection is managed directly by the controller.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  void _openAcLoadGuide() {
    _showDetailModal(
      title: _isBangla ? 'এসি লোড সংযোগ নির্দেশিকা' : 'AC Loads Wiring Guide',
      headerColor: const Color(0xFFD97706),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _isBangla
              ? '• এসি লোডসমূহ (২২০V ফ্রিজ, সাধারণ টিভি, ফ্যান ইত্যাদি) ইনভার্টারের আউটপুট থেকে এসি ব্রেকার (AC MCB) হয়ে চলবে।\n• বিশুদ্ধ সাইন ওয়েভ লাইন সাধারণ বাসাবাড়ির সব যন্ত্রপাতির জন্য নিরাপদ।'
              : '• AC loads (220V Fridge, TV, AC Fan) run from Inverter AC output breaker.\n• Pure Sine Wave line ensures safe operation of sensitive home appliances.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPortRow(String port, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              port,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final params = widget.params;
    final isGridTied = params.systemType == SolarSystemType.gridTied;
    final isHybrid = params.systemType == SolarSystemType.hybrid;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          _isBangla ? 'সিস্টেম ওয়্যারিং ডায়াগ্রাম' : 'System Wiring Diagram',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isLandscape ? 'পোর্ট্রেট মোড' : 'ল্যান্ডস্কেপ মোড',
            icon: Icon(
              _isLandscape
                  ? Icons.screen_lock_portrait_rounded
                  : Icons.screen_lock_landscape_rounded,
              color: Colors.amberAccent,
            ),
            onPressed: _toggleOrientation,
          ),

          IconButton(
            tooltip: _isBangla ? 'রিসেট ভিউ' : 'Reset View',
            icon: const Icon(
              Icons.center_focus_strong_rounded,
              color: Colors.white70,
            ),
            onPressed: _resetZoom,
          ),
          // 📄 ডায়াগ্রামের ছবিসহ পূর্ণাঙ্গ রিপোর্ট এক্সপোর্ট বাটন
          IconButton(
            tooltip: _isBangla
                ? 'ডায়াগ্রামসহ রিপোর্ট শেয়ার'
                : 'Share Full Report with Diagram',
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _isExporting ? null : _handlePdfExport,
          ),
          IconButton(
            onPressed: () => setState(() => _isBangla = !_isBangla),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isBangla ? 'ENG' : 'বাংলা',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: _isBangla ? 'হোম / ড্যাশবোর্ড' : 'Dashboard / Home',
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            onPressed: () {
              // 💡 সরাসরি নেভিগেশন স্ট্যাকের প্রথম পেজে (Dashboard) ফিরে যাওয়ার কমান্ড
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final offGridPvRect = Rect.fromLTWH(
                vWidth * 0.025,
                vHeight * 0.10,
                vWidth * 0.19,
                vHeight * 0.32,
              );
              final offGridControllerRect = Rect.fromLTWH(
                vWidth * 0.31,
                vHeight * 0.11,
                vWidth * 0.19,
                vHeight * 0.28,
              );
              final offGridBatteryRect = Rect.fromLTWH(
                vWidth * 0.31,
                vHeight * 0.63,
                vWidth * 0.19,
                vHeight * 0.28,
              );
              final offGridInverterRect = Rect.fromLTWH(
                vWidth * 0.57,
                vHeight * 0.63,
                vWidth * 0.18,
                vHeight * 0.28,
              );
              final offGridDcLoadRect = Rect.fromLTWH(
                vWidth * 0.60,
                vHeight * 0.11,
                vWidth * 0.16,
                vHeight * 0.25,
              );
              final offGridAcLoadRect = Rect.fromLTWH(
                vWidth * 0.83,
                vHeight * 0.63,
                vWidth * 0.15,
                vHeight * 0.28,
              );

              final hybridPvRect = Rect.fromLTWH(
                vWidth * 0.025,
                vHeight * 0.11,
                vWidth * 0.19,
                vHeight * 0.32,
              );
              final hybridBatteryRect = Rect.fromLTWH(
                vWidth * 0.025,
                vHeight * 0.58,
                vWidth * 0.19,
                vHeight * 0.28,
              );
              final hybridInvRect = Rect.fromLTWH(
                vWidth * 0.33,
                vHeight * 0.24,
                vWidth * 0.23,
                vHeight * 0.50,
              );
              final hybridAcLoadRect = Rect.fromLTWH(
                vWidth * 0.68,
                vHeight * 0.13,
                vWidth * 0.18,
                vHeight * 0.26,
              );
              final hybridGridRect = Rect.fromLTWH(
                vWidth * 0.68,
                vHeight * 0.55,
                vWidth * 0.18,
                vHeight * 0.26,
              );

              final gridTiedPvRect = Rect.fromLTWH(
                vWidth * 0.025,
                vHeight * 0.28,
                vWidth * 0.19,
                vHeight * 0.35,
              );
              final gridTiedInvRect = Rect.fromLTWH(
                vWidth * 0.29,
                vHeight * 0.28,
                vWidth * 0.19,
                vHeight * 0.35,
              );
              final gridTiedMeterRect = Rect.fromLTWH(
                vWidth * 0.55,
                vHeight * 0.30,
                vWidth * 0.17,
                vHeight * 0.30,
              );
              final gridTiedAcLoadRect = Rect.fromLTWH(
                vWidth * 0.79,
                vHeight * 0.12,
                vWidth * 0.18,
                vHeight * 0.26,
              );
              final gridTiedGridRect = Rect.fromLTWH(
                vWidth * 0.79,
                vHeight * 0.53,
                vWidth * 0.18,
                vHeight * 0.26,
              );

              return InteractiveViewer(
                transformationController: _mainCanvasController,
                minScale: 0.5,
                maxScale: 3.5,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 60),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        // 📸 RepaintBoundary দিয়ে ফ্রেম র‍্যাপ করা হয়েছে
                        child: RepaintBoundary(
                          key: _diagramCanvasKey,
                          child: Container(
                            width: vWidth,
                            height: vHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFF131D31),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withAlpha(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(120),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                CustomPaint(
                                  size: const Size(vWidth, vHeight),
                                  painter: SolarRealisticWiringPainter(
                                    result: result,
                                    params: params,
                                    isBangla: _isBangla,
                                  ),
                                ),

                                // ১. অফ-গ্রিড টাচ হটস্পটসমূহ
                                if (!isGridTied && !isHybrid) ...[
                                  _buildTouchOverlay(
                                    offGridPvRect,
                                    _openPvWiringGuide,
                                    _isBangla
                                        ? 'টাচ: প্যানেল সংযোগ'
                                        : 'Tap: PV Wiring',
                                  ),
                                  _buildTouchOverlay(
                                    offGridControllerRect,
                                    _openControllerGuide,
                                    _isBangla
                                        ? 'টাচ: পোর্ট গাইড'
                                        : 'Tap: Ports',
                                  ),
                                  _buildTouchOverlay(
                                    offGridBatteryRect,
                                    _openBatteryWiringGuide,
                                    _isBangla
                                        ? 'টাচ: ব্যাটারি সংযোগ'
                                        : 'Tap: Battery Wiring',
                                  ),
                                  if (result.hasAcLoad) ...[
                                    _buildTouchOverlay(
                                      offGridInverterRect,
                                      _openInverterGuide,
                                      _isBangla
                                          ? 'টাচ: ইনভার্টার গাইড'
                                          : 'Tap: Inverter Guide',
                                    ),
                                    _buildTouchOverlay(
                                      offGridAcLoadRect,
                                      _openAcLoadGuide,
                                      _isBangla
                                          ? 'টাচ: এসি লোড গাইড'
                                          : 'Tap: AC Loads',
                                    ),
                                  ],
                                  if (result.hasDcLoad)
                                    _buildTouchOverlay(
                                      offGridDcLoadRect,
                                      _openDcLoadGuide,
                                      _isBangla
                                          ? 'টাচ: ডিসি লোড গাইড'
                                          : 'Tap: DC Loads',
                                    ),
                                ],

                                // ২. হাইব্রিড টাচ হটস্পটসমূহ
                                if (isHybrid) ...[
                                  _buildTouchOverlay(
                                    hybridPvRect,
                                    _openPvWiringGuide,
                                    _isBangla
                                        ? 'টাচ: প্যানেল সংযোগ'
                                        : 'Tap: PV Wiring',
                                  ),
                                  _buildTouchOverlay(
                                    hybridBatteryRect,
                                    _openBatteryWiringGuide,
                                    _isBangla
                                        ? 'টাচ: ব্যাটারি সংযোগ'
                                        : 'Tap: Battery Wiring',
                                  ),
                                  _buildTouchOverlay(
                                    hybridInvRect,
                                    _openHybridInverterGuide,
                                    _isBangla
                                        ? 'টাচ: হাইব্রিড গাইড'
                                        : 'Tap: Hybrid Inverter',
                                  ),
                                  _buildTouchOverlay(
                                    hybridAcLoadRect,
                                    _openAcLoadGuide,
                                    _isBangla ? 'টাচ: এসি লোড' : 'Tap: AC Load',
                                  ),
                                  _buildTouchOverlay(
                                    hybridGridRect,
                                    _openNationalGridGuide,
                                    _isBangla
                                        ? 'টাচ: গ্রিড তথ্য'
                                        : 'Tap: Utility Grid',
                                  ),
                                ],

                                // ৩. অন-গ্রিড টাচ হটস্পটসমূহ
                                if (isGridTied) ...[
                                  _buildTouchOverlay(
                                    gridTiedPvRect,
                                    _openPvWiringGuide,
                                    _isBangla
                                        ? 'টাচ: প্যানেল সংযোগ'
                                        : 'Tap: PV Wiring',
                                  ),
                                  _buildTouchOverlay(
                                    gridTiedInvRect,
                                    _openInverterGuide,
                                    _isBangla
                                        ? 'টাচ: অন-গ্রিড ইনভার্টার'
                                        : 'Tap: Inverter Guide',
                                  ),
                                  _buildTouchOverlay(
                                    gridTiedMeterRect,
                                    _openNetMeterGuide,
                                    _isBangla
                                        ? 'টাচ: নেট মিটার'
                                        : 'Tap: Net Meter',
                                  ),
                                  _buildTouchOverlay(
                                    gridTiedAcLoadRect,
                                    _openAcLoadGuide,
                                    _isBangla ? 'টাচ: এসি লোড' : 'Tap: AC Load',
                                  ),
                                  _buildTouchOverlay(
                                    gridTiedGridRect,
                                    _openNationalGridGuide,
                                    _isBangla
                                        ? 'টাচ: পাওয়ার গ্রিড'
                                        : 'Tap: Utility Grid',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(left: 16, right: 16, bottom: 12, child: _buildLegendBar()),
        ],
      ),
    );
  }

  Widget _buildTouchOverlay(Rect rect, VoidCallback onTap, String hint) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    color: Colors.cyanAccent,
                    size: 11,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hint,
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withAlpha(240),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 12,
        runSpacing: 4,
        children: [
          _legendItem(
            const Color(0xFFEF4444),
            _isBangla ? 'ডিসি পজিটিভ (+)' : 'DC Positive (+)',
          ),
          _legendItem(
            const Color(0xFF38BDF8),
            _isBangla ? 'ডিসি নেগেটিভ (-)' : 'DC Negative (-)',
          ),
          if (widget.result.hasAcLoad ||
              widget.params.systemType == SolarSystemType.gridTied) ...[
            _legendItem(
              const Color(0xFFF59E0B),
              _isBangla ? 'এসি ফেজ (220V)' : 'AC Live (L)',
            ),
            _legendItem(
              const Color(0xFF38BDF8),
              _isBangla ? 'এসি নিউট্রাল (N)' : 'AC Neutral (N)',
            ),
          ],
          if (widget.params.systemType != SolarSystemType.offGrid)
            _legendItem(
              const Color(0xFF10B981),
              _isBangla ? 'গ্রিড লাইন' : 'Grid Line',
            ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
