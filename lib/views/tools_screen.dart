import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ToolsScreen extends StatefulWidget {
  final bool isBangla;
  final int initialIndex;

  const ToolsScreen({super.key, required this.isBangla, this.initialIndex = 0});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  double? _heading = 0.0;
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 9.8;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );

    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _heading = event.heading ?? 0.0;
        });
      }
    });

    accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _accelX = event.x;
          _accelY = event.y;
          _accelZ = event.z;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isBangla = widget.isBangla;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          isBangla ? 'সোলার ইন্সট্রুমেন্ট' : 'Solar Instruments',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3.5,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.explore_rounded),
              text: isBangla ? 'কম্পাস' : 'Compass',
            ),
            Tab(
              icon: const Icon(Icons.blur_circular_rounded),
              text: isBangla ? 'লেভেলার' : 'Leveler',
            ),
            Tab(
              icon: const Icon(Icons.speed_rounded),
              text: isBangla ? 'চাঁদা / কোণ' : 'Inclinometer',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCompassView(isBangla),
          _buildLevelerView(isBangla),
          _buildProtractorView(isBangla),
        ],
      ),
    );
  }

  // ================= ১. কম্পাস ভিউ =================
  Widget _buildCompassView(bool isBangla) {
    final double heading = (_heading ?? 0.0);
    final double positiveHeading =
        (heading < 0 ? heading + 360 : heading) % 360;
    final bool isSouth = positiveHeading >= 172 && positiveHeading <= 188;

    final double rotX = (_accelY / 10).clamp(-0.35, 0.35);
    final double rotY = (-_accelX / 10).clamp(-0.35, 0.35);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            _buildStatusBadge(
              isSuccess: isSouth,
              icon: isSouth ? Icons.check_circle : Icons.navigation_rounded,
              text: isSouth
                  ? (isBangla
                        ? 'নিখুঁত দক্ষিণ দিক! (South)'
                        : 'Aligned with South')
                  : (isBangla
                        ? 'দক্ষিণ দিকে (১৮০°) ঘোরান'
                        : 'Rotate to 180° South'),
            ),
            const SizedBox(height: 36),

            // ডিভাইসটির থ্রি-ডি মেটালিক ফ্রেম ও পার্সপেক্টিভ
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateX(rotX)
                ..rotateY(rotY),
              alignment: FractionalOffset.center,
              child: Container(
                width: 290,
                height: 290,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF334155),
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                    ],
                    stops: [0.0, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.65),
                      blurRadius: 28,
                      offset: Offset(-rotY * 45, rotX * 45 + 14),
                    ),
                    BoxShadow(
                      color: isSouth
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : const Color(0xFF38BDF8).withOpacity(0.12),
                      blurRadius: 22,
                    ),
                  ],
                  border: Border.all(
                    color: isSouth ? const Color(0xFF10B981) : Colors.white24,
                    width: 4,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ঘূর্ণায়মান ইন্টারনাল ডায়াল
                    Transform.rotate(
                      angle: -(positiveHeading * (math.pi / 180)),
                      child: CustomPaint(
                        size: const Size(280, 280),
                        painter: CompassDialPainter(),
                      ),
                    ),
                    // সেন্টার কোর ডিস্ক
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0F172A),
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black87, blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${positiveHeading.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _getDirectionName(positiveHeading),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSouth
                                  ? const Color(0xFF10B981)
                                  : Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isBangla
                  ? 'সর্বোচ্চ সৌরশক্তির জন্য সোলার প্যানেলটি ১৮০° দক্ষিণমুখী করে স্থাপন করুন।'
                  : 'For maximum generation in Bangladesh, face the panel due South.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ২. লেভেলার ভিউ =================
  Widget _buildLevelerView(bool isBangla) {
    final double maxOffset = 95.0;
    final double rawX = (_accelX * 12).clamp(-maxOffset, maxOffset);
    final double rawY = (-_accelY * 12).clamp(-maxOffset, maxOffset);
    final bool isLevel = rawX.abs() < 4.0 && rawY.abs() < 4.0;

    final double rotX = (_accelY / 12).clamp(-0.35, 0.35);
    final double rotY = (-_accelX / 12).clamp(-0.35, 0.35);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            _buildStatusBadge(
              isSuccess: isLevel,
              icon: isLevel ? Icons.verified_rounded : Icons.crop_free_rounded,
              text: isLevel
                  ? (isBangla
                        ? 'পৃষ্ঠ সম্পূর্ণ সমতল (0° Level)'
                        : 'Surface Perfectly Level!')
                  : (isBangla ? 'বাবলটি মাঝে স্থির করুন' : 'Center the bubble'),
            ),
            const SizedBox(height: 36),

            // ডিভাইসটির থ্রি-ডি স্ফেরিক্যাল গ্লাস টিউব
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateX(rotX)
                ..rotateY(rotY),
              alignment: FractionalOffset.center,
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-rotY, -rotX),
                    colors: const [
                      Color(0xFF475569),
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                  border: Border.all(color: Colors.white30, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 30,
                      offset: Offset(-rotY * 45, rotX * 45 + 16),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLevel
                              ? const Color(0xFF10B981)
                              : Colors.white24,
                          width: 2,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    const VerticalDivider(color: Colors.white12, width: 1),

                    // ত্রিমাত্রিক শ্যাডোযুক্ত ফ্লুইড বাবল
                    Transform.translate(
                      offset: Offset(rawX, rawY),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.35, -0.35),
                            colors: isLevel
                                ? [
                                    const Color(0xFF6EE7B7),
                                    const Color(0xFF059669),
                                  ]
                                : [
                                    const Color(0xFF38BDF8),
                                    const Color(0xFF0284C7),
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isLevel
                                          ? const Color(0xFF10B981)
                                          : Colors.cyan)
                                      .withOpacity(0.55),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'Pitch: ${(-_accelY).toStringAsFixed(1)}°   |   Roll: ${_accelX.toStringAsFixed(1)}°',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ৩. চাঁদা / ইনক্লিনোমিটার ভিউ =================
  Widget _buildProtractorView(bool isBangla) {
    double angleRad = math.atan2(
      _accelY.abs(),
      math.sqrt(_accelX * _accelX + _accelZ * _accelZ),
    );
    double angleDeg = (angleRad * (180.0 / math.pi)).clamp(0.0, 90.0);
    final bool isOptimal = angleDeg >= 23.0 && angleDeg <= 27.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            _buildStatusBadge(
              isSuccess: isOptimal,
              icon: isOptimal ? Icons.wb_sunny_rounded : Icons.tune_rounded,
              text: isOptimal
                  ? (isBangla
                        ? 'সর্বোত্তম সৌর কোণ (~২৫°)'
                        : 'Optimal Solar Angle (~25°)')
                  : (isBangla
                        ? 'লক্ষ্য কোণ: প্রায় ২৫°'
                        : 'Target Angle: ~25°'),
            ),
            const SizedBox(height: 36),

            // ডিভাইসটির থ্রি-ডি মেকানিক্যাল গেজ ফ্রেম
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(0.25),
              alignment: FractionalOffset.bottomCenter,
              child: Container(
                width: 290,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(150),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF334155),
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                    ],
                  ),
                  border: Border.all(color: Colors.white24, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.65),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CustomPaint(
                      size: const Size(280, 150),
                      painter: ProtractorArcPainter(currentAngle: angleDeg),
                    ),
                    Positioned(
                      bottom: 16,
                      child: Column(
                        children: [
                          Text(
                            '${angleDeg.toStringAsFixed(1)}°',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: isOptimal
                                  ? const Color(0xFF34D399)
                                  : Colors.white,
                              shadows: [
                                Shadow(
                                  color:
                                      (isOptimal
                                              ? const Color(0xFF10B981)
                                              : Colors.white)
                                          .withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            isBangla ? 'বর্তমান ঢাল' : 'CURRENT TILT',
                            style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isBangla
                          ? 'প্যানেল বা টিনের চালার ওপর ফোনের এক পাশ রেখে কোণ পরিমাপ করুন।'
                          : 'Rest the long edge of the phone against the surface to measure tilt.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isSuccess,
    required IconData icon,
    required String text,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFF065F46).withOpacity(0.8)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSuccess ? const Color(0xFF10B981) : Colors.white12,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSuccess ? const Color(0xFF34D399) : Colors.amber,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSuccess ? const Color(0xFF34D399) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  String _getDirectionName(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'উত্তর (N)';
    if (deg >= 22.5 && deg < 67.5) return 'উত্তর-পূর্ব (NE)';
    if (deg >= 67.5 && deg < 112.5) return 'পূর্ব (E)';
    if (deg >= 112.5 && deg < 157.5) return 'দক্ষিণ-পূর্ব (SE)';
    if (deg >= 157.5 && deg < 202.5) return 'দক্ষিণ (S)';
    if (deg >= 202.5 && deg < 247.5) return 'দক্ষিণ-পশ্চিম (SW)';
    if (deg >= 247.5 && deg < 292.5) return 'পশ্চিম (W)';
    return 'উত্তর-পশ্চিম (NW)';
  }
}

// ----------------- কাস্টম পেইন্টারসমূহ -----------------

class CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 5) {
      final isMajor = i % 30 == 0;
      final isCardinal = i % 90 == 0;
      final tickLength = isCardinal ? 16.0 : (isMajor ? 10.0 : 5.0);

      tickPaint.strokeWidth = isCardinal ? 3.0 : (isMajor ? 1.5 : 1.0);
      tickPaint.color = i == 180
          ? const Color(0xFF10B981)
          : (i == 0 ? Colors.redAccent : Colors.white54);

      final rad = (i - 90) * (math.pi / 180);
      final p1 = Offset(
        center.dx + (radius - 14) * math.cos(rad),
        center.dy + (radius - 14) * math.sin(rad),
      );
      final p2 = Offset(
        center.dx + (radius - 14 - tickLength) * math.cos(rad),
        center.dy + (radius - 14 - tickLength) * math.sin(rad),
      );
      canvas.drawLine(p1, p2, tickPaint);

      if (isCardinal) {
        final tp = TextPainter(
          text: TextSpan(
            text: i == 0 ? 'N' : (i == 90 ? 'E' : (i == 180 ? 'S' : 'W')),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: i == 180
                  ? const Color(0xFF10B981)
                  : (i == 0 ? Colors.redAccent : Colors.white),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final textRadius = radius - 40;
        final tx = center.dx + textRadius * math.cos(rad) - tp.width / 2;
        final ty = center.dy + textRadius * math.sin(rad) - tp.height / 2;
        tp.paint(canvas, Offset(tx, ty));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProtractorArcPainter extends CustomPainter {
  final double currentAngle;

  ProtractorArcPainter({required this.currentAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    final bgArcPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgArcPaint,
    );

    // ২৫° অপটিমাল জোন
    final targetArcPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi + (23.0 * (math.pi / 180)),
      (4.0 * (math.pi / 180)),
      false,
      targetArcPaint,
    );

    final sweepAngle = (currentAngle.clamp(0.0, 90.0) * (math.pi / 180));
    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF10B981)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProtractorArcPainter oldDelegate) =>
      oldDelegate.currentAngle != currentAngle;
}
