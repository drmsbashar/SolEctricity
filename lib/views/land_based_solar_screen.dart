import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../constants/app_colors.dart';
import '../services/location_search_service.dart';
import '../services/solar_calculation_service.dart';
import '../services/solar_radiation_service.dart';

enum DrawingMode { boundary, obstacle }

class _PlannerItem {
  final String key;
  String nameBn;
  String nameEn;
  double watt;
  final IconData icon;
  bool isAc;
  int quantity;
  double hours;

  _PlannerItem({
    required this.key,
    required this.nameBn,
    required this.nameEn,
    required this.watt,
    required this.icon,
    this.isAc = true,
    this.quantity = 0,
    this.hours = 0.0,
  });

  double get rawDailyWh => watt * quantity * hours;

  double get effectiveDailyWh {
    final double raw = rawDailyWh;
    return isAc ? (raw / 0.88) : raw;
  }
}

class LandBasedSolarScreen extends StatefulWidget {
  final bool isBangla;

  const LandBasedSolarScreen({super.key, this.isBangla = true});

  @override
  State<LandBasedSolarScreen> createState() => _LandBasedSolarScreenState();
}

class _LandBasedSolarScreenState extends State<LandBasedSolarScreen> {
  late bool _isBangla;
  final MapController _mapController = MapController();

  final TextEditingController _searchController = TextEditingController();
  List<PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchBarVisible = false;

  bool _isInteractingWithControls = false;
  bool _isModalOpen = false;

  DrawingMode _currentMode = DrawingMode.boundary;

  // 🗺️ লেয়ার এবং লাইভ লোকেশন স্টেট
  bool _isSatellite = true;
  bool _isLocatingUser = false;

  final List<ll.LatLng> _boundaryPoints = [];
  final List<List<ll.LatLng>> _obstacles = [];
  List<ll.LatLng> _currentObstaclePoints = [];

  double _totalAreaSqM = 0.0;
  double _obstacleAreaSqM = 0.0;

  static const ll.LatLng _initialPosition = ll.LatLng(23.8103, 90.4125);

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

  late List<_PlannerItem> _plannerAppliances;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _initPlannerAppliances();

    // স্ক্রিন খোলার পর স্বয়ংক্রিয়ভাবে মোবাইলের বর্তমান লোকেশনে যাওয়া
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToCurrentLocation(silent: true);
    });
  }

  Future<void> _goToCurrentLocation({bool silent = false}) async {
    setState(() => _isLocatingUser = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isBangla
                    ? 'ফোনের লোকেশন (GPS) চালু করুন।'
                    : 'Please turn on device location (GPS).',
              ),
            ),
          );
        }
        setState(() => _isLocatingUser = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLocatingUser = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLocatingUser = false);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      final target = ll.LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() => _isLocatingUser = false);
        _mapController.move(target, 18.5);
      }
    } catch (_) {
      if (mounted) setState(() => _isLocatingUser = false);
    }
  }

  void _initPlannerAppliances() {
    _plannerAppliances = [
      _PlannerItem(
        key: 'light',
        nameBn: 'লাইট',
        nameEn: 'Light',
        watt: 15,
        icon: Icons.lightbulb_outline_rounded,
        isAc: true,
        quantity: 6,
        hours: 6.0,
      ),
      _PlannerItem(
        key: 'fan',
        nameBn: 'ফ্যান',
        nameEn: 'Fan',
        watt: 65,
        icon: Icons.mode_fan_off_outlined,
        isAc: true,
        quantity: 4,
        hours: 8.0,
      ),
      _PlannerItem(
        key: 'tv',
        nameBn: 'টেলিভিশন',
        nameEn: 'Television',
        watt: 65,
        icon: Icons.tv_rounded,
        isAc: true,
        quantity: 1,
        hours: 4.0,
      ),
      _PlannerItem(
        key: 'computer',
        nameBn: 'কম্পিউটার',
        nameEn: 'Computer',
        watt: 150,
        icon: Icons.computer_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      _PlannerItem(
        key: 'laptop',
        nameBn: 'ল্যাপটপ',
        nameEn: 'Laptop',
        watt: 65,
        icon: Icons.laptop_chromebook_rounded,
        isAc: true,
        quantity: 1,
        hours: 6.0,
      ),
      _PlannerItem(
        key: 'printer',
        nameBn: 'প্রিন্টার',
        nameEn: 'Printer',
        watt: 300,
        icon: Icons.print_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      _PlannerItem(
        key: 'air_cooler',
        nameBn: 'এয়ারকুলার',
        nameEn: 'Air Cooler',
        watt: 120,
        icon: Icons.ac_unit_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      _PlannerItem(
        key: 'refrigerator',
        nameBn: 'ফ্রিজ',
        nameEn: 'Refrigerator',
        watt: 120,
        icon: Icons.kitchen_rounded,
        isAc: true,
        quantity: 1,
        hours: 12.0,
      ),
      _PlannerItem(
        key: 'cooker',
        nameBn: 'কুকার',
        nameEn: 'Cooker',
        watt: 800,
        icon: Icons.soup_kitchen_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      _PlannerItem(
        key: 'oven',
        nameBn: 'ওভেন',
        nameEn: 'Oven',
        watt: 1200,
        icon: Icons.microwave_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      _PlannerItem(
        key: 'blender',
        nameBn: 'ব্লেন্ডার',
        nameEn: 'Blender',
        watt: 400,
        icon: Icons.blender_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
      _PlannerItem(
        key: 'other',
        nameBn: 'অন্যান্য',
        nameEn: 'Other',
        watt: 100,
        icon: Icons.devices_other_rounded,
        isAc: true,
        quantity: 0,
        hours: 0.0,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _calculatePolygonArea(List<ll.LatLng> points) {
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

  ll.LatLng _calculateCentroid(List<ll.LatLng> points) {
    if (points.isEmpty) return _initialPosition;
    double latSum = 0.0;
    double lngSum = 0.0;
    for (var p in points) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return ll.LatLng(latSum / points.length, lngSum / points.length);
  }

  // বাউন্ডারি পলিগনের উত্তর-দক্ষিণ এবং পূর্ব-পশ্চিম বিস্তার (মিটারে)
  Map<String, double> _calculateBoundingBoxSpans(List<ll.LatLng> points) {
    if (points.isEmpty) return {'ns': 0.0, 'ew': 0.0};

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final double nsSpanM = (maxLat - minLat) * 111320.0;
    final double avgLatRad = ((minLat + maxLat) / 2.0) * (math.pi / 180.0);
    final double ewSpanM = (maxLng - minLng) * 111320.0 * math.cos(avgLatRad);

    return {'ns': nsSpanM, 'ew': ewSpanM};
  }

  void _onMapTapped(TapPosition tapPosition, ll.LatLng position) {
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

    final target = ll.LatLng(place.latitude, place.longitude);
    _mapController.move(target, 18.5);
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

  void _editApplianceWatt(
    BuildContext context,
    _PlannerItem item,
    StateSetter setSheetState,
    bool isDark,
  ) {
    final wattController = TextEditingController(
      text: item.watt.toInt().toString(),
    );
    final nameController = TextEditingController(
      text: _isBangla ? item.nameBn : item.nameEn,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _isBangla ? '${item.nameBn} সম্পাদনা' : 'Edit ${item.nameEn}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.key == 'other') ...[
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: _isBangla ? 'উপকরণের নাম' : 'Appliance Name',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: wattController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                labelText: _isBangla
                    ? 'রেটেড ওয়াট (Watt)'
                    : 'Rated Wattage (W)',
                suffixText: 'W',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isBangla ? 'বাতিল' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.accentCyan
                  : AppColors.primaryGreen,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () {
              final newWatt = double.tryParse(wattController.text);
              if (newWatt != null && newWatt > 0) {
                setSheetState(() {
                  item.watt = newWatt;
                  if (item.key == 'other' &&
                      nameController.text.trim().isNotEmpty) {
                    item.nameBn = nameController.text.trim();
                    item.nameEn = nameController.text.trim();
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: Text(_isBangla ? 'সংরক্ষণ' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSolarEstimationSheet(
    double netUsableSqM,
    bool isDark,
  ) async {
    final centroid = _calculateCentroid(_boundaryPoints);
    final spans = _calculateBoundingBoxSpans(_boundaryPoints);

    // 🌟 ছাদ ও বাউন্ডারির আকার অনুযায়ী স্বয়ংক্রিয়ভাবে সর্বোত্তম প্যানেল ওয়াট নির্ধারণ
    final optimalWatt = SolarGeometryEngine.findOptimalModuleWatt(
      northSouthSpanM: spans['ns'] ?? 0.0,
      eastWestSpanM: spans['ew'] ?? 0.0,
      netUsableAreaSqM: netUsableSqM,
      latitude: centroid.latitude,
    );

    setState(() {
      _selectedModuleWatt = optimalWatt;
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
            final layoutResult = SolarGeometryEngine.calculateDiscreteLayout(
              northSouthSpanM: spans['ns'] ?? 0.0,
              eastWestSpanM: spans['ew'] ?? 0.0,
              netUsableAreaSqM: netUsableSqM,
              latitude: centroid.latitude,
              moduleWatt: _selectedModuleWatt,
            );

            final int totalModules = layoutResult['totalPanels'] as int;
            final double systemCapacityKwp =
                layoutResult['actualKwp'] as double;
            final int rows = layoutResult['rows'] as int;
            final int cols = layoutResult['cols'] as int;
            final double rowPitch = layoutResult['pitchM'] as double;
            final double optimalTilt = layoutResult['tiltDeg'] as double;

            final double tempDerate =
                SolarCalculationService.calculateTempDerateFactor(_ambientTemp);
            final double psh =
                _nasaPeakSunHours ?? SolarRadiationService.defaultPsh;
            final double effectivePR = 0.80 * tempDerate;
            final double dailyGenerationKwh =
                systemCapacityKwp * psh * effectivePR;
            final double dailyGenerationWh = dailyGenerationKwh * 1000.0;
            final double monthlyGenerationKwh = dailyGenerationKwh * 30;

            final double totalPlannedEffectiveWh = _plannerAppliances.fold(
              0.0,
              (sum, item) => sum + item.effectiveDailyWh,
            );
            final double remainingWh =
                dailyGenerationWh - totalPlannedEffectiveWh;
            final double usageRatio = dailyGenerationWh > 0
                ? (totalPlannedEffectiveWh / dailyGenerationWh).clamp(0.0, 1.5)
                : 0.0;
            final bool isOverloaded =
                totalPlannedEffectiveWh > dailyGenerationWh;
            final Color plannerStatusColor = isOverloaded
                ? Colors.redAccent
                : (usageRatio > 0.85
                      ? Colors.orangeAccent
                      : AppColors.energyGreen);

            return DefaultTabController(
              length: 4,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.72,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.5 : 0.15,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
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
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
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
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppColors.accentCyan
                                        : AppColors.energyGreen)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  (isDark
                                          ? AppColors.accentCyan
                                          : AppColors.energyGreen)
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.satellite_alt_rounded,
                                color: isDark
                                    ? AppColors.accentCyan
                                    : AppColors.energyGreen,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isBangla
                                    ? 'নাসা ক্লাইমেট ডাটা'
                                    : 'NASA Climate Data',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.accentCyan
                                      : AppColors.energyGreen,
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
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: isDark
                          ? AppColors.accentCyan
                          : AppColors.energyGreen,
                      indicatorWeight: 2.5,
                      labelColor: isDark
                          ? AppColors.accentCyan
                          : AppColors.energyGreen,
                      unselectedLabelColor: isDark
                          ? Colors.white54
                          : AppColors.lightTextSecondary,
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
                          icon: const Icon(
                            Icons.electric_bolt_rounded,
                            size: 18,
                          ),
                          text: _isBangla ? 'ব্যবহার' : 'Usage Planner',
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
                                    color:
                                        (isDark
                                                ? AppColors.accentCyan
                                                : AppColors.energyGreen)
                                            .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.explore_outlined,
                                        size: 14,
                                        color: isDark
                                            ? AppColors.accentCyan
                                            : AppColors.energyGreen,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _isBangla
                                              ? 'লেআউট: ${rows}টি সারি × ${cols}টি কলাম | সারি দূরত্ব: ${rowPitch.toStringAsFixed(2)} মি'
                                              : 'Layout: ${rows} Rows × ${cols} Cols | Row Pitch: ${rowPitch.toStringAsFixed(2)} m',
                                          style: TextStyle(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
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
                                    color: isDark
                                        ? AppColors.darkInputBg
                                        : AppColors.lightInputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
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
                                              style: TextStyle(
                                                color: isDark
                                                    ? AppColors
                                                          .darkTextSecondary
                                                    : AppColors
                                                          .lightTextSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                            DropdownButton<double>(
                                              value: _selectedModuleEfficiency,
                                              isDense: true,
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
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
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
                                              style: TextStyle(
                                                color: isDark
                                                    ? AppColors
                                                          .darkTextSecondary
                                                    : AppColors
                                                          .lightTextSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                            DropdownButton<int>(
                                              value: _selectedModuleWatt,
                                              isDense: true,
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
                                      subtitle: _isBangla
                                          ? 'মোট বিন্যাস: ${rows}×${cols} গ্রিড'
                                          : 'Layout: ${rows}×${cols} Grid',
                                      icon: Icons.flash_on_rounded,
                                      color: isDark
                                          ? AppColors.accentCyan
                                          : const Color(0xFF0284C7),
                                      isDark: isDark,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatCard(
                                      title: _isBangla
                                          ? 'প্রয়োজনীয় প্যানেল'
                                          : 'Total Panels',
                                      value: _isBangla
                                          ? '$totalModules টি'
                                          : '$totalModules pcs',
                                      subtitle:
                                          '$_selectedModuleWatt Watt Modules',
                                      icon: Icons.grid_view_rounded,
                                      color: AppColors.solarGold,
                                      isDark: isDark,
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
                                      color: AppColors.energyGreen,
                                      isDark: isDark,
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
                                      color: isDark
                                          ? Colors.tealAccent
                                          : const Color(0xFF0D9488),
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkInputBg
                                        : AppColors.lightInputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isOverloaded
                                          ? Colors.redAccent.withValues(
                                              alpha: 0.7,
                                            )
                                          : (isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _isBangla
                                                ? 'কার্যকর চাহিদা: ${totalPlannedEffectiveWh.toStringAsFixed(0)} Wh'
                                                : 'Planned: ${totalPlannedEffectiveWh.toStringAsFixed(0)} Wh',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: plannerStatusColor,
                                            ),
                                          ),
                                          Text(
                                            _isBangla
                                                ? 'মোট উৎপাদন: ${dailyGenerationWh.toStringAsFixed(0)} Wh'
                                                : 'Available: ${dailyGenerationWh.toStringAsFixed(0)} Wh',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white70
                                                  : AppColors
                                                        .lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: usageRatio > 1.0
                                              ? 1.0
                                              : usageRatio,
                                          minHeight: 10,
                                          backgroundColor: isDark
                                              ? Colors.white12
                                              : Colors.black12,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                plannerStatusColor,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            isOverloaded
                                                ? (_isBangla
                                                      ? '⚠️ ঘাটতি: +${(-remainingWh).toStringAsFixed(0)} Wh'
                                                      : '⚠️ Deficit: +${(-remainingWh).toStringAsFixed(0)} Wh')
                                                : (_isBangla
                                                      ? 'উদ্বৃত্ত শক্তি: ${remainingWh.toStringAsFixed(0)} Wh'
                                                      : 'Surplus: ${remainingWh.toStringAsFixed(0)} Wh'),
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: plannerStatusColor,
                                            ),
                                          ),
                                          Text(
                                            '${(usageRatio * 100).toStringAsFixed(0)}% ${_isBangla ? "ব্যবহার" : "Used"}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _isBangla
                                      ? 'বক্সে ক্লিক করে ওয়াট নির্ধারণ করুন এবং AC/DC সিলেক্ট করুন:'
                                      : 'Tap box to edit Watt. Select AC/DC type:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _plannerAppliances.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final item = _plannerAppliances[index];
                                    final bool isActive =
                                        item.quantity > 0 && item.hours > 0;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? (isDark
                                                  ? const Color(0xFF0F172A)
                                                  : const Color(0xFFF8FAFC))
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.02,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.02,
                                                    )),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isActive
                                              ? (isDark
                                                    ? AppColors.accentCyan
                                                          .withValues(
                                                            alpha: 0.35,
                                                          )
                                                    : const Color(0xFF93C5FD))
                                              : (isDark
                                                    ? Colors.white10
                                                    : Colors.black12),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                item.icon,
                                                size: 20,
                                                color: isActive
                                                    ? (isDark
                                                          ? AppColors.accentCyan
                                                          : AppColors
                                                                .primaryGreen)
                                                    : (isDark
                                                          ? Colors.white38
                                                          : Colors.grey),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _isBangla
                                                          ? item.nameBn
                                                          : item.nameEn,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isDark
                                                            ? Colors.white
                                                            : AppColors
                                                                  .lightTextPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 1),
                                                    Text(
                                                      _isBangla
                                                          ? 'মোট: ${item.effectiveDailyWh.toStringAsFixed(0)} Wh/দিন'
                                                          : 'Total: ${item.effectiveDailyWh.toStringAsFixed(0)} Wh/day',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isActive
                                                            ? (isDark
                                                                  ? AppColors
                                                                        .solarGold
                                                                  : const Color(
                                                                      0xFFB45309,
                                                                    ))
                                                            : (isDark
                                                                  ? Colors
                                                                        .white38
                                                                  : Colors
                                                                        .grey
                                                                        .shade600),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () => _editApplianceWatt(
                                                  context,
                                                  item,
                                                  setSheetState,
                                                  isDark,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF0B132B,
                                                          )
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? AppColors.accentCyan
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                )
                                                          : const Color(
                                                              0xFF0284C7,
                                                            ),
                                                      width: 1.1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '${item.watt.toInt()} W',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily:
                                                              'monospace',
                                                          color: isDark
                                                              ? AppColors
                                                                    .accentCyan
                                                              : const Color(
                                                                  0xFF0284C7,
                                                                ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Icon(
                                                        Icons.edit,
                                                        size: 11,
                                                        color: isDark
                                                            ? AppColors
                                                                  .accentCyan
                                                            : const Color(
                                                                0xFF0284C7,
                                                              ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.black26
                                                      : Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                  border: Border.all(
                                                    color: isDark
                                                        ? Colors.white12
                                                        : Colors.black12,
                                                  ),
                                                ),
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        if (!item.isAc) {
                                                          setSheetState(
                                                            () => item.isAc =
                                                                true,
                                                          );
                                                        }
                                                      },
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            5,
                                                          ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2.5,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: item.isAc
                                                              ? const Color(
                                                                  0xFFD97706,
                                                                )
                                                              : Colors
                                                                    .transparent,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                5,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'AC',
                                                          style: TextStyle(
                                                            fontSize: 9.5,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: item.isAc
                                                                ? Colors.white
                                                                : (isDark
                                                                      ? Colors
                                                                            .white54
                                                                      : Colors
                                                                            .grey
                                                                            .shade600),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        if (item.isAc) {
                                                          setSheetState(
                                                            () => item.isAc =
                                                                false,
                                                          );
                                                        }
                                                      },
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            5,
                                                          ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2.5,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: !item.isAc
                                                              ? const Color(
                                                                  0xFF0284C7,
                                                                )
                                                              : Colors
                                                                    .transparent,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                5,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'DC',
                                                          style: TextStyle(
                                                            fontSize: 9.5,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: !item.isAc
                                                                ? Colors.white
                                                                : (isDark
                                                                      ? Colors
                                                                            .white54
                                                                      : Colors
                                                                            .grey
                                                                            .shade600),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Row(
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      if (item.quantity > 0) {
                                                        setSheetState(
                                                          () => item.quantity--,
                                                        );
                                                      }
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors.white12
                                                            : Colors.black12,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.remove,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: Text(
                                                      '${item.quantity}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      setSheetState(
                                                        () => item.quantity++,
                                                      );
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors.white12
                                                            : Colors.black12,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.add,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (item.quantity > 0) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.black26
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.schedule_rounded,
                                                    size: 14,
                                                    color: isDark
                                                        ? AppColors.accentCyan
                                                        : AppColors
                                                              .primaryGreen,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    _isBangla
                                                        ? 'দৈনিক চালানোর সময়: ${item.hours.toStringAsFixed(1)} ঘণ্টা'
                                                        : 'Daily Runtime: ${item.hours.toStringAsFixed(1)} hrs',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF94A3B8,
                                                            )
                                                          : AppColors
                                                                .lightTextSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: SliderTheme(
                                                      data: SliderTheme.of(context).copyWith(
                                                        trackHeight: 3,
                                                        thumbShape:
                                                            const RoundSliderThumbShape(
                                                              enabledThumbRadius:
                                                                  6,
                                                            ),
                                                        activeTrackColor: isDark
                                                            ? AppColors
                                                                  .accentCyan
                                                            : AppColors
                                                                  .primaryGreen,
                                                        thumbColor: isDark
                                                            ? AppColors
                                                                  .accentCyan
                                                            : AppColors
                                                                  .primaryGreen,
                                                      ),
                                                      child: Slider(
                                                        value: item.hours,
                                                        min: 0.0,
                                                        max: 24.0,
                                                        divisions: 48,
                                                        onChanged: (val) {
                                                          setSheetState(
                                                            () => item.hours =
                                                                val,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_monthlyTempAvg.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkInputBg
                                          : AppColors.lightInputBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                      ),
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
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? AppColors
                                                              .darkTextPrimary
                                                        : AppColors
                                                              .lightTextPrimary,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.alertRed
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: AppColors.alertRed
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Text(
                                                _isBangla
                                                    ? 'তাপমাত্রা লস: ${((1.0 - tempDerate) * 100).toStringAsFixed(1)}% | PR: ${(effectivePR * 100).toStringAsFixed(0)}%'
                                                    : 'Thermal Loss: ${((1.0 - tempDerate) * 100).toStringAsFixed(1)}% | PR: ${(effectivePR * 100).toStringAsFixed(0)}%',
                                                style: const TextStyle(
                                                  color: AppColors.alertRed,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          height: 105,
                                          child: TemperatureEnvelopeWithAxis(
                                            tempAvg: _monthlyTempAvg,
                                            tempMax: _monthlyTempMax,
                                            tempMin: _monthlyTempMin,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                if (_monthlyPsh.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkInputBg
                                          : AppColors.lightInputBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                      ),
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
                                                  color: AppColors.solarGold,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _isBangla
                                                      ? 'সৌর বিকিরণ (PSH)'
                                                      : 'Solar Radiation (PSH)',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? AppColors
                                                              .darkTextPrimary
                                                        : AppColors
                                                              .lightTextPrimary,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.solarGold
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: AppColors.solarGold
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Text(
                                                _isBangla
                                                    ? 'বাৎসরিক গড়: ${psh.toStringAsFixed(2)} hrs'
                                                    : 'Annual Avg: ${psh.toStringAsFixed(2)} hrs',
                                                style: const TextStyle(
                                                  color: AppColors.solarGold,
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
                                            isDark: isDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
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
                                      color: AppColors.solarGold,
                                      isDark: isDark,
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
                                      color: isDark
                                          ? AppColors.accentCyan
                                          : const Color(0xFF0284C7),
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _isCoastal
                                        ? AppColors.alertRed.withValues(
                                            alpha: 0.1,
                                          )
                                        : (isDark
                                              ? AppColors.darkInputBg
                                              : AppColors.lightInputBg),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isCoastal
                                          ? AppColors.alertRed.withValues(
                                              alpha: 0.35,
                                            )
                                          : (isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder),
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
                                            ? AppColors.alertRed
                                            : (isDark
                                                  ? AppColors.accentCyan
                                                  : AppColors.energyGreen),
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
                                                    ? AppColors.alertRed
                                                    : (isDark
                                                          ? AppColors
                                                                .darkTextPrimary
                                                          : AppColors
                                                                .lightTextPrimary),
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
                                              style: TextStyle(
                                                color: isDark
                                                    ? AppColors
                                                          .darkTextSecondary
                                                    : AppColors
                                                          .lightTextSecondary,
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double netUsableSqM = math.max(0.0, _totalAreaSqM - _obstacleAreaSqM);
    final double netUsableSqFt = netUsableSqM * 10.7639;

    final List<Polygon> polygons = [];

    if (_boundaryPoints.length >= 3) {
      polygons.add(
        Polygon(
          points: _boundaryPoints,
          borderColor: AppColors.solarGold,
          borderStrokeWidth: 2,
          color: isDark
              ? AppColors.accentCyan.withValues(alpha: 0.22)
              : AppColors.energyGreen.withValues(alpha: 0.25),
        ),
      );
    }

    for (int i = 0; i < _obstacles.length; i++) {
      polygons.add(
        Polygon(
          points: _obstacles[i],
          borderColor: AppColors.alertRed,
          borderStrokeWidth: 2,
          color: AppColors.alertRed.withValues(alpha: 0.38),
        ),
      );
    }

    if (_currentObstaclePoints.length >= 3) {
      polygons.add(
        Polygon(
          points: _currentObstaclePoints,
          borderColor: Colors.orangeAccent,
          borderStrokeWidth: 2,
          color: AppColors.alertRed.withValues(alpha: 0.38),
        ),
      );
    }

    final List<Polyline> polylines = [];
    if (_boundaryPoints.length >= 2) {
      polylines.add(
        Polyline(
          points: _boundaryPoints,
          color: AppColors.solarGold,
          strokeWidth: 3,
        ),
      );
    }
    if (_currentObstaclePoints.length >= 2) {
      polylines.add(
        Polyline(
          points: _currentObstaclePoints,
          color: AppColors.alertRed,
          strokeWidth: 3,
        ),
      );
    }

    final List<Marker> markers = [];
    void addDots(List<ll.LatLng> pts) {
      for (var p in pts) {
        markers.add(
          Marker(
            point: p,
            width: 12,
            height: 12,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 3)],
              ),
            ),
          ),
        );
      }
    }

    addDots(_boundaryPoints);
    for (var obs in _obstacles) {
      addDots(obs);
    }
    addDots(_currentObstaclePoints);

    final bool hasAnyPoints =
        _boundaryPoints.isNotEmpty ||
        _obstacles.isNotEmpty ||
        _currentObstaclePoints.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isBangla ? 'ছাদ বা জমি পরিমাপ' : 'Rooftop or Land Sizing'),
        actions: [
          if (hasAnyPoints) ...[
            IconButton(
              tooltip: _isBangla ? 'আগের পয়েন্ট বাতিল' : 'Undo Point',
              icon: const Icon(Icons.undo_rounded, color: AppColors.solarGold),
              onPressed: _undoLastPoint,
            ),
            IconButton(
              tooltip: _isBangla ? 'সব মুছুন' : 'Clear All',
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.alertRed,
              ),
              onPressed: _clearAll,
            ),
          ],
          IconButton(
            onPressed: () => setState(() => _isBangla = !_isBangla),
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
        ],
      ),
      body: Stack(
        children: [
          // 🌍 সম্পূর্ণ সাবস্ক্রিপশন-ফ্রি স্যাটেলাইট ও ওপেনস্ট্রিটম্যাপ ভিউ
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 17.5,
                maxZoom: 20.0,
                minZoom: 3.0,
                onTap: _onMapTapped,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _isSatellite
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'app.solectricity.shs',
                  maxNativeZoom: 19,
                ),
                PolygonLayer(polygons: polygons),
                PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
              ],
            ),
          ),

          // 🎛️ ফ্লোটিং টুলস (স্যাটেলাইট/ম্যাপ টগল ও বর্তমান জিপিএস লোকেশন বাটন)
          Positioned(
            right: 14,
            top: 70,
            child: SafeArea(
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'map_view_toggle',
                    backgroundColor: isDark
                        ? AppColors.darkCardBg
                        : Colors.white,
                    foregroundColor: _isSatellite
                        ? AppColors.solarGold
                        : AppColors.energyGreen,
                    tooltip: _isSatellite
                        ? (_isBangla
                              ? 'ম্যাপ ভিউ দেখুন'
                              : 'Switch to Street Map')
                        : (_isBangla
                              ? 'স্যাটেলাইট ভিউ দেখুন'
                              : 'Switch to Satellite'),
                    onPressed: () =>
                        setState(() => _isSatellite = !_isSatellite),
                    child: Icon(
                      _isSatellite
                          ? Icons.map_rounded
                          : Icons.satellite_alt_rounded,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'gps_location_btn',
                    backgroundColor: isDark
                        ? AppColors.darkCardBg
                        : Colors.white,
                    foregroundColor: AppColors.energyGreen,
                    tooltip: _isBangla ? 'আমার অবস্থান' : 'My Location',
                    onPressed: _isLocatingUser
                        ? null
                        : () => _goToCurrentLocation(silent: false),
                    child: _isLocatingUser
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.energyGreen,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 14,
            right: 70,
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
                            color: isDark
                                ? AppColors.darkCardBg
                                : AppColors.lightCardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
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
                                activeColor: isDark
                                    ? AppColors.accentCyan
                                    : AppColors.energyGreen,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 4),
                              _buildModeButton(
                                mode: DrawingMode.obstacle,
                                label: _isBangla ? 'বাধা/ছায়া' : 'Obstacle',
                                icon: Icons.block_rounded,
                                activeColor: AppColors.alertRed,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Material(
                          color: _isSearchBarVisible
                              ? AppColors.alertRed
                              : (isDark
                                    ? AppColors.darkCardBg
                                    : AppColors.lightCardBg),
                          borderRadius: BorderRadius.circular(14),
                          elevation: 3,
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
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Icon(
                                _isSearchBarVisible
                                    ? Icons.close_rounded
                                    : Icons.search_rounded,
                                color: _isSearchBarVisible
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white
                                          : AppColors.lightTextPrimary),
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
                          color: isDark
                              ? AppColors.darkCardBg
                              : AppColors.lightCardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontSize: 13.5,
                          ),
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: _isBangla
                                ? 'এলাকা বা ভবনের নাম লিখুন...'
                                : 'Search area or building name...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.lightTextSecondary,
                              fontSize: 12.5,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDark
                                  ? AppColors.accentCyan
                                  : AppColors.energyGreen,
                              size: 20,
                            ),
                            suffixIcon: _isSearching
                                ? Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: isDark
                                            ? AppColors.accentCyan
                                            : AppColors.energyGreen,
                                      ),
                                    ),
                                  )
                                : (_searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            color: isDark
                                                ? Colors.white70
                                                : AppColors.lightTextSecondary,
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
                            color: isDark
                                ? AppColors.darkInputBg
                                : AppColors.lightCardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => Divider(
                              color: isDark ? Colors.white10 : Colors.black12,
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.location_on_outlined,
                                  color: isDark
                                      ? AppColors.accentCyan
                                      : AppColors.energyGreen,
                                  size: 18,
                                ),
                                title: Text(
                                  item.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
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
                            backgroundColor: AppColors.alertRed,
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
                  color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.4 : 0.15,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
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
                                ? AppColors.solarGold.withValues(alpha: 0.15)
                                : AppColors.energyGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.solar_power_rounded,
                            color: (_boundaryPoints.length < 3)
                                ? AppColors.solarGold
                                : AppColors.energyGreen,
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
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
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
                                      ? AppColors.solarGold
                                      : AppColors.energyGreen,
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
                              backgroundColor: isDark
                                  ? AppColors.accentCyan
                                  : AppColors.energyGreen,
                              foregroundColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
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
                                : () => _openSolarEstimationSheet(
                                    netUsableSqM,
                                    isDark,
                                  ),
                            child: _isLoadingNasa
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark
                                          ? const Color(0xFF0F172A)
                                          : Colors.white,
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
                      Divider(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        height: 14,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isBangla
                                ? 'মোট ছাদ: ${(_totalAreaSqM * 10.7639).toStringAsFixed(0)} sq.ft'
                                : 'Total Roof: ${(_totalAreaSqM * 10.7639).toStringAsFixed(0)} sq.ft',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.lightTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            _isBangla
                                ? 'বাধা/ছায়া: -${(_obstacleAreaSqM * 10.7639).toStringAsFixed(0)} sq.ft'
                                : 'Obstacle: -${(_obstacleAreaSqM * 10.7639).toStringAsFixed(0)} sq.ft',
                            style: const TextStyle(
                              color: AppColors.alertRed,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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
    required bool isDark,
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
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                      : (isDark ? Colors.white60 : Colors.black54),
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

class TemperatureEnvelopeWithAxis extends StatelessWidget {
  final Map<String, double> tempAvg;
  final Map<String, double> tempMax;
  final Map<String, double> tempMin;
  final bool isDark;

  const TemperatureEnvelopeWithAxis({
    super.key,
    required this.tempAvg,
    required this.tempMax,
    required this.tempMin,
    required this.isDark,
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
        SizedBox(
          width: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${maxVal.toStringAsFixed(0)}°',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8.5,
                ),
              ),
              Text(
                '${midVal.toStringAsFixed(0)}°',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8.5,
                ),
              ),
              Text(
                '${minVal.toStringAsFixed(0)}°',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8.5,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(width: 6),
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
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tempAvg.keys.map((m) {
                  return Text(
                    m.substring(0, 1),
                    style: TextStyle(
                      color: isDark
                          ? Colors.white38
                          : AppColors.lightTextSecondary,
                      fontSize: 9,
                    ),
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
  final bool isDark;

  TemperatureEnvelopePainter({
    required this.tempAvg,
    required this.tempMax,
    required this.tempMin,
    required this.minVal,
    required this.maxVal,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tempAvg.isEmpty) return;

    final double range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final Paint gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
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

    bandPath.moveTo(maxPoints.first.dx, maxPoints.first.dy);
    for (var pt in maxPoints) {
      bandPath.lineTo(pt.dx, pt.dy);
    }
    for (var pt in minPoints.reversed) {
      bandPath.lineTo(pt.dx, pt.dy);
    }
    bandPath.close();

    final Paint bandPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: isDark ? 0.18 : 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bandPath, bandPaint);

    avgLinePath.moveTo(avgPoints.first.dx, avgPoints.first.dy);
    for (var pt in avgPoints) {
      avgLinePath.lineTo(pt.dx, pt.dy);
    }

    final Paint avgPaint = Paint()
      ..color = AppColors.solarGold
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(avgLinePath, avgPaint);

    final Paint dotPaint = Paint()
      ..color = isDark ? Colors.white : Colors.black87;
    for (var pt in avgPoints) {
      canvas.drawCircle(pt, 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SolarPshChartWithAxis extends StatelessWidget {
  final Map<String, double> monthlyPsh;
  final double annualAvgPsh;
  final bool isDark;

  const SolarPshChartWithAxis({
    super.key,
    required this.monthlyPsh,
    required this.annualAvgPsh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const double yMax = 7.0;

    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '6.0',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8,
                ),
              ),
              Text(
                '4.0',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8,
                ),
              ),
              Text(
                '2.0',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8,
                ),
              ),
              Text(
                '0.0',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: PshGridAndAvgPainter(
                    annualAvgPsh: annualAvgPsh,
                    yMax: yMax,
                    isDark: isDark,
                  ),
                ),
              ),
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
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.accentCyan
                                        : const Color(0xFF0284C7),
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
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: isDark
                                              ? [
                                                  AppColors.accentCyan,
                                                  Colors.blueAccent,
                                                ]
                                              : [
                                                  const Color(0xFF38BDF8),
                                                  const Color(0xFF0284C7),
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
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : AppColors.lightTextSecondary,
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
  final bool isDark;

  PshGridAndAvgPainter({
    required this.annualAvgPsh,
    required this.yMax,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double chartHeight = size.height - 18;

    final Paint gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double v = 2.0; v <= 6.0; v += 2.0) {
      final double y = chartHeight - (v / yMax) * chartHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double avgY = chartHeight - (annualAvgPsh / yMax) * chartHeight;
    final Paint avgLinePaint = Paint()
      ..color = AppColors.solarGold.withValues(alpha: 0.8)
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
