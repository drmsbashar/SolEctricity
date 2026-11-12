import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../models/solar_calculation_result.dart';
import '../models/system_sizing_params.dart';
import '../services/pdf_report_service.dart';
import 'widgets/wiring_painters.dart';
import '../widgets/app_bar_title.dart';

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
  final GlobalKey _diagramCanvasKey = GlobalKey();
  bool _isLandscape = false;
  bool _isExporting = false;

  static const double vWidth = 1140.0;
  static const double vHeight = 620.0;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
  }

  Future<void> _toggleOrientation() async {
    final nextIsLandscape = !_isLandscape;
    if (nextIsLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    if (mounted) {
      setState(() {
        _isLandscape = nextIsLandscape;
      });
    }
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

  void _resetZoom() {
    _mainCanvasController.value = Matrix4.identity();
  }

  Future<Uint8List?> _captureDiagramPng() async {
    try {
      final boundary =
          _diagramCanvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _handlePdfExport() async {
    setState(() => _isExporting = true);

    try {
      // ১. প্রিন্ট ও PDF-এর জন্য সুপার শার্প হাই-রেজোলিউশন ক্যানভাস তৈরি (3.0x Scale)
      const double exportScale = 3.0;
      final recorder = ui.PictureRecorder();
      final printCanvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, vWidth, vHeight),
      );

      final printPainter = SolarRealisticWiringPainter(
        result: widget.result,
        params: widget.params,
        isBangla: _isBangla,
        isDark: false,
        isForPrint: true, // সাদা ব্যাকগ্রাউন্ড, প্রতিটি ব্লকের ভেতর পূর্ণাঙ্গ বিবরণ ও স্থায়ী লিজেন্ডসহ
      );

      printPainter.paint(printCanvas, const Size(vWidth, vHeight));

      final picture = recorder.endRecording();
      // ৩ গুণ রেজোলিউশন যাতে ব্লকের ভেতরের প্রতিটি ভোল্টেজ, কারেন্ট, ব্রেকার টেক্সট ক্রিস্টাল ক্লিয়ার আসে
      final img = await picture.toImage(
        (vWidth * exportScale).toInt(),
        (vHeight * exportScale).toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final diagramBytes = byteData?.buffer.asUint8List();

      if (mounted) {
        setState(() => _isExporting = false);
        await PdfReportService.shareOrPrintReport(
          widget.result,
          widget.params,
          _isBangla,
          diagramImageBytes: diagramBytes,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showDetailModal({
    required String title,
    required Widget Function(
      bool isDark,
      TransformationController modalController,
    )
    contentBuilder,
    Color headerColor = const Color(0xFF10B981),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TransformationController modalController = TransformationController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'WiringDetail',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0B1120)
              : const Color(0xFFF1F5F9),
          appBar: AppBar(
            backgroundColor: isDark
                ? const Color(0xFF1E293B)
                : AppColors.primaryGreen,
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Icon(Icons.hub_rounded, color: headerColor, size: 20),
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
            actions: [
              IconButton(
                tooltip: _isBangla ? 'রিসেট ভিউ' : 'Reset View',
                icon: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  modalController.value = Matrix4.identity();
                },
              ),
            ],
          ),
          body: SafeArea(child: contentBuilder(isDark, modalController)),
        );
      },
    );
  }

  void _openPvWiringGuide() {
    final result = widget.result;
    final int pvs = result.panelsSeries;
    final int pvp = result.panelsParallel;

    final String modeText = _isBangla
        ? 'মোট ${result.totalPanels}টি প্যানেল ($pvsটি সিরিজে × $pvpটি প্যারালালে)'
        : 'Total ${result.totalPanels} Panels ($pvs in Series × $pvp in Parallel)';

    final double scale = pvs <= 3 ? 1.0 : (pvs <= 6 ? 0.82 : 0.68);
    final double gridWidth = ((pvs * 95.0) + ((pvs - 1) * 35.0)) * scale;
    final double canvasWidth = math.max(650.0, gridWidth + 260.0);
    final double canvasHeight = math.max(
      380.0,
      110.0 + (pvp * (180.0 * scale)),
    );

    _showDetailModal(
      title: _isBangla
          ? 'সোলার প্যানেল বাস্তব সংযোগ চিত্র'
          : 'Solar PV Wiring Blueprint',
      headerColor: const Color(0xFF0284C7),
      contentBuilder: (isDark, modalController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D31) : const Color(0xFFE2E8F0),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.solar_power_rounded,
                  color: isDark ? Colors.cyanAccent : const Color(0xFF0284C7),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    modeText,
                    style: TextStyle(
                      color: isDark
                          ? Colors.cyanAccent
                          : const Color(0xFF0369A1),
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 🌟 স্ক্রিন সাইজ অনুযায়ী স্বয়ংক্রিয় ফিট ও ইন্টারেক্টিভ জুম
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  transformationController: modalController,
                  minScale: 0.5,
                  maxScale: 3.5,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FittedBox(
                          fit: BoxFit.contain, // ডিফল্ট অবস্থায় ১০০% স্ক্রিনের ভেতরে ফিট থাকবে
                          child: Container(
                            width: canvasWidth,
                            height: canvasHeight,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF090E17)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.5 : 0.08,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              size: Size(canvasWidth, canvasHeight),
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
                );
              },
            ),
          ),
          _buildBottomGuideText(
            isSeries: pvs > 1,
            isParallel: pvp > 1,
            componentType: 'panel',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  void _openBatteryWiringGuide() {
    final result = widget.result;
    final int bs = result.batteriesSeries;
    final int bp = result.batteriesParallel;

    final String modeText = _isBangla
        ? 'মোট ${result.totalBatteries}টি ব্যাটারি ($bsটি সিরিজে × $bpটি প্যারালালে = ${widget.params.systemVoltage.toInt()}V)'
        : 'Total ${result.totalBatteries} Batteries ($bs in Series × $bp in Parallel = ${widget.params.systemVoltage.toInt()}V)';

    final double scale = bs <= 2 ? 1.0 : (bs <= 4 ? 0.85 : 0.70);
    final double gridWidth = ((bs * 105.0) + ((bs - 1) * 35.0)) * scale;
    final double canvasWidth = math.max(650.0, gridWidth + 260.0);
    final double canvasHeight = math.max(380.0, 110.0 + (bp * (140.0 * scale)));

    _showDetailModal(
      title: _isBangla
          ? 'ব্যাটারি ব্যাংক বাস্তব সংযোগ চিত্র'
          : 'Battery Bank Wiring Blueprint',
      headerColor: const Color(0xFFEAB308),
      contentBuilder: (isDark, modalController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D31) : const Color(0xFFE2E8F0),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.battery_charging_full_rounded,
                  color: isDark ? Colors.amberAccent : const Color(0xFFB45309),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    modeText,
                    style: TextStyle(
                      color: isDark
                          ? Colors.amberAccent
                          : const Color(0xFFB45309),
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 🌟 স্ক্রিন সাইজ অনুযায়ী স্বয়ংক্রিয় ফিট ও ইন্টারেক্টিভ জুম
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  transformationController: modalController,
                  minScale: 0.5,
                  maxScale: 3.5,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FittedBox(
                          fit: BoxFit.contain, // ডিফল্ট অবস্থায় ১০০% স্ক্রিনের ভেতরে ফিট থাকবে
                          child: Container(
                            width: canvasWidth,
                            height: canvasHeight,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF090E17)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.5 : 0.08,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              size: Size(canvasWidth, canvasHeight),
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
                );
              },
            ),
          ),
          _buildBottomGuideText(
            isSeries: bs > 1,
            isParallel: bp > 1,
            componentType: 'battery',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomGuideText({
    required bool isSeries,
    required bool isParallel,
    required String componentType,
    required bool isDark,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
      ),
    );
  }

  void _openControllerGuide() {
    _showDetailModal(
      title: _isBangla
          ? 'চার্জ কন্ট্রোলার সংযোগ নির্দেশিকা'
          : 'Charge Controller Wiring Ports',
      headerColor: const Color(0xFF16A34A),
      contentBuilder: (isDark, modalController) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFFDC2626).withValues(alpha: 0.15)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFFCA5A5),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isBangla
                          ? 'সতর্কতা: সংযোগ দেওয়ার সময় প্রথমে ব্যাটারি সংযুক্ত করুন, তারপর সোলার প্যানেল! খোলার সময় আগে সোলার খুলুন, তারপর ব্যাটারি।'
                          : 'Golden Rule: Always connect Battery FIRST, then Solar Panels! When disconnecting, remove Solar FIRST.',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF991B1B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildPortRow(
              'Port 1 & 2',
              _isBangla
                  ? 'সোলার প্যানেল ইনপুট (+ ও -)'
                  : 'Solar Array Input (+ & -)',
              const Color(0xFF0284C7),
              isDark,
            ),
            _buildPortRow(
              'Port 3 & 4',
              _isBangla
                  ? 'ব্যাটারি ব্যাংক টার্মিনাল (+ ও -)'
                  : 'Battery Bank (+ & -)',
              const Color(0xFFD97706),
              isDark,
            ),
            _buildPortRow(
              'Port 5 & 6',
              _isBangla
                  ? '১২V ডিসি লোড টার্মিনাল (+ ও -)'
                  : 'DC Load Terminal (+ & -)',
              const Color(0xFF16A34A),
              isDark,
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
      contentBuilder: (isDark, modalController) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            widget.params.systemType == SolarSystemType.gridTied
                ? (_isBangla
                      ? '• অন-গ্রিড স্ট্রিং ইনভার্টার সোলার ডিসি ভোল্টেজকে সিনক্রোনাইজ করে ২২০V এসিতে রূপান্তর করে।\n\n• এর আউটপুট সরাসরি নেট-মিটার হয়ে মূল ডিস্ট্রিবিউশন বোর্ডে যুক্ত হয়।\n\n• গ্রিড অফ থাকলে নিরাপত্তা স্বার্থে এটি স্বয়ংক্রিয়ভাবে বন্ধ (Anti-Islanding) হয়ে যায়।'
                      : '• Grid-Tied Inverter synchronizes solar DC power to 220V grid AC.\n\n• Output directly connects to Net-Meter.\n\n• Features Anti-Islanding safety protection.')
                : (_isBangla
                      ? '• ইনভার্টারের ডিসি ইনপুট সরাসরি ব্যাটারি ব্যাংকে যুক্ত হবে (কন্ট্রোলারের ডিসি লোড পোর্টে কখনো ইনভার্টার লাগাবেন না)।\n\n• ব্যাটারির পজিটিভ তারের সাথে ≥ ${widget.result.batteryFuseAmp.toInt()}A ডিসি ফিউজ লাগাতে হবে।\n\n• আউটপুট সকেট থেকে ঘরের ২২০V এসি লোড বক্সে সংযোগ যাবে।'
                      : '• Inverter DC input connects directly to the Battery Bank (NEVER into charge controller DC load port!).\n\n• Install a ≥ ${widget.result.batteryFuseAmp.toInt()}A DC Fuse on the battery positive line.\n\n• AC 220V output routes to your home AC loads.'),
            style: TextStyle(
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              fontSize: 13.5,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
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
      contentBuilder: (isDark, modalController) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            _isBangla
                ? '• এটি একটি অল-ইন-ওয়ান ইনভার্টার যার ভেতরে MPPT চার্জ কন্ট্রোলার বিল্ট-ইন থাকে।\n\n• সোলার প্যানেল এবং ব্যাটারি ব্যাংক উভয়ই সরাসরি ইনভার্টারের নির্ধারিত টার্মিনালে সংযুক্ত হয়।\n\n• একই সাথে এটি জাতীয় গ্রিডের সাথে যুক্ত হয়ে স্বয়ংক্রিয়ভাবে ব্যাকআপ পরিচালনা করে।'
                : '• All-in-One smart unit with integrated MPPT charge controller.\n\n• Solar array and battery bank connect directly to the inverter.\n\n• Manages solar, battery and grid inputs simultaneously.',
            style: TextStyle(
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              fontSize: 13.5,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
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
      contentBuilder: (isDark, modalController) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            _isBangla
                ? '• নেট মিটারিং একটি বিশেষ দ্বিমুখী মিটার যা বিদ্যুৎ আমদানি (Import) এবং রপ্তানি (Export) উভয় হিসাব রাখে।\n\n• দিনের বেলা উৎপাদিত বাড়তি সোলার বিদ্যুৎ জাতীয় গ্রিডে রপ্তানি হয় এবং মাসের শেষে মোট বিল সমন্বয় করা হয়।'
                : '• Bi-directional meter records both electricity imported from and exported to the grid.\n\n• Excess solar electricity is sold back to the utility grid.',
            style: TextStyle(
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              fontSize: 13.5,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _openNationalGridGuide() {
    _showDetailModal(
      title: _isBangla ? 'জাতীয় পাওয়ার গ্রিড সংযোগ' : 'National Utility Grid',
      headerColor: const Color(0xFF10B981),
      contentBuilder: (isDark, modalController) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            _isBangla
                ? '• জাতীয় গ্রিড ২৪ ঘণ্টা প্রধান শক্তি ভাণ্ডার হিসেবে কাজ করে।\n\n• অন-গ্রিড এবং হাইব্রিড সিস্টেমে সোলারের ঘাটতি সময়ে গ্রিড থেকে স্বয়ংক্রিয়ভাবে শক্তি সরবরাহ বজায় থাকে।'
                : '• 24/7 main utility grid source providing continuous power supply and absorbing excess solar power.',
            style: TextStyle(
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              fontSize: 13.5,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _openDcLoadGuide() {
    _showDetailModal(
      title: _isBangla ? 'ডিসি লোড সংযোগ নির্দেশিকা' : 'DC Loads Wiring Guide',
      headerColor: const Color(0xFF06B6D4),
      contentBuilder: (isDark, modalController) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            _isBangla
                ? '• ১২V ডিসি লোডসমূহ (যেমন: ডিসি ফ্যান, এলইডি লাইট) সরাসরি চার্জ কন্ট্রোলারের ডিসি লোড পোর্ট থেকে চলবে।\n\n• এখানে ব্যাটারির ওভার-ডিসচার্জ প্রোটেকশন কন্ট্রোলার নিজেই নিয়ন্ত্রণ করে।'
                : '• DC loads (12V Fan, LED) run from Controller DC load port.\n\n• Battery low-voltage protection is managed directly by the controller.',
            style: TextStyle(
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              fontSize: 13.5,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _openAcLoadGuide() {
    _showDetailModal(
      title: _isBangla ? 'এসি লোড সংযোগ নির্দেশিকা' : 'AC Loads Wiring Guide',
      headerColor: const Color(0xFFD97706),
      contentBuilder: (isDark, modalController) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            _isBangla
                ? '• এসি লোডসমূহ (২২০V ফ্রিজ, সাধারণ টিভি, ফ্যান ইত্যাদি) ইনভার্টারের আউটপুট থেকে এসি ব্রেকার (AC MCB) হয়ে চলবে।\n\n• বিশুদ্ধ সাইন ওয়েভ লাইন সাধারণ বাসাবাড়ির সব যন্ত্রপাতির জন্য নিরাপদ।'
                : '• AC loads (220V Fridge, TV, AC Fan) run from Inverter AC output breaker.\n\n• Pure Sine Wave line ensures safe operation of sensitive home appliances.',
            style: TextStyle(
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              fontSize: 13.5,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortRow(String port, String label, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.5)),
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
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final result = widget.result;
    final params = widget.params;
    final isGridTied = params.systemType == SolarSystemType.gridTied;
    final isHybrid = params.systemType == SolarSystemType.hybrid;

    return Scaffold(
      appBar: AppBar(
        titleSpacing:
            8.0, // বামের আইকন ও টাইটেলের মাঝের ফাঁকা জায়গা অপ্টিমাইজ করা হলো
        title: TwoLineAppBarTitle(
          title: _isBangla ? 'সংযোগ চিত্র' : 'Wiring Diagram',
          subtitle: _isBangla
              ? 'ব্লক ও ক্যাবল কানেকশন গাইড'
              : 'System Blueprint & Connections',
        ),
        actions: [
          // ১. ল্যান্ডস্কেপ / পোর্ট্রেট রোটেশন বাটন (বাইরে থাকবে)
          IconButton(
            tooltip: _isLandscape ? 'পোর্ট্রেট মোড' : 'ল্যান্ডস্কেপ মোড',
            icon: Icon(
              _isLandscape
                  ? Icons.screen_lock_portrait_rounded
                  : Icons.screen_lock_landscape_rounded,
              color: Colors.amberAccent,
              size: 22,
            ),
            onPressed: _toggleOrientation,
          ),

          // ২. পিডিএফ রিপোর্ট শেয়ার বাটন (বাইরে থাকবে)
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
                : const Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
            onPressed: _isExporting ? null : _handlePdfExport,
          ),

          // ৩. বাকি ৩টি অপশন (Reset Zoom, Language, Home) একটি ৩-ডট মেনুতে একীভূত করা হলো
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            tooltip: _isBangla ? 'আরও অপশন' : 'More Options',
            onSelected: (value) {
              if (value == 'reset') {
                _resetZoom();
              } else if (value == 'lang') {
                setState(() => _isBangla = !_isBangla);
              } else if (value == 'home') {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.center_focus_strong_rounded, size: 19),
                    const SizedBox(width: 10),
                    Text(_isBangla ? 'রিসেট ভিউ (Reset)' : 'Reset Zoom'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'lang',
                child: Row(
                  children: [
                    const Icon(Icons.translate_rounded, size: 19),
                    const SizedBox(width: 10),
                    Text(_isBangla ? 'Switch to English' : 'বাংলা ভাষা'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'home',
                child: Row(
                  children: [
                    const Icon(Icons.home_rounded, size: 19),
                    const SizedBox(width: 10),
                    Text(_isBangla ? 'হোম / ড্যাশবোর্ড' : 'Home Dashboard'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF030712),
                    const Color(0xFF0B1120),
                    const Color(0xFF020617),
                  ]
                : [
                    const Color(0xFFDCECE4),
                    const Color(0xFFEDF4F0),
                    const Color(0xFFE2EBE6),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
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
                          child: RepaintBoundary(
                            key: _diagramCanvasKey,
                            child: Container(
                              width: vWidth,
                              height: vHeight,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.65 : 0.12,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
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
                                      isDark: isDark,
                                      isForPrint: false,
                                    ),
                                  ),
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
                                      _isBangla
                                          ? 'টাচ: এসি লোড'
                                          : 'Tap: AC Load',
                                    ),
                                    _buildTouchOverlay(
                                      hybridGridRect,
                                      _openNationalGridGuide,
                                      _isBangla
                                          ? 'টাচ: গ্রিড তথ্য'
                                          : 'Tap: Utility Grid',
                                    ),
                                  ],
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
                                      _isBangla
                                          ? 'টাচ: এসি লোড'
                                          : 'Tap: AC Load',
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
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: _buildTactileLegendBar(isDark),
            ),
          ],
        ),
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
                color: Colors.black.withValues(alpha: 0.65),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTactileLegendBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 12,
        runSpacing: 4,
        children: [
          _legendItem(
            const Color(0xFFEF4444),
            _isBangla ? 'ডিসি পজিটিভ (+)' : 'DC Positive (+)',
            isDark,
          ),
          _legendItem(
            const Color(0xFF1D4ED8),
            _isBangla ? 'ডিসি নেগেটিভ (-)' : 'DC Negative (-)',
            isDark,
          ),
          if (widget.result.hasAcLoad ||
              widget.params.systemType == SolarSystemType.gridTied) ...[
            _legendItem(
              const Color(0xFFD97706),
              _isBangla ? 'এসি ফেজ (220V)' : 'AC Live (L)',
              isDark,
            ),
            _legendItem(
              const Color(0xFF06B6D4),
              _isBangla ? 'এসি নিউট্রাল (N)' : 'AC Neutral (N)',
              isDark,
            ),
          ],
          if (widget.params.systemType != SolarSystemType.offGrid)
            _legendItem(
              const Color(0xFF059669),
              _isBangla ? 'গ্রিড লাইন' : 'Grid Line',
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text, bool isDark) {
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
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.lightTextPrimary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
