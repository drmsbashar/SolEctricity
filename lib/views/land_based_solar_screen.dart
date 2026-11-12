import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../constants/app_colors.dart';
import '../models/system_sizing_params.dart';
import '../services/land_pdf_export_service.dart';
import '../services/location_search_service.dart';
import '../services/solar_calculation_service.dart';
import '../services/solar_radiation_service.dart';
import 'cost_based_solar_screen.dart'; // BatteryChemistry-এর জন্য
import 'widgets/land_solar_bottom_sheet.dart';
import 'land_solar_result_screen.dart';
import '../widgets/app_bar_title.dart';

enum DrawingMode { boundary, obstacle }

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
  bool _isExportingPdf = false;

  DrawingMode _currentMode = DrawingMode.boundary;

  bool _isSatellite = true;
  bool _isLocatingUser = false;

  final List<ll.LatLng> _boundaryPoints = [];
  final List<List<ll.LatLng>> _obstacles = [];
  List<ll.LatLng> _currentObstaclePoints = [];

  double _totalAreaSqM = 0.0;
  double _obstacleAreaSqM = 0.0;

  static const ll.LatLng _initialPosition = ll.LatLng(23.8103, 90.4125);

  double? _nasaPeakSunHours;
  Map<String, double> _monthlyPsh = {};
  double _ambientTemp = 26.0;
  Map<String, double> _monthlyTempAvg = {};
  Map<String, double> _monthlyTempMax = {};
  Map<String, double> _monthlyTempMin = {};
  double _windSpeed = 3.5;
  bool _isCoastal = false;
  String _locationPlaceName = '';
  bool _isLoadingNasa = false;

  static const double maxRoofAreaSqFtLimit = 5000.0;
  static const double minPanelThresholdSqFt = 4.0;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToCurrentLocation(silent: true);
    });
  }

  void _onToggleLanguageInternal() {
    setState(() => _isBangla = !_isBangla);
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 📐 হাই-প্রিসিশন লোকাল কার্টেসিয়ান প্রজেকশন (Shoelace Formula)
  double _calculatePolygonArea(List<ll.LatLng> points) {
    if (points.length < 3) return 0.0;

    final refLat = points.first.latitude;
    final double latToM = 111132.954;
    final double lonToM = 111412.84 * math.cos(refLat * (math.pi / 180.0));

    final refLon = points.first.longitude;
    final List<math.Point<double>> planarPoints = points.map((p) {
      final double x = (p.longitude - refLon) * lonToM;
      final double y = (p.latitude - refLat) * latToM;
      return math.Point<double>(x, y);
    }).toList();

    double area = 0.0;
    for (int i = 0; i < planarPoints.length; i++) {
      final j = (i + 1) % planarPoints.length;
      area +=
          (planarPoints[i].x * planarPoints[j].y) -
          (planarPoints[j].x * planarPoints[i].y);
    }

    return (area.abs() / 2.0);
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
        if (_boundaryPoints.isNotEmpty) _boundaryPoints.removeLast();
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
      _monthlyTempAvg = {};
      _monthlyTempMax = {};
      _monthlyTempMin = {};
      _windSpeed = 3.5;
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
            if (mounted) setState(() => _isInteractingWithControls = false);
          });
        },
        child: child,
      ),
    );
  }

  Future<void> _fetchNasaClimate(ll.LatLng centroid) async {
    setState(() => _isLoadingNasa = true);
    try {
      final radResult = await SolarRadiationService.fetchPshByCoordinates(
        centroid.latitude,
        centroid.longitude,
      );
      _nasaPeakSunHours = radResult.peakSunHours;
      _monthlyPsh = radResult.monthlyPsh;
      _ambientTemp = radResult.ambientTemp;
      _monthlyTempAvg = radResult.monthlyTempAvg;
      _monthlyTempMax = radResult.monthlyTempMax;
      _monthlyTempMin = radResult.monthlyTempMin;
      _windSpeed = radResult.windSpeed;
      _isCoastal = radResult.isCoastal;
      _locationPlaceName = radResult.placeName;
    } catch (_) {
      _nasaPeakSunHours = SolarRadiationService.defaultPsh;
    } finally {
      if (mounted) setState(() => _isLoadingNasa = false);
    }
  }

  Future<void> _exportDedicatedLandPdf({required double netUsableSqM}) async {
    setState(() => _isExportingPdf = true);
    try {
      final centroid = _calculateCentroid(_boundaryPoints);
      final layoutResult = SolarGeometryEngine.calculateDiscreteLayout(
        northSouthSpanM: math.sqrt(netUsableSqM),
        eastWestSpanM: math.sqrt(netUsableSqM),
        netUsableAreaSqM: netUsableSqM,
        latitude: centroid.latitude,
        moduleWatt: 550,
      );

      final int rows = layoutResult['rows'] as int;
      final int cols = layoutResult['cols'] as int;
      final int totalModules = rows * cols;
      final double systemCapacityKwp = (totalModules * 550) / 1000.0;
      final double optimalTilt = layoutResult['tiltDeg'] as double;

      final double tempDerate =
          SolarCalculationService.calculateTempDerateFactor(_ambientTemp);
      final double psh = _nasaPeakSunHours ?? SolarRadiationService.defaultPsh;
      final double effectivePR = 0.80 * tempDerate;
      final double dailyGenKwh = systemCapacityKwp * psh * effectivePR;
      final double monthlyGenKwh = dailyGenKwh * 30;

      await LandPdfExportService.generateAndSharePdf(
        centroid: centroid,
        placeName: _locationPlaceName,
        totalRoofSqFt: _totalAreaSqM * 10.7639,
        obstacleSqFt: _obstacleAreaSqM * 10.7639,
        netUsableSqFt: netUsableSqM * 10.7639,
        netUsableSqM: netUsableSqM,
        capacityKwp: systemCapacityKwp,
        totalPanels: totalModules,
        rows: rows,
        cols: cols,
        optimalTilt: optimalTilt,
        dailyGenKwh: dailyGenKwh,
        monthlyGenKwh: monthlyGenKwh,
        estimatedBudget: systemCapacityKwp * 1000.0 * 75.0,
        systemType: SolarSystemType.gridTied,
        batteryChemistry: BatteryChemistry.tubular,
        selectedModuleWatt: 550,
        selectedModuleEfficiency: 0.215,
        pricePerWatt: 75.0,
        nasaPsh: psh,
        ambientTemp: _ambientTemp,
        isBangla: _isBangla,
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  void _openSolarEstimationSheet(double netUsableSqM, bool isDark) async {
    final centroid = _calculateCentroid(_boundaryPoints);
    await _fetchNasaClimate(centroid);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LandSolarResultScreen(
          netUsableSqM: netUsableSqM,
          totalRoofSqFt: _totalAreaSqM * 10.7639,
          obstacleSqFt: _obstacleAreaSqM * 10.7639,
          latitude: centroid.latitude,
          longitude: centroid.longitude,
          initialNasaPsh: _nasaPeakSunHours,
          monthlyPsh: _monthlyPsh,
          ambientTemp: _ambientTemp,
          monthlyTempAvg: _monthlyTempAvg,
          monthlyTempMax: _monthlyTempMax,
          monthlyTempMin: _monthlyTempMin,
          windSpeed: _windSpeed,
          isCoastal: _isCoastal,
          locationPlaceName: _locationPlaceName,
          isBangla: _isBangla,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double netUsableSqM = math.max(0.0, _totalAreaSqM - _obstacleAreaSqM);
    final double netUsableSqFt = netUsableSqM * 10.7639;
    final bool isExceedingHomeLimit = netUsableSqFt > maxRoofAreaSqFtLimit;
    final bool isTooSmall =
        netUsableSqFt > 0 && netUsableSqFt < minPanelThresholdSqFt;

    final List<Polygon> polygons = [];
    if (_boundaryPoints.length >= 3) {
      polygons.add(
        Polygon(
          points: _boundaryPoints,
          borderColor: isExceedingHomeLimit
              ? AppColors.alertRed
              : AppColors.solarGold,
          borderStrokeWidth: 2,
          color: isDark
              ? AppColors.accentCyan.withValues(alpha: 0.22)
              : AppColors.energyGreen.withValues(alpha: 0.25),
        ),
      );
    }

    for (var obs in _obstacles) {
      polygons.add(
        Polygon(
          points: obs,
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
          color: isExceedingHomeLimit
              ? AppColors.alertRed
              : AppColors.solarGold,
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
        title: TwoLineAppBarTitle(
          title: _isBangla ? 'ছাদ বা জমি পরিমাপ' : 'Rooftop & Land Sizing',
          subtitle: _isBangla
              ? 'স্যাটেলাইট ভিত্তিক সৌর এলাকা'
              : 'Satellite Solar Mapping',
        ),
        actions: [
          if (_boundaryPoints.length >= 3 && !isTooSmall)
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
                  : () => _exportDedicatedLandPdf(netUsableSqM: netUsableSqM),
            ),
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
            onPressed: _onToggleLanguageInternal,
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
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: Stack(
        children: [
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
                                : 'Search location...',
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
                                : (isExceedingHomeLimit
                                      ? AppColors.alertRed.withValues(
                                          alpha: 0.15,
                                        )
                                      : AppColors.energyGreen.withValues(
                                          alpha: 0.15,
                                        )),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.solar_power_rounded,
                            color: (_boundaryPoints.length < 3)
                                ? AppColors.solarGold
                                : (isExceedingHomeLimit
                                      ? AppColors.alertRed
                                      : AppColors.energyGreen),
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
                                    : 'Net Solar Area',
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
                                          : 'Mark boundary (${_boundaryPoints.length}/3)')
                                    : '${netUsableSqFt.toStringAsFixed(1)} sq.ft (${netUsableSqM.toStringAsFixed(1)} m²)',
                                style: TextStyle(
                                  color: _boundaryPoints.length < 3
                                      ? AppColors.solarGold
                                      : (isExceedingHomeLimit
                                            ? AppColors.alertRed
                                            : AppColors.energyGreen),
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
                              backgroundColor: isTooSmall
                                  ? Colors.grey
                                  : (isDark
                                        ? AppColors.accentCyan
                                        : AppColors.energyGreen),
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
                            onPressed: (_isLoadingNasa || isTooSmall)
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
                    if (isExceedingHomeLimit) ...[
                      const SizedBox(height: 8),
                      Text(
                        _isBangla
                            ? '* সোলার হোম সিস্টেমের জন্য সর্বোচ্চ ৫,০০০ sq.ft (৪৬৫ m²) ক্ষেত্রফল পর্যন্ত গণনা করা যাবে।'
                            : '* Sizing is calculated up to 5,000 sq.ft (465 m²) for residential solar.',
                        style: const TextStyle(
                          color: AppColors.alertRed,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (isTooSmall) ...[
                      const SizedBox(height: 8),
                      Text(
                        _isBangla
                            ? '* স্থানটি খুব ছোট (৫০W প্যানেলের জন্য অন্তত ৪ sq.ft প্রয়োজন)।'
                            : '* Area too small (min 4 sq.ft required for a 50W panel).',
                        style: const TextStyle(
                          color: AppColors.alertRed,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
