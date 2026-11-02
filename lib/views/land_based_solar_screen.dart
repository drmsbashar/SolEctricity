import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_search_service.dart';
import '../services/solar_radiation_service.dart';

enum DrawingMode { boundary, obstacle }

class LandBasedSolarScreen extends StatefulWidget {
  final bool isBangla;

  const LandBasedSolarScreen({super.key, this.isBangla = true});

  @override
  State<LandBasedSolarScreen> createState() => _LandBasedSolarScreenState();
}

class _LandBasedSolarScreenState extends State<LandBasedSolarScreen> {
  late bool _isBangla;
  GoogleMapController? _mapController;

  final TextEditingController _searchController = TextEditingController();
  List<PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchBarVisible = false;

  bool _isInteractingWithControls = false;
  bool _isModalOpen = false;

  DrawingMode _currentMode = DrawingMode.boundary;

  final List<LatLng> _boundaryPoints = [];
  final List<List<LatLng>> _obstacles = [];
  List<LatLng> _currentObstaclePoints = [];

  double _totalAreaSqM = 0.0;
  double _obstacleAreaSqM = 0.0;

  BitmapDescriptor? _whiteDotIcon;
  static const LatLng _initialPosition = LatLng(23.8103, 90.4125);

  // ⚡ সোলার সাইজিং ও নাসা থেকে প্রাপ্ত ডাটা
  double _selectedModuleEfficiency = 0.215;
  int _selectedModuleWatt = 550;
  bool _isLoadingNasa = false;
  double? _nasaPeakSunHours;
  Map<String, double> _monthlyPsh = {};
  double _ambientTemp = 26.0;
  double _tempMax = 32.0;
  double _tempMin = 20.0;
  double _windSpeed = 3.5;
  Map<String, double> _monthlyTempAvg = {};
  Map<String, double> _monthlyTempMax = {};
  Map<String, double> _monthlyTempMin = {};
  bool _isCoastal = false;
  String _locationPlaceName = '';

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _createWhiteDotIcon();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createWhiteDotIcon() async {
    const int size = 12;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, dotPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();

    if (mounted) {
      setState(() {
        _whiteDotIcon = BitmapDescriptor.bytes(bytes);
      });
    }
  }

  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    const double earthRadius = 6378137.0;
    double area = 0.0;

    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];

      final double lat1 = p1.latitude * (math.pi / 180.0);
      final double lat2 = p2.latitude * (math.pi / 180.0);
      final double lonDiff = (p2.longitude - p1.longitude) * (math.pi / 180.0);

      area += lonDiff * (2.0 + math.sin(lat1) + math.sin(lat2));
    }

    area = (area.abs() * earthRadius * earthRadius) / 4.0;
    return area;
  }

  void _recalculateAreas() {
    _totalAreaSqM = _calculatePolygonArea(_boundaryPoints);

    double obsTotal = 0.0;
    for (final obs in _obstacles) {
      obsTotal += _calculatePolygonArea(obs);
    }
    if (_currentObstaclePoints.length >= 3) {
      obsTotal += _calculatePolygonArea(_currentObstaclePoints);
    }
    _obstacleAreaSqM = obsTotal;
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return _initialPosition;
    double latSum = 0.0;
    double lngSum = 0.0;
    for (var p in points) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  double _calculateDynamicPackingFactor(double latitude) {
    final double absLat = latitude.abs();
    if (absLat <= 15.0) {
      return 0.75;
    } else if (absLat <= 25.0) {
      return 0.75 - ((absLat - 15.0) / 10.0) * 0.07;
    } else if (absLat <= 35.0) {
      return 0.68 - ((absLat - 25.0) / 10.0) * 0.08;
    } else {
      return 0.58;
    }
  }

  double _calculateOptimalTilt(double latitude) {
    return (latitude.abs() * 0.90).clamp(10.0, 45.0);
  }

  double _calculateTempDerateFactor(double ambientTemp) {
    const double noct = 45.0;
    const double tempCoeff = 0.0035;
    final double cellTemp = ambientTemp + (noct - 20.0);
    if (cellTemp <= 25.0) return 1.0;
    final double loss = (cellTemp - 25.0) * tempCoeff;
    return (1.0 - loss).clamp(0.75, 1.0);
  }

  void _onMapTapped(LatLng position) {
    if (_isInteractingWithControls || _isModalOpen) return;

    if (_isSearchBarVisible) {
      setState(() {
        _isSearchBarVisible = false;
        _searchResults = [];
      });
      FocusScope.of(context).unfocus();
      return;
    }

    setState(() {
      if (_currentMode == DrawingMode.boundary) {
        _boundaryPoints.add(position);
      } else {
        _currentObstaclePoints.add(position);
      }
      _recalculateAreas();
    });
  }

  void _completeCurrentObstacle() {
    if (_currentObstaclePoints.length >= 3) {
      setState(() {
        _obstacles.add(List.from(_currentObstaclePoints));
        _currentObstaclePoints.clear();
        _recalculateAreas();
      });
    }
  }

  void _undoLastPoint() {
    setState(() {
      if (_currentMode == DrawingMode.boundary) {
        if (_boundaryPoints.isNotEmpty) {
          _boundaryPoints.removeLast();
        }
      } else {
        if (_currentObstaclePoints.isNotEmpty) {
          _currentObstaclePoints.removeLast();
        } else if (_obstacles.isNotEmpty) {
          _currentObstaclePoints = _obstacles.removeLast();
        }
      }
      _recalculateAreas();
    });
  }

  void _clearAll() {
    setState(() {
      _boundaryPoints.clear();
      _obstacles.clear();
      _currentObstaclePoints.clear();
      _totalAreaSqM = 0.0;
      _obstacleAreaSqM = 0.0;
      _nasaPeakSunHours = null;
      _monthlyPsh = {};
      _ambientTemp = 26.0;
      _tempMax = 32.0;
      _tempMin = 20.0;
      _windSpeed = 3.5;
      _monthlyTempAvg = {};
      _monthlyTempMax = {};
      _monthlyTempMin = {};
      _isCoastal = false;
      _locationPlaceName = '';
    });
  }

  void _onSearchChanged(String query) async {
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    final results = await LocationSearchService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectPlace(PlaceSearchResult place) {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchResults = [];
      _isSearchBarVisible = false;
      _searchController.clear();
    });

    final target = LatLng(place.latitude, place.longitude);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 19.5),
      ),
    );
  }

  Widget _buildControlWrapper({required Widget child}) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isInteractingWithControls = true),
      onExit: (_) => setState(() => _isInteractingWithControls = false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => setState(() => _isInteractingWithControls = true),
        onPointerUp: (_) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) {
              setState(() => _isInteractingWithControls = false);
            }
          });
        },
        child: child,
      ),
    );
  }

  Future<void> _openSolarEstimationSheet(double netUsableSqM) async {
    final centroid = _calculateCentroid(_boundaryPoints);

    setState(() {
      _isLoadingNasa = true;
      _isModalOpen = true;
    });

    try {
      final radResult = await SolarRadiationService.fetchPshByCoordinates(
        centroid.latitude,
        centroid.longitude,
      );
      _nasaPeakSunHours = radResult.peakSunHours;
      _monthlyPsh = radResult.monthlyPsh;
      _ambientTemp = radResult.ambientTemp;
      _tempMax = radResult.tempMax;
      _tempMin = radResult.tempMin;
      _windSpeed = radResult.windSpeed;
      _monthlyTempAvg = radResult.monthlyTempAvg;
      _monthlyTempMax = radResult.monthlyTempMax;
      _monthlyTempMin = radResult.monthlyTempMin;
      _isCoastal = radResult.isCoastal;
      _locationPlaceName = radResult.placeName;
    } catch (_) {
      _nasaPeakSunHours = SolarRadiationService.defaultPsh;
    } finally {
      if (mounted) setState(() => _isLoadingNasa = false);
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final double dynamicPackingFactor = _calculateDynamicPackingFactor(
              centroid.latitude,
            );
            final double effectivePanelAreaSqM =
                netUsableSqM * dynamicPackingFactor;
            final double systemCapacityKwp =
                effectivePanelAreaSqM * _selectedModuleEfficiency;
            final int totalModules =
                ((systemCapacityKwp * 1000) / _selectedModuleWatt).round();

            final double tempDerate = _calculateTempDerateFactor(_ambientTemp);
            final double psh =
                _nasaPeakSunHours ?? SolarRadiationService.defaultPsh;
            final double effectivePR = 0.80 * tempDerate;
            final double dailyGenerationKwh =
                systemCapacityKwp * psh * effectivePR;
            final double monthlyGenerationKwh = dailyGenerationKwh * 30;

            final double optimalTilt = _calculateOptimalTilt(centroid.latitude);

            return DefaultTabController(
              length: 3,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.60,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _isBangla
                                ? 'সৌর সম্ভাব্যতা বিশ্লেষণ'
                                : 'Solar Potential Analysis',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // 🛰️ উপরে ডানপাশে শুধুমাত্র ডেটা সোর্স
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.satellite_alt_rounded,
                                color: Colors.cyanAccent,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'NASA POWER',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TabBar(
                      indicatorColor: Colors.cyanAccent,
                      indicatorWeight: 2.5,
                      labelColor: Colors.cyanAccent,
                      unselectedLabelColor: Colors.white54,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.solar_power, size: 18),
                          text: _isBangla ? 'সাইজিং' : 'Sizing',
                        ),
                        Tab(
                          icon: const Icon(Icons.bar_chart_rounded, size: 18),
                          text: _isBangla ? 'উৎপাদন' : 'Generation',
                        ),
                        Tab(
                          icon: const Icon(
                            Icons.engineering_outlined,
                            size: 18,
                          ),
                          text: _isBangla ? 'ইনস্টলেশন' : 'Installation',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: TabBarView(
                        children: [
                          // ---------------- ট্যাব ১: সাইজিং ----------------
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.explore_outlined,
                                        size: 14,
                                        color: Colors.cyanAccent,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _isBangla
                                              ? 'অক্ষাংশ: ${centroid.latitude.toStringAsFixed(2)}°N | প্যাকিং: ${(dynamicPackingFactor * 100).toStringAsFixed(1)}%'
                                              : 'Lat: ${centroid.latitude.toStringAsFixed(2)}°N | Packing: ${(dynamicPackingFactor * 100).toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isBangla
                                                  ? 'প্যানেল দক্ষতা'
                                                  : 'Module Efficiency',
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11,
                                              ),
                                            ),
                                            DropdownButton<double>(
                                              value: _selectedModuleEfficiency,
                                              isDense: true,
                                              dropdownColor: const Color(
                                                0xFF0F172A,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.cyanAccent,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              underline: const SizedBox(),
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
                                                  setSheetState(
                                                    () =>
                                                        _selectedModuleEfficiency =
                                                            val,
                                                  );
                                                  setState(
                                                    () =>
                                                        _selectedModuleEfficiency =
                                                            val,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 35,
                                        color: Colors.white12,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isBangla
                                                  ? 'মডিউল ক্ষমতা'
                                                  : 'Module Rating',
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11,
                                              ),
                                            ),
                                            DropdownButton<int>(
                                              value: _selectedModuleWatt,
                                              isDense: true,
                                              dropdownColor: const Color(
                                                0xFF0F172A,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.cyanAccent,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              underline: const SizedBox(),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 150,
                                                  child: Text('150 Watt'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 250,
                                                  child: Text('250 Watt'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 330,
                                                  child: Text('330 Watt'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 400,
                                                  child: Text('400 Watt'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 450,
                                                  child: Text('450 Watt'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 550,
                                                  child: Text('550 Watt'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 620,
                                                  child: Text('620 Watt'),
                                                ),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setSheetState(
                                                    () => _selectedModuleWatt =
                                                        val,
                                                  );
                                                  setState(
                                                    () => _selectedModuleWatt =
                                                        val,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    _buildStatCard(
                                      title: _isBangla
                                          ? 'ইনস্টলযোগ্য ক্ষমতা'
                                          : 'DC Capacity',
                                      value:
                                          '${systemCapacityKwp.toStringAsFixed(2)} kWp',
                                      subtitle:
                                          'কার্যকর: ${effectivePanelAreaSqM.toStringAsFixed(1)} m²',
                                      icon: Icons.flash_on_rounded,
                                      color: Colors.greenAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatCard(
                                      title: _isBangla
                                          ? 'প্রয়োজনীয় প্যানেল'
                                          : 'Total Panels',
                                      value: _isBangla
                                          ? '$totalModules টি'
                                          : '$totalModules pcs', // 💡 বাংলা হলে 'টি', ইংরেজি হলে 'pcs'
                                      subtitle:
                                          '$_selectedModuleWatt Watt Modules',
                                      icon: Icons.grid_view_rounded,
                                      color: Colors.amberAccent,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildStatCard(
                                      title: _isBangla
                                          ? 'দৈনিক বিদ্যুৎ'
                                          : 'Daily Output',
                                      value:
                                          '${dailyGenerationKwh.toStringAsFixed(1)} kWh',
                                      subtitle: _isBangla
                                          ? 'ইউনিট / দিন'
                                          : 'kWh / Day',
                                      icon: Icons.wb_sunny_rounded,
                                      color: Colors.cyanAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatCard(
                                      title: _isBangla
                                          ? 'মাসিক বিদ্যুৎ'
                                          : 'Monthly Output',
                                      value:
                                          '${monthlyGenerationKwh.toStringAsFixed(0)} kWh',
                                      subtitle: _isBangla
                                          ? 'ইউনিট / মাস'
                                          : 'kWh / Month',
                                      icon: Icons.calendar_month_rounded,
                                      color: Colors.tealAccent,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ---------------- ট্যাব ২: উৎপাদন ও আবহাওয়া ----------------
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🌡️ তাপমাত্রা এরিয়া গ্রাফ (যার ভেতরেই লস ও PR যুক্ত)
                                if (_monthlyTempAvg.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.thermostat_rounded,
                                                  color: Colors.orangeAccent,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _isBangla
                                                      ? 'তাপমাত্রা প্রোফাইল (°C)'
                                                      : 'Temperature Profile (°C)',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // 💡 থার্মাল লস ও পারফরম্যান্স রেশিও ফ্যাক্টর
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.redAccent
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Text(
                                                _isBangla
                                                    ? 'তাপমাত্রা লস: ${((1.0 - tempDerate) * 100).toStringAsFixed(1)}% | PR: ${(effectivePR * 100).toStringAsFixed(0)}%'
                                                    : 'Thermal Loss: ${((1.0 - tempDerate) * 100).toStringAsFixed(1)}% | PR: ${(effectivePR * 100).toStringAsFixed(0)}%',
                                                style: const TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // গ্রাফ কন্টেইনার (Y-Axis সহ)
                                        SizedBox(
                                          height: 105,
                                          child: TemperatureEnvelopeWithAxis(
                                            tempAvg: _monthlyTempAvg,
                                            tempMax: _monthlyTempMax,
                                            tempMin: _monthlyTempMin,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),

                                // 📊 ১২ মাসের সৌর বিকিরণ (PSH) বার-গ্রাফ (Y-Axis ও গড়ের লাইন সহ)
                                if (_monthlyPsh.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.wb_sunny_rounded,
                                                  color: Colors.amberAccent,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _isBangla
                                                      ? 'সৌর বিকিরণ (PSH)'
                                                      : 'Solar Radiation (PSH)',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // 💡 গ্রাফের ভেতরেই বাৎসরিক গড় PSH
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.amberAccent
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.amberAccent
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Text(
                                                _isBangla
                                                    ? 'বাৎসরিক গড়: ${psh.toStringAsFixed(2)} hrs'
                                                    : 'Annual Avg: ${psh.toStringAsFixed(2)} hrs',
                                                style: const TextStyle(
                                                  color: Colors.amberAccent,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          height: 125,
                                          child: SolarPshChartWithAxis(
                                            monthlyPsh: _monthlyPsh,
                                            annualAvgPsh: psh,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // ---------------- ট্যাব ৩: ইনস্টলেশন গাইড ----------------
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildStatCard(
                                      title: _isBangla
                                          ? 'আদর্শ কাত কোণ'
                                          : 'Optimal Tilt',
                                      value:
                                          '${optimalTilt.toStringAsFixed(1)}°',
                                      subtitle: _isBangla
                                          ? 'বার্ষিক সর্বোচ্চ উৎপাদন'
                                          : 'Annual Optimization',
                                      icon: Icons.straighten_rounded,
                                      color: Colors.amberAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatCard(
                                      title: _isBangla
                                          ? 'দিকবিন্যাস (Azimuth)'
                                          : 'Optimal Azimuth',
                                      value: '180° (South)',
                                      subtitle: _isBangla
                                          ? 'ঠিক দক্ষিণমুখী'
                                          : 'True South Facing',
                                      icon: Icons.compass_calibration_rounded,
                                      color: Colors.cyanAccent,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _isCoastal
                                        ? Colors.redAccent.withValues(
                                            alpha: 0.12,
                                          )
                                        : Colors.blueGrey.withValues(
                                            alpha: 0.15,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isCoastal
                                          ? Colors.redAccent.withValues(
                                              alpha: 0.35,
                                            )
                                          : Colors.white12,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _isCoastal
                                            ? Icons.warning_amber_rounded
                                            : Icons.info_outline_rounded,
                                        color: _isCoastal
                                            ? Colors.redAccent
                                            : Colors.cyanAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isCoastal
                                                  ? (_isBangla
                                                        ? 'উচ্চ বায়ুপ্রবাহ / উপকূলীয় সতর্কতা'
                                                        : 'High Wind / Coastal Advisory')
                                                  : (_isBangla
                                                        ? 'মাউন্টিং স্ট্রাকচার পরামর্শ'
                                                        : 'Mounting Structure Advisory'),
                                              style: TextStyle(
                                                color: _isCoastal
                                                    ? Colors.redAccent
                                                    : Colors.cyanAccent,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _isCoastal
                                                  ? (_isBangla
                                                        ? 'উচ্চ বায়ুপ্রবাহ এলাকা (বাৎসরিক গড় বেগ: $_windSpeed m/s)। মাউন্টিং স্ট্রাকচারে ১৪০ কিমি/ঘণ্টা বায়ুচাপ প্রতিরোধী চ্যানেল ও রুফ অ্যাংকর ব্যবহার করুন।'
                                                        : 'High wind zone (Annual avg speed: $_windSpeed m/s). Design structure to withstand up to 140 km/h wind uplift.')
                                                  : (_isBangla
                                                        ? 'বাতাসের স্বাভাবিক গতিবেগ ($_windSpeed m/s)। সমতল ছাদে প্যানেলের নিচে পর্যাপ্ত ফাঁকা রাখুন যাতে বাতাস সহজে চলাচল করতে পারে।'
                                                        : 'Normal wind speed ($_windSpeed m/s). Ensure adequate clearance below panels on flat roofs for natural convective cooling.'),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isModalOpen = false);
      }
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
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
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
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
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double netUsableSqM = math.max(0.0, _totalAreaSqM - _obstacleAreaSqM);
    final double netUsableSqFt = netUsableSqM * 10.7639;

    final Set<Polygon> polygons = {};

    if (_boundaryPoints.length >= 3) {
      polygons.add(
        Polygon(
          polygonId: const PolygonId('boundary_polygon'),
          points: _boundaryPoints,
          strokeWidth: 2,
          strokeColor: Colors.amberAccent,
          fillColor: Colors.cyanAccent.withValues(alpha: 0.22),
        ),
      );
    }

    for (int i = 0; i < _obstacles.length; i++) {
      polygons.add(
        Polygon(
          polygonId: PolygonId('obstacle_$i'),
          points: _obstacles[i],
          strokeWidth: 2,
          strokeColor: Colors.redAccent,
          fillColor: Colors.redAccent.withValues(alpha: 0.38),
        ),
      );
    }

    if (_currentObstaclePoints.length >= 3) {
      polygons.add(
        Polygon(
          polygonId: const PolygonId('current_obstacle'),
          points: _currentObstaclePoints,
          strokeWidth: 2,
          strokeColor: Colors.orangeAccent,
          fillColor: Colors.redAccent.withValues(alpha: 0.38),
        ),
      );
    }

    final Set<Polyline> polylines = {};
    if (_boundaryPoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('boundary_line'),
          points: _boundaryPoints,
          color: Colors.amberAccent,
          width: 3,
        ),
      );
    }
    if (_currentObstaclePoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('current_obs_line'),
          points: _currentObstaclePoints,
          color: Colors.redAccent,
          width: 3,
        ),
      );
    }

    final Set<Marker> markers = {};
    if (_whiteDotIcon != null) {
      for (int i = 0; i < _boundaryPoints.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('b_dot_$i'),
            position: _boundaryPoints[i],
            icon: _whiteDotIcon!,
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
      for (int j = 0; j < _obstacles.length; j++) {
        for (int k = 0; k < _obstacles[j].length; k++) {
          markers.add(
            Marker(
              markerId: MarkerId('obs_${j}_dot_$k'),
              position: _obstacles[j][k],
              icon: _whiteDotIcon!,
              anchor: const Offset(0.5, 0.5),
            ),
          );
        }
      }
      for (int i = 0; i < _currentObstaclePoints.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('cur_obs_dot_$i'),
            position: _currentObstaclePoints[i],
            icon: _whiteDotIcon!,
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    }

    final bool hasAnyPoints =
        _boundaryPoints.isNotEmpty ||
        _obstacles.isNotEmpty ||
        _currentObstaclePoints.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isBangla ? 'ছাদ বা জমি পরিমাপ' : 'Rooftop or Land Sizing',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (hasAnyPoints) ...[
            IconButton(
              tooltip: _isBangla ? 'আগের পয়েন্ট বাতিল' : 'Undo Point',
              icon: const Icon(Icons.undo_rounded, color: Colors.amberAccent),
              onPressed: _undoLastPoint,
            ),
            IconButton(
              tooltip: _isBangla ? 'সব মুছুন' : 'Clear All',
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
              ),
              onPressed: _clearAll,
            ),
          ],
          IconButton(
            onPressed: () => setState(() => _isBangla = !_isBangla),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
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
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _initialPosition,
                zoom: 16.0,
              ),
              mapType: MapType.satellite,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              polygons: polygons,
              polylines: polylines,
              markers: markers,
              onTap: _onMapTapped,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 12,
            child: SafeArea(
              child: _buildControlWrapper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildModeButton(
                                mode: DrawingMode.boundary,
                                label: _isBangla ? 'সীমানা' : 'Boundary',
                                icon: Icons.crop_square_rounded,
                                activeColor: Colors.cyanAccent,
                              ),
                              const SizedBox(width: 4),
                              _buildModeButton(
                                mode: DrawingMode.obstacle,
                                label: _isBangla ? 'বাধা/ছায়া' : 'Obstacle',
                                icon: Icons.block_rounded,
                                activeColor: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Material(
                          color: _isSearchBarVisible
                              ? Colors.redAccent
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          elevation: 4,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _isSearchBarVisible = !_isSearchBarVisible;
                                if (!_isSearchBarVisible) {
                                  _searchResults = [];
                                  _searchController.clear();
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Icon(
                                _isSearchBarVisible
                                    ? Icons.close_rounded
                                    : Icons.search_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isSearchBarVisible) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                          ),
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: _isBangla
                                ? 'এলাকা বা ভবনের নাম লিখুন...'
                                : 'Search area or building name...',
                            hintStyle: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12.5,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.cyanAccent,
                              size: 20,
                            ),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.cyanAccent,
                                      ),
                                    ),
                                  )
                                : (_searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchResults = []);
                                          },
                                        )
                                      : null),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.cyanAccent,
                                  size: 18,
                                ),
                                title: Text(
                                  item.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () => _selectPlace(item),
                              );
                            },
                          ),
                        ),
                    ],
                    if (_currentMode == DrawingMode.obstacle &&
                        _currentObstaclePoints.length >= 3) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(
                            _isBangla
                                ? 'বাধা সম্পন্ন করুন'
                                : 'Complete Obstacle',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _completeCurrentObstacle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: _buildControlWrapper(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (_boundaryPoints.length < 3)
                                ? Colors.amberAccent.withValues(alpha: 0.15)
                                : Colors.greenAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.solar_power_rounded,
                            color: (_boundaryPoints.length < 3)
                                ? Colors.amberAccent
                                : Colors.greenAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isBangla
                                    ? 'কার্যকর ব্যবহারযোগ্য এলাকা'
                                    : 'Net Usable Solar Area',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _boundaryPoints.length < 3
                                    ? (_isBangla
                                          ? 'সীমানা নির্ধারণ করুন (${_boundaryPoints.length}/৩)'
                                          : 'Mark the boundary (${_boundaryPoints.length}/3)')
                                    : '${netUsableSqFt.toStringAsFixed(1)} sq.ft  (${netUsableSqM.toStringAsFixed(1)} m²)',
                                style: TextStyle(
                                  color: _boundaryPoints.length < 3
                                      ? Colors.amberAccent
                                      : Colors.greenAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_boundaryPoints.length >= 3)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            onPressed: _isLoadingNasa
                                ? null
                                : () => _openSolarEstimationSheet(netUsableSqM),
                            child: _isLoadingNasa
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0F172A),
                                    ),
                                  )
                                : Text(
                                    _isBangla ? 'হিসাব' : 'Analyze',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                    if (_obstacleAreaSqM > 0 &&
                        _boundaryPoints.length >= 3) ...[
                      const Divider(color: Colors.white12, height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isBangla
                                ? 'মোট ছাদ: ${(_totalAreaSqM * 10.7639).toStringAsFixed(0)} sq.ft'
                                : 'Total Roof: ${(_totalAreaSqM * 10.7639).toStringAsFixed(0)} sq.ft',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            _isBangla
                                ? 'বাধা/ছায়া: -${(_obstacleAreaSqM * 10.7639).toStringAsFixed(0)} sq.ft'
                                : 'Obstacle: -${(_obstacleAreaSqM * 10.7639).toStringAsFixed(0)} sq.ft',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required DrawingMode mode,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final bool isSelected = _currentMode == mode;
    return Material(
      color: isSelected
          ? activeColor.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          if (_currentMode == DrawingMode.obstacle &&
              mode == DrawingMode.boundary) {
            _completeCurrentObstacle();
          }
          setState(() => _currentMode = mode);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: activeColor, width: 1.2)
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : Colors.white60,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 📈 ১. তাপমাত্রা এরিয়া গ্রাফ উইজেট (বামে Y-Axis সহ)
// =========================================================================
class TemperatureEnvelopeWithAxis extends StatelessWidget {
  final Map<String, double> tempAvg;
  final Map<String, double> tempMax;
  final Map<String, double> tempMin;

  const TemperatureEnvelopeWithAxis({
    super.key,
    required this.tempAvg,
    required this.tempMax,
    required this.tempMin,
  });

  @override
  Widget build(BuildContext context) {
    if (tempAvg.isEmpty) return const SizedBox();

    final double minVal = (tempMin.values.reduce(math.min) - 2).clamp(
      -10.0,
      50.0,
    );
    final double maxVal = (tempMax.values.reduce(math.max) + 2).clamp(
      10.0,
      60.0,
    );
    final double midVal = (maxVal + minVal) / 2.0;

    return Row(
      children: [
        // Y-Axis লেবেল কলাম
        SizedBox(
          width: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${maxVal.toStringAsFixed(0)}°',
                style: const TextStyle(color: Colors.white38, fontSize: 8.5),
              ),
              Text(
                '${midVal.toStringAsFixed(0)}°',
                style: const TextStyle(color: Colors.white38, fontSize: 8.5),
              ),
              Text(
                '${minVal.toStringAsFixed(0)}°',
                style: const TextStyle(color: Colors.white38, fontSize: 8.5),
              ),
              const SizedBox(height: 12), // এক্স-অ্যাক্সিসের ফাঁকা রাখার জন্য
            ],
          ),
        ),
        const SizedBox(width: 6),
        // গ্রাফ ও এক্স-অ্যাক্সিস
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: TemperatureEnvelopePainter(
                    tempAvg: tempAvg,
                    tempMax: tempMax,
                    tempMin: tempMin,
                    minVal: minVal,
                    maxVal: maxVal,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tempAvg.keys.map((m) {
                  return Text(
                    m.substring(0, 1),
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TemperatureEnvelopePainter extends CustomPainter {
  final Map<String, double> tempAvg;
  final Map<String, double> tempMax;
  final Map<String, double> tempMin;
  final double minVal;
  final double maxVal;

  TemperatureEnvelopePainter({
    required this.tempAvg,
    required this.tempMax,
    required this.tempMin,
    required this.minVal,
    required this.maxVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tempAvg.isEmpty) return;

    final double range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    // অনুভূমিক গ্রিড লাইন
    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), gridPaint);
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      gridPaint,
    );

    final double dx = size.width / (tempAvg.length - 1);

    final Path bandPath = Path();
    final Path avgLinePath = Path();

    final List<Offset> maxPoints = [];
    final List<Offset> minPoints = [];
    final List<Offset> avgPoints = [];

    int i = 0;
    for (var key in tempAvg.keys) {
      final double x = i * dx;
      final double yMax =
          size.height - ((tempMax[key]! - minVal) / range) * size.height;
      final double yMin =
          size.height - ((tempMin[key]! - minVal) / range) * size.height;
      final double yAvg =
          size.height - ((tempAvg[key]! - minVal) / range) * size.height;

      maxPoints.add(Offset(x, yMax));
      minPoints.add(Offset(x, yMin));
      avgPoints.add(Offset(x, yAvg));
      i++;
    }

    // ১. শেডেড ব্যান্ড
    bandPath.moveTo(maxPoints.first.dx, maxPoints.first.dy);
    for (var pt in maxPoints) {
      bandPath.lineTo(pt.dx, pt.dy);
    }
    for (var pt in minPoints.reversed) {
      bandPath.lineTo(pt.dx, pt.dy);
    }
    bandPath.close();

    final Paint bandPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bandPath, bandPaint);

    // ২. গড় লাইন
    avgLinePath.moveTo(avgPoints.first.dx, avgPoints.first.dy);
    for (var pt in avgPoints) {
      avgLinePath.lineTo(pt.dx, pt.dy);
    }

    final Paint avgPaint = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(avgLinePath, avgPaint);

    // ডট
    final Paint dotPaint = Paint()..color = Colors.white;
    for (var pt in avgPoints) {
      canvas.drawCircle(pt, 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =========================================================================
// 📊 ২. PSH বার-চার্ট উইজেট (বামে Y-Axis ও গড়ের ড্যাশড লাইন সহ)
// =========================================================================
class SolarPshChartWithAxis extends StatelessWidget {
  final Map<String, double> monthlyPsh;
  final double annualAvgPsh;

  const SolarPshChartWithAxis({
    super.key,
    required this.monthlyPsh,
    required this.annualAvgPsh,
  });

  @override
  Widget build(BuildContext context) {
    const double yMax = 7.0; // PSH স্কেল সর্বোচ্চ ৭.০

    return Row(
      children: [
        // Y-Axis লেবেল কলাম
        const SizedBox(
          width: 24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('6.0', style: TextStyle(color: Colors.white38, fontSize: 8)),
              Text('4.0', style: TextStyle(color: Colors.white38, fontSize: 8)),
              Text('2.0', style: TextStyle(color: Colors.white38, fontSize: 8)),
              Text('0.0', style: TextStyle(color: Colors.white38, fontSize: 8)),
              SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // বার গ্রাফ এরিয়া
        Expanded(
          child: Stack(
            children: [
              // গ্রিড ও গড়ের ড্যাশড লাইন পেইন্টার
              Positioned.fill(
                child: CustomPaint(
                  painter: PshGridAndAvgPainter(
                    annualAvgPsh: annualAvgPsh,
                    yMax: yMax,
                  ),
                ),
              ),
              // বার ও মাস
              Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: monthlyPsh.entries.map((entry) {
                        final double barRatio = (entry.value / yMax).clamp(
                          0.05,
                          1.0,
                        );
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  entry.value.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Container(
                                      height: 70 * barRatio,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.cyanAccent,
                                            Colors.blueAccent,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    );
                                  },
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
                    children: monthlyPsh.keys.map((m) {
                      return Expanded(
                        child: Text(
                          m.substring(0, 1),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 9.5,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PshGridAndAvgPainter extends CustomPainter {
  final double annualAvgPsh;
  final double yMax;

  PshGridAndAvgPainter({required this.annualAvgPsh, required this.yMax});

  @override
  void paint(Canvas canvas, Size size) {
    final double chartHeight =
        size.height - 18; // নিচের টেক্সট মার্জিন বাদ দিয়ে

    // অনুভূমিক ব্যাকগ্রাউন্ড গ্রিড লাইন
    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double v = 2.0; v <= 6.0; v += 2.0) {
      final double y = chartHeight - (v / yMax) * chartHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 💡 বাৎসরিক গড় PSH-এর ড্যাশড অনুভূমিক লাইন
    final double avgY = chartHeight - (annualAvgPsh / yMax) * chartHeight;
    final Paint avgLinePaint = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.7)
      ..strokeWidth = 1.2;

    const double dashWidth = 4.0;
    const double dashSpace = 3.0;
    double startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, avgY),
        Offset(startX + dashWidth, avgY),
        avgLinePaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
