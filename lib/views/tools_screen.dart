import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/solar_calculation_service.dart';
import '../widgets/app_bar_title.dart';

enum TiltSeasonMode { annual, summer, winter }

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

  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  double? _heading = 0.0;
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 9.8;
  bool _wasAligned = false;

  // 🌍 লোকেশন ভিত্তিক ডায়নামিক ভ্যারিয়েবল (ডিফল্ট ঢাকা: 23.8103°)
  double _latitude = 23.8103;
  bool _isGpsSynced = false;
  bool _isFetchingLocation = false;
  TiltSeasonMode _seasonMode = TiltSeasonMode.annual;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );

    _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _heading = event.heading ?? 0.0;
        });
      }
    });

    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _accelX = event.x;
          _accelY = event.y;
          _accelZ = event.z;
        });
      }
    });

    _detectUserLocation();
  }

  Future<void> _detectUserLocation() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isFetchingLocation = false);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 7),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _isGpsSynced = true;
          _isFetchingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  // 📐 লোকেশন ও ঋতু অনুযায়ী ডায়নামিক সৌর কোণ হিসাব
  double _getTargetTiltAngle() {
    final double absLat = _latitude.abs();
    final double baseOptimal = SolarCalculationService.calculateOptimalTilt(
      absLat,
    );

    switch (_seasonMode) {
      case TiltSeasonMode.annual:
        return baseOptimal.clamp(5.0, 65.0);
      case TiltSeasonMode.summer:
        return (absLat - 15.0).clamp(5.0, 60.0);
      case TiltSeasonMode.winter:
        return (absLat + 15.0).clamp(10.0, 75.0);
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _accelSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isBangla = widget.isBangla;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: TwoLineAppBarTitle(
          title: isBangla ? 'সোলার ইন্সট্রুমেন্ট' : 'Solar Instruments',
          subtitle: _isGpsSynced
              ? (isBangla
                    ? 'GPS অক্ষাংশ: ${_latitude.toStringAsFixed(2)}°'
                    : 'GPS Lat: ${_latitude.toStringAsFixed(2)}°')
              : (isBangla
                    ? 'ডিফল্ট অক্ষাংশ: ২৩.৮১° (ঢাকা)'
                    : 'Default Lat: 23.81° (Dhaka)'),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: isBangla ? 'GPS লোকেশন সিঙ্ক' : 'Sync GPS Location',
            onPressed: _isFetchingLocation ? null : _detectUserLocation,
            icon: _isFetchingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF10B981),
                    ),
                  )
                : Icon(
                    _isGpsSynced
                        ? Icons.gps_fixed_rounded
                        : Icons.gps_not_fixed_rounded,
                    color: _isGpsSynced
                        ? const Color(0xFF10B981)
                        : Colors.amberAccent,
                  ),
          ),
        ],
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

  // ================= ১. ডায়নামিক কম্পাস ভিউ =================
  Widget _buildCompassView(bool isBangla) {
    final double heading = (_heading ?? 0.0);
    final double positiveHeading =
        (heading < 0 ? heading + 360 : heading) % 360;

    // উত্তর গোলার্ধে (Lat >= 0) দক্ষিণমুখী (180°), দক্ষিণ গোলার্ধে (Lat < 0) উত্তরমুখী (0°)
    final bool isNorthernHemisphere = _latitude >= 0;
    final bool isAligned = isNorthernHemisphere
        ? (positiveHeading >= 172 && positiveHeading <= 188)
        : (positiveHeading >= 352 || positiveHeading <= 8);

    // হ্যাপটিক ফিডব্যাক
    if (isAligned && !_wasAligned) {
      HapticFeedback.lightImpact();
      _wasAligned = true;
    } else if (!isAligned && _wasAligned) {
      _wasAligned = false;
    }

    final double rotX = (_accelY / 10).clamp(-0.35, 0.35);
    final double rotY = (-_accelX / 10).clamp(-0.35, 0.35);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            _buildStatusBadge(
              isSuccess: isAligned,
              icon: isAligned ? Icons.check_circle : Icons.navigation_rounded,
              text: isNorthernHemisphere
                  ? (isAligned
                        ? (isBangla
                              ? 'নিখুঁত দক্ষিণ দিক! (180° South)'
                              : 'Aligned with South (180°)')
                        : (isBangla
                              ? 'দক্ষিণ দিকে (১৮০°) ঘোরান'
                              : 'Rotate to 180° South'))
                  : (isAligned
                        ? (isBangla
                              ? 'নিখুঁত উত্তর দিক! (0° North)'
                              : 'Aligned with North (0°)')
                        : (isBangla
                              ? 'উত্তর দিকে (০°) ঘোরান'
                              : 'Rotate to 0° North')),
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
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 28,
                      offset: Offset(-rotY * 45, rotX * 45 + 14),
                    ),
                    BoxShadow(
                      color: isAligned
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : const Color(0xFF38BDF8).withValues(alpha: 0.12),
                      blurRadius: 22,
                    ),
                  ],
                  border: Border.all(
                    color: isAligned ? const Color(0xFF10B981) : Colors.white24,
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
                        painter: CompassDialPainter(
                          targetHeading: isNorthernHemisphere ? 180 : 0,
                        ),
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
                            _getDirectionName(positiveHeading, isBangla),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isAligned
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
              isNorthernHemisphere
                  ? (isBangla
                        ? 'উত্তর গোলার্ধে (${_latitude.toStringAsFixed(1)}°N) সর্বোচ্চ সৌরশক্তির জন্য প্যানেলটি ১৮০° দক্ষিণমুখী করে স্থাপন করুন।'
                        : 'In the Northern Hemisphere (${_latitude.toStringAsFixed(1)}°N), face panels due South (180°).')
                  : (isBangla
                        ? 'দক্ষিণ গোলার্ধে (${_latitude.abs().toStringAsFixed(1)}°S) সর্বোচ্চ সৌরশক্তির জন্য প্যানেলটি ০° উত্তরমুখী করে স্থাপন করুন।'
                        : 'In the Southern Hemisphere (${_latitude.abs().toStringAsFixed(1)}°S), face panels due North (0°).'),
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
    const double maxOffset = 95.0;
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
                      color: Colors.black.withValues(alpha: 0.7),
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
                                      .withValues(alpha: 0.55),
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
                              color: Colors.white.withValues(alpha: 0.85),
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

  // ================= ৩. ডায়নামিক চাঁদা / ইনক্লিনোমিটার ভিউ =================
  Widget _buildProtractorView(bool isBangla) {
    final double angleRad = math.atan2(
      _accelY.abs(),
      math.sqrt(_accelX * _accelX + _accelZ * _accelZ),
    );
    final double angleDeg = (angleRad * (180.0 / math.pi)).clamp(0.0, 90.0);

    // লোকেশন ও ঋতু অনুযায়ী আদর্শ সৌর কোণ
    final double optimalTilt = _getTargetTiltAngle();
    final double minOpt = (optimalTilt - 1.5).clamp(0.0, 90.0);
    final double maxOpt = (optimalTilt + 1.5).clamp(0.0, 90.0);
    final bool isOptimal = angleDeg >= minOpt && angleDeg <= maxOpt;

    // হ্যাপটিক ফিডব্যাক ট্রিগার
    if (isOptimal && !_wasAligned) {
      HapticFeedback.mediumImpact();
      _wasAligned = true;
    } else if (!isOptimal && _wasAligned) {
      _wasAligned = false;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          children: [
            // ঋতুভিত্তিক লক্ষ্য কোণ নির্বাচন চিপ (বার্ষিক / গ্রীষ্ম / শীত)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  _buildSeasonChip(
                    mode: TiltSeasonMode.annual,
                    label: isBangla ? 'বার্ষিক গড়' : 'Annual',
                  ),
                  const SizedBox(width: 4),
                  _buildSeasonChip(
                    mode: TiltSeasonMode.summer,
                    label: isBangla ? 'গ্রীষ্মকাল' : 'Summer',
                  ),
                  const SizedBox(width: 4),
                  _buildSeasonChip(
                    mode: TiltSeasonMode.winter,
                    label: isBangla ? 'শীতকাল' : 'Winter',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            _buildStatusBadge(
              isSuccess: isOptimal,
              icon: isOptimal ? Icons.wb_sunny_rounded : Icons.tune_rounded,
              text: isOptimal
                  ? (isBangla
                        ? '✓ সর্বোত্তম সৌর কোণ (${optimalTilt.toStringAsFixed(1)}°)'
                        : '✓ Optimal Solar Tilt (${optimalTilt.toStringAsFixed(1)}°)')
                  : (isBangla
                        ? 'লক্ষ্য কোণ: ${optimalTilt.toStringAsFixed(1)}° (অক্ষাংশ ${_latitude.abs().toStringAsFixed(1)}°)'
                        : 'Target Angle: ${optimalTilt.toStringAsFixed(1)}° (Lat ${_latitude.abs().toStringAsFixed(1)}°)'),
            ),
            const SizedBox(height: 22),

            // ১. মূল অ্যানালগ চাঁদা ও পেন্ডুলাম সুইং গেজ (ডায়নামিক টার্গেট জোনসহ)
            SizedBox(
              width: 320,
              height: 205,
              child: CustomPaint(
                painter: GraphicalProtractorPainter(
                  currentAngle: angleDeg,
                  optimalTilt: optimalTilt,
                  isOptimal: isOptimal,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ২. ডিজিটাল পাঠ ও গ্লোয়িং ডিসপ্লে
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOptimal ? const Color(0xFF10B981) : Colors.white12,
                  width: isOptimal ? 2.0 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isOptimal
                        ? const Color(0xFF10B981).withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.4),
                    blurRadius: isOptimal ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        angleDeg.toStringAsFixed(1),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: isOptimal
                              ? const Color(0xFF34D399)
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '°',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isOptimal
                              ? const Color(0xFF10B981)
                              : const Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isBangla
                        ? 'বর্তমান ঢাল (TILT ANGLE)'
                        : 'CURRENT TILT ANGLE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: isOptimal
                          ? const Color(0xFF6EE7B7)
                          : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ৩. লাইভ প্যানেল টিল্ট সিমুলেশন ও নির্দেশিকা কার্ড
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isOptimal
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 58,
                    height: 48,
                    child: CustomPaint(
                      painter: MiniPanelProfilePainter(
                        tiltDeg: angleDeg,
                        isOptimal: isOptimal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      isBangla
                          ? 'প্যানেল বা টিনের চালার ওপর ফোনের দীর্ঘ প্রান্তটি সমান্তরালভাবে রেখে কোণ মিলিয়ে নিন।'
                          : 'Rest the long edge of the phone flush against the panel surface to match the tilt.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        height: 1.45,
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

  Widget _buildSeasonChip({
    required TiltSeasonMode mode,
    required String label,
  }) {
    final bool isSelected = _seasonMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _seasonMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF10B981).withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF34D399) : Colors.white60,
              ),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFF065F46).withValues(alpha: 0.8)
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
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: isSuccess ? const Color(0xFF34D399) : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDirectionName(double deg, bool isBangla) {
    if (isBangla) {
      if (deg >= 337.5 || deg < 22.5) return 'উত্তর (N)';
      if (deg >= 22.5 && deg < 67.5) return 'উত্তর-পূর্ব (NE)';
      if (deg >= 67.5 && deg < 112.5) return 'পূর্ব (E)';
      if (deg >= 112.5 && deg < 157.5) return 'দক্ষিণ-পূর্ব (SE)';
      if (deg >= 157.5 && deg < 202.5) return 'দক্ষিণ (S)';
      if (deg >= 202.5 && deg < 247.5) return 'দক্ষিণ-পশ্চিম (SW)';
      if (deg >= 247.5 && deg < 292.5) return 'পশ্চিম (W)';
      return 'উত্তর-পশ্চিম (NW)';
    } else {
      if (deg >= 337.5 || deg < 22.5) return 'North (N)';
      if (deg >= 22.5 && deg < 67.5) return 'North-East (NE)';
      if (deg >= 67.5 && deg < 112.5) return 'East (E)';
      if (deg >= 112.5 && deg < 157.5) return 'South-East (SE)';
      if (deg >= 157.5 && deg < 202.5) return 'South (S)';
      if (deg >= 202.5 && deg < 247.5) return 'South-West (SW)';
      if (deg >= 247.5 && deg < 292.5) return 'West (W)';
      return 'North-West (NW)';
    }
  }
}

// ----------------- কাস্টম পেইন্টারসমূহ -----------------

class CompassDialPainter extends CustomPainter {
  final int targetHeading;

  CompassDialPainter({this.targetHeading = 180});

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
      tickPaint.color = i == targetHeading
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
              color: i == targetHeading
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
  bool shouldRepaint(covariant CompassDialPainter oldDelegate) =>
      oldDelegate.targetHeading != targetHeading;
}

/// 🎨 ডায়নামিক ১৮০° গ্রাফিক্যাল চাঁদা ও সুইং নিডেল পেইন্টার
class GraphicalProtractorPainter extends CustomPainter {
  final double currentAngle;
  final double optimalTilt;
  final bool isOptimal;

  GraphicalProtractorPainter({
    required this.currentAngle,
    required this.optimalTilt,
    required this.isOptimal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 4);
    final radius = size.width / 2 - 16;

    // ১. ব্যাকগ্রাউন্ড মেটালিক চাঁদা ট্র্যাক
    final bgArcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgArcPaint,
    );

    // ২. ডায়নামিক অপটিমাল সোলার টার্গেট জোন (optimalTilt ± 1.5°)
    final double startDeg = (optimalTilt - 1.5).clamp(0.0, 87.0);
    final double optStartRad = math.pi + (startDeg * (math.pi / 180.0));
    final double optSweepRad = 3.0 * (math.pi / 180.0);

    final optZonePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      optStartRad,
      optSweepRad,
      false,
      optZonePaint,
    );

    // ৩. টিক মার্ক ও ডিগ্রি লেবেল
    final tickPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int deg = 0; deg <= 90; deg += 5) {
      final rad = math.pi + deg * (math.pi / 180.0);
      final bool isMajor = (deg % 15 == 0);
      final double tickLen = isMajor ? 12.0 : 6.0;

      final startOffset = Offset(
        center.dx + (radius - 12) * math.cos(rad),
        center.dy + (radius - 12) * math.sin(rad),
      );
      final endOffset = Offset(
        center.dx + (radius - 12 - tickLen) * math.cos(rad),
        center.dy + (radius - 12 - tickLen) * math.sin(rad),
      );

      canvas.drawLine(
        startOffset,
        endOffset,
        isMajor ? majorTickPaint : tickPaint,
      );

      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$deg°',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelRadius = radius - 34;
        final labelOffset = Offset(
          center.dx + labelRadius * math.cos(rad) - tp.width / 2,
          center.dy + labelRadius * math.sin(rad) - tp.height / 2,
        );
        tp.paint(canvas, labelOffset);
      }
    }

    // ৪. লাইভ সুইং পেন্ডুলাম নিডেল (Needle Pointer)
    final clampedAngle = currentAngle.clamp(0.0, 90.0);
    final needleRad = math.pi + clampedAngle * (math.pi / 180.0);
    final needleEnd = Offset(
      center.dx + (radius + 6) * math.cos(needleRad),
      center.dy + (radius + 6) * math.sin(needleRad),
    );

    final needlePaint = Paint()
      ..color = isOptimal ? const Color(0xFF34D399) : const Color(0xFF38BDF8)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: isOptimal
            ? [const Color(0xFF059669), const Color(0xFF34D399)]
            : [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
      ).createShader(Rect.fromPoints(center, needleEnd));

    canvas.drawLine(center, needleEnd, needlePaint);

    // ৫. পিভট কোর সার্কেল
    final pivotPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final pivotBorder = Paint()
      ..color = isOptimal ? const Color(0xFF10B981) : Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, 11, pivotPaint);
    canvas.drawCircle(center, 11, pivotBorder);
    canvas.drawCircle(
      center,
      4,
      Paint()
        ..color = isOptimal ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
    );
  }

  @override
  bool shouldRepaint(covariant GraphicalProtractorPainter oldDelegate) {
    return oldDelegate.currentAngle != currentAngle ||
        oldDelegate.optimalTilt != optimalTilt ||
        oldDelegate.isOptimal != isOptimal;
  }
}

/// 📐 নিচের মিনি সোলার প্যানেল প্রোফাইল ড্রয়ার
class MiniPanelProfilePainter extends CustomPainter {
  final double tiltDeg;
  final bool isOptimal;

  MiniPanelProfilePainter({required this.tiltDeg, required this.isOptimal});

  @override
  void paint(Canvas canvas, Size size) {
    final double originX = 8.0;
    final double originY = size.height - 6.0;
    final double panelLen = 42.0;
    final double rad = tiltDeg * (math.pi / 180.0);

    // অনুভূমিক বেসলাইন
    final groundPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.8;
    canvas.drawLine(
      Offset(0, originY),
      Offset(size.width, originY),
      groundPaint,
    );

    // কাত হওয়া সোলার প্যানেল লাইন
    final endX = originX + panelLen * math.cos(rad);
    final endY = originY - panelLen * math.sin(rad);

    final panelPaint = Paint()
      ..color = isOptimal ? const Color(0xFF34D399) : Colors.amber
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(originX, originY), Offset(endX, endY), panelPaint);

    // টিল্ট কার্ভ ইন্ডিকেটর
    if (tiltDeg > 6) {
      final arcPaint = Paint()
        ..color = isOptimal
            ? const Color(0xFF10B981).withValues(alpha: 0.6)
            : const Color(0xFF38BDF8).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(originX, originY), radius: 18),
        -rad,
        rad,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MiniPanelProfilePainter oldDelegate) =>
      oldDelegate.tiltDeg != tiltDeg || oldDelegate.isOptimal != isOptimal;
}
