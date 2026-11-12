import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../constants/app_colors.dart';
import '../models/system_sizing_params.dart';
import '../services/land_pdf_export_service.dart';
import '../services/solar_calculation_service.dart';
import '../services/solar_radiation_service.dart';
import 'cost_based_solar_screen.dart';
import 'widgets/climate_charts.dart';
import '../widgets/app_bar_title.dart';

class PlannerApplianceItem {
  final String key;
  String nameBn;
  String nameEn;
  double watt;
  final IconData icon;
  bool isAc;
  int quantity;
  double hours;

  PlannerApplianceItem({
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

  // 🌟 এসি লোডের ক্ষেত্রে ইনভার্টার অপচয় ডায়নামিক সমন্বয়
  double getEffectiveDailyWh({double inverterEfficiencyPercent = 90.0}) {
    final double raw = rawDailyWh;
    if (!isAc) return raw;
    final double eff = (inverterEfficiencyPercent > 0)
        ? (inverterEfficiencyPercent / 100.0)
        : 0.90;
    return raw / eff;
  }
}

class LandSolarResultScreen extends StatefulWidget {
  final double netUsableSqM;
  final double totalRoofSqFt;
  final double obstacleSqFt;
  final double latitude;
  final double longitude;
  final double? initialNasaPsh;
  final Map<String, double> monthlyPsh;
  final double ambientTemp;
  final Map<String, double> monthlyTempAvg;
  final Map<String, double> monthlyTempMax;
  final Map<String, double> monthlyTempMin;
  final double windSpeed;
  final bool isCoastal;
  final String locationPlaceName;
  final bool isBangla;

  const LandSolarResultScreen({
    super.key,
    required this.netUsableSqM,
    required this.totalRoofSqFt,
    required this.obstacleSqFt,
    required this.latitude,
    required this.longitude,
    this.initialNasaPsh,
    required this.monthlyPsh,
    required this.ambientTemp,
    required this.monthlyTempAvg,
    required this.monthlyTempMax,
    required this.monthlyTempMin,
    required this.windSpeed,
    required this.isCoastal,
    required this.locationPlaceName,
    required this.isBangla,
  });

  @override
  State<LandSolarResultScreen> createState() => _LandSolarResultScreenState();
}

class _LandSolarResultScreenState extends State<LandSolarResultScreen> {
  late bool _isBangla;
  bool _isExportingPdf = false;

  double _selectedModuleEfficiency = 0.215;
  int _selectedModuleWatt = 550;
  SolarSystemType _selectedSystemType = SolarSystemType.gridTied;
  BatteryChemistry _selectedBatteryChemistry = BatteryChemistry.tubular;
  double _pricePerWatt = 75.0;

  late List<PlannerApplianceItem> _plannerAppliances;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _pricePerWatt = _getDefaultRateForType(
      _selectedSystemType,
      _selectedBatteryChemistry,
    );
    _initPlannerAppliances();
  }

  double _getDefaultRateForType(SolarSystemType type, BatteryChemistry chem) {
    if (_isBangla) {
      switch (type) {
        case SolarSystemType.gridTied:
          return 75.0;
        case SolarSystemType.hybrid:
          switch (chem) {
            case BatteryChemistry.leadAcid:
              return 95.0;
            case BatteryChemistry.tubular:
              return 105.0;
            case BatteryChemistry.lithium:
              return 135.0;
          }
        case SolarSystemType.offGrid:
          switch (chem) {
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
          switch (chem) {
            case BatteryChemistry.leadAcid:
              return 0.80;
            case BatteryChemistry.tubular:
              return 0.90;
            case BatteryChemistry.lithium:
              return 1.15;
          }
        case SolarSystemType.offGrid:
          switch (chem) {
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

  String _formatBudget(double totalAmount) {
    if (_isBangla) {
      if (totalAmount >= 100000) {
        final double lakh = totalAmount / 100000.0;
        return '৳ ${lakh.toStringAsFixed(2)} লাখ';
      } else {
        final double thousand = totalAmount / 1000.0;
        return '৳ ${thousand.toStringAsFixed(1)} হাজার';
      }
    } else {
      if (totalAmount >= 1000) {
        return '\$ ${(totalAmount / 1000).toStringAsFixed(1)}k';
      } else {
        return '\$ ${totalAmount.toStringAsFixed(0)}';
      }
    }
  }

  void _initPlannerAppliances() {
    _plannerAppliances = [
      PlannerApplianceItem(
        key: 'light',
        nameBn: 'LED লাইট',
        nameEn: 'LED Light',
        watt: 15,
        icon: Icons.lightbulb_outline_rounded,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'fan',
        nameBn: 'সিলিং ফ্যান',
        nameEn: 'Ceiling Fan',
        watt: 75,
        icon: Icons.mode_fan_off_outlined,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'tv',
        nameBn: 'টেলিভিশন',
        nameEn: 'Television',
        watt: 65,
        icon: Icons.tv_rounded,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'computer',
        nameBn: 'কম্পিউটার',
        nameEn: 'Computer',
        watt: 150,
        icon: Icons.computer_rounded,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'laptop',
        nameBn: 'ল্যাপটপ',
        nameEn: 'Laptop',
        watt: 65,
        icon: Icons.laptop_chromebook_rounded,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'printer',
        nameBn: 'প্রিন্টার',
        nameEn: 'Printer',
        watt: 300,
        icon: Icons.print_rounded,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'air_cooler',
        nameBn: 'এয়ারকুলার',
        nameEn: 'Air Cooler',
        watt: 120,
        icon: Icons.ac_unit_rounded,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'refrigerator',
        nameBn: 'ফ্রিজ / ডিপ ফ্রিজার',
        nameEn: 'Refrigerator',
        watt: 140,
        icon: Icons.kitchen_rounded,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'cooker',
        nameBn: 'রাইস কুকার',
        nameEn: 'Rice Cooker',
        watt: 700,
        icon: Icons.soup_kitchen_rounded,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'oven',
        nameBn: 'ওভেন',
        nameEn: 'Oven',
        watt: 1200,
        icon: Icons.microwave_rounded,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'blender',
        nameBn: 'ব্লেন্ডার / মিক্সার',
        nameEn: 'Blender',
        watt: 400,
        icon: Icons.blender_rounded,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'water_pump',
        nameBn: 'পানির পাম্প (১.৫ HP)',
        nameEn: 'Water Pump (1.5 HP)',
        watt: 1400,
        icon: Icons.water_drop_outlined,
        isAc: true,
      ),
      PlannerApplianceItem(
        key: 'other',
        nameBn: 'অন্যান্য লোড',
        nameEn: 'Other Appliance',
        watt: 100,
        icon: Icons.devices_other_rounded,
        isAc: true,
      ),
    ];
  }

  void _editApplianceWatt(
    BuildContext context,
    PlannerApplianceItem item,
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
                setState(() {
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

  Future<void> _exportPdfReport() async {
    setState(() => _isExportingPdf = true);
    try {
      final layoutResult = SolarGeometryEngine.calculateDiscreteLayout(
        northSouthSpanM: math.sqrt(widget.netUsableSqM),
        eastWestSpanM: math.sqrt(widget.netUsableSqM),
        netUsableAreaSqM: widget.netUsableSqM,
        latitude: widget.latitude,
        moduleWatt: _selectedModuleWatt,
      );

      final int rows = layoutResult['rows'] as int;
      final int cols = layoutResult['cols'] as int;
      final int totalModules = rows * cols;
      final double systemCapacityKwp =
          (totalModules * _selectedModuleWatt) / 1000.0;
      final double optimalTilt = layoutResult['tiltDeg'] as double;

      final double tempDerate =
          SolarCalculationService.calculateTempDerateFactor(widget.ambientTemp);
      final double psh =
          widget.initialNasaPsh ?? SolarRadiationService.defaultPsh;

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
      final double dailyGenKwh = systemCapacityKwp * psh * effectivePR;
      final double monthlyGenKwh = dailyGenKwh * 30;

      final double estimatedTotalBudget =
          systemCapacityKwp * 1000.0 * _pricePerWatt;

      await LandPdfExportService.generateAndSharePdf(
        centroid: ll.LatLng(widget.latitude, widget.longitude),
        placeName: widget.locationPlaceName,
        totalRoofSqFt: widget.totalRoofSqFt,
        obstacleSqFt: widget.obstacleSqFt,
        netUsableSqFt: widget.netUsableSqM * 10.7639,
        netUsableSqM: widget.netUsableSqM,
        capacityKwp: systemCapacityKwp,
        totalPanels: totalModules,
        rows: rows,
        cols: cols,
        optimalTilt: optimalTilt,
        dailyGenKwh: dailyGenKwh,
        monthlyGenKwh: monthlyGenKwh,
        estimatedBudget: estimatedTotalBudget,
        systemType: _selectedSystemType,
        batteryChemistry: _selectedBatteryChemistry,
        selectedModuleWatt: _selectedModuleWatt,
        selectedModuleEfficiency: _selectedModuleEfficiency,
        pricePerWatt: _pricePerWatt,
        nasaPsh: psh,
        ambientTemp: widget.ambientTemp,
        isBangla: _isBangla,
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final layoutResult = SolarGeometryEngine.calculateDiscreteLayout(
      northSouthSpanM: math.sqrt(widget.netUsableSqM),
      eastWestSpanM: math.sqrt(widget.netUsableSqM),
      netUsableAreaSqM: widget.netUsableSqM,
      latitude: widget.latitude,
      moduleWatt: _selectedModuleWatt,
    );

    final int rows = layoutResult['rows'] as int;
    final int cols = layoutResult['cols'] as int;
    final int totalModules = rows * cols;
    final double systemCapacityKwp =
        (totalModules * _selectedModuleWatt) / 1000.0;
    final double rowPitch = layoutResult['pitchM'] as double;
    final double optimalTilt = layoutResult['tiltDeg'] as double;
    final bool isSingleRow = rows == 1;

    final double tempDerate = SolarCalculationService.calculateTempDerateFactor(
      widget.ambientTemp,
    );
    final double psh =
        widget.initialNasaPsh ?? SolarRadiationService.defaultPsh;

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
    final double dailyGenerationKwh = systemCapacityKwp * psh * effectivePR;
    final double dailyGenerationWh = dailyGenerationKwh * 1000.0;
    final double monthlyGenerationKwh = dailyGenerationKwh * 30;

    // 🌟 এসি এবং ডিসি লোড আলাদা সমন্বিত মোট চাহিদা
    final double totalPlannedEffectiveWh = _plannerAppliances.fold(
      0.0,
      (sum, item) => sum + item.getEffectiveDailyWh(),
    );
    final double remainingWh = dailyGenerationWh - totalPlannedEffectiveWh;
    final double usageRatio = dailyGenerationWh > 0
        ? (totalPlannedEffectiveWh / dailyGenerationWh).clamp(0.0, 1.5)
        : 0.0;
    final bool isOverloaded = totalPlannedEffectiveWh > dailyGenerationWh;
    final Color plannerStatusColor = isOverloaded
        ? Colors.redAccent
        : (usageRatio > 0.85 ? Colors.orangeAccent : AppColors.energyGreen);

    final double totalSystemWatt = systemCapacityKwp * 1000.0;
    final double estimatedTotalBudget = totalSystemWatt * _pricePerWatt;

    final double annualGenYr1 = dailyGenerationKwh * 365.0;
    final double lifetimeGen25Yrs = annualGenYr1 * 25.0 * 0.94;
    final double thermalLossPercent = ((1.0 - tempDerate) * 100.0).clamp(
      0.0,
      30.0,
    );

    final double deadLoadKgM2 = 14.5;
    final double estimatedArrayWeightKg =
        (totalModules * (_selectedModuleWatt >= 400 ? 28.5 : 18.0));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: TwoLineAppBarTitle(
            title: _isBangla ? 'সৌর সম্ভাব্যতা' : 'Solar Feasibility',
            subtitle: _isBangla
                ? 'বাজেট ও কারিগরি সাইজিং'
                : 'Budget & Technical Sizing',
          ),
          actions: [
            IconButton(
              tooltip: _isBangla ? 'PDF প্রপোজাল শেয়ার' : 'Share PDF Report',
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
              onPressed: _isExportingPdf ? null : () => _exportPdfReport(),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isBangla = !_isBangla;
                  _pricePerWatt = _getDefaultRateForType(
                    _selectedSystemType,
                    _selectedBatteryChemistry,
                  );
                });
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
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            tabs: [
              Tab(
                icon: const Icon(
                  Icons.solar_power,
                  size: 18,
                  color: Colors.white,
                ),
                child: Text(
                  _isBangla ? 'সাইজিং ও বাজেট' : 'Sizing & Budget',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Tab(
                icon: const Icon(
                  Icons.electric_bolt_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                child: Text(
                  _isBangla ? 'ব্যবহার' : 'Usage Planner',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Tab(
                icon: const Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                child: Text(
                  _isBangla ? 'উৎপাদন' : 'Generation',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Tab(
                icon: const Icon(
                  Icons.engineering_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                child: Text(
                  _isBangla ? 'ইনস্টলেশন' : 'Installation',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
          child: TabBarView(
            children: [
              // ==========================================
              // ট্যাব ১: সাইজিং ও বাজেট
              // ==========================================
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (totalModules == 0) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.alertRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.alertRed.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.alertRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isBangla
                                    ? 'চিহ্নিত জায়গায় নির্বাচিত ${_selectedModuleWatt}W প্যানেল বসানোর মতো স্থান নেই। ছোট ওয়াটের প্যানেল বেছে নিন।'
                                    : 'Not enough area to fit ${_selectedModuleWatt}W modules. Please choose smaller wattage.',
                                style: const TextStyle(
                                  color: AppColors.alertRed,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
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
                            size: 16,
                            color: isDark
                                ? AppColors.accentCyan
                                : AppColors.energyGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isBangla
                                  ? (isSingleRow
                                        ? 'লেআউট: ১টি একক সারি × ${cols}টি কলাম (মোট $totalModules টি প্যানেল)'
                                        : (rows > 1
                                              ? 'লেআউট: ${rows}টি সারি × ${cols}টি কলাম (মোট $totalModules টি প্যানেল) | সারি দূরত্ব: ${rowPitch.toStringAsFixed(2)} মি'
                                              : 'স্থান অপর্যাপ্ত'))
                                  : (isSingleRow
                                        ? 'Layout: 1 Row × $cols Columns (Total: $totalModules Modules)'
                                        : (rows > 1
                                              ? 'Layout: $rows Rows × $cols Columns (Total: $totalModules Modules) | Pitch: ${rowPitch.toStringAsFixed(2)} m'
                                              : 'Insufficient Area')),
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
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
                      child: Row(
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
                                    fontSize: 13,
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
                                    if (val != null)
                                      setState(
                                        () => _selectedModuleEfficiency = val,
                                      );
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 50,
                                      child: Text('50 W'),
                                    ),
                                    DropdownMenuItem(
                                      value: 80,
                                      child: Text('80 W'),
                                    ),
                                    DropdownMenuItem(
                                      value: 100,
                                      child: Text('100 W'),
                                    ),
                                    DropdownMenuItem(
                                      value: 150,
                                      child: Text('150 W'),
                                    ),
                                    DropdownMenuItem(
                                      value: 200,
                                      child: Text('200 W'),
                                    ),
                                    DropdownMenuItem(
                                      value: 250,
                                      child: Text('250 W'),
                                    ),
                                    DropdownMenuItem(
                                      value: 330,
                                      child: Text('330 W'),
                                    ),
                                    DropdownMenuItem(
                                      value: 400,
                                      child: Text('400 W'),
                                    ),
                                    DropdownMenuItem(
                                      value: 450,
                                      child: Text('450 W'),
                                    ),
                                    DropdownMenuItem(
                                      value: 550,
                                      child: Text('550 W'),
                                    ),
                                    DropdownMenuItem(
                                      value: 620,
                                      child: Text('620 W'),
                                    ),
                                    DropdownMenuItem(
                                      value: 700,
                                      child: Text('700 W'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null)
                                      setState(() => _selectedModuleWatt = val);
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
                          value: '${systemCapacityKwp.toStringAsFixed(2)} kWp',
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
                          title: _isBangla ? 'প্যানেল সংখ্যা' : 'Total Panels',
                          value: _isBangla
                              ? '$totalModules টি'
                              : '$totalModules pcs',
                          subtitle:
                              '$_selectedModuleWatt W (${rows}S × ${cols}P)',
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
                          title: _isBangla ? 'দৈনিক বিদ্যুৎ' : 'Daily Output',
                          value: '${dailyGenerationKwh.toStringAsFixed(1)} kWh',
                          subtitle: _isBangla ? 'ইউনিট / দিন' : 'kWh / Day',
                          icon: Icons.wb_sunny_rounded,
                          color: AppColors.energyGreen,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          title: _isBangla ? 'মাসিক বিদ্যুৎ' : 'Monthly Output',
                          value:
                              '${monthlyGenerationKwh.toStringAsFixed(0)} kWh',
                          subtitle: _isBangla ? 'ইউনিট / মাস' : 'kWh / Month',
                          icon: Icons.calendar_month_rounded,
                          color: isDark
                              ? Colors.tealAccent
                              : const Color(0xFF0D9488),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightCardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.payments_outlined,
                                    size: 20,
                                    color: isDark
                                        ? AppColors.accentCyan
                                        : const Color(0xFF0284C7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isBangla
                                        ? 'সম্ভাব্য সিস্টেম বাজেট'
                                        : 'Estimated Budget',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _formatBudget(estimatedTotalBudget),
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.solarGold
                                      : const Color(0xFFB45309),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSystemTypeChip(
                                SolarSystemType.gridTied,
                                _isBangla ? 'অন-গ্রিড' : 'On-Grid',
                                isDark,
                              ),
                              const SizedBox(width: 6),
                              _buildSystemTypeChip(
                                SolarSystemType.hybrid,
                                _isBangla ? 'হাইব্রিড' : 'Hybrid',
                                isDark,
                              ),
                              const SizedBox(width: 6),
                              _buildSystemTypeChip(
                                SolarSystemType.offGrid,
                                _isBangla ? 'অফ-গ্রিড' : 'Off-Grid',
                                isDark,
                              ),
                            ],
                          ),
                          if (_selectedSystemType !=
                              SolarSystemType.gridTied) ...[
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
                                    ? 'প্রতি ওয়াট সিস্টেম খরচ:'
                                    : 'Turnkey Rate per Watt:',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : AppColors.lightTextSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                _isBangla
                                    ? '৳ ${_pricePerWatt.toStringAsFixed(0)} / W'
                                    : '\$ ${_pricePerWatt.toStringAsFixed(2)} / W',
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
                          Slider(
                            value: _pricePerWatt,
                            min: _isBangla ? 50.0 : 0.40,
                            max: _isBangla ? 180.0 : 1.60,
                            divisions: 130,
                            onChanged: (val) =>
                                setState(() => _pricePerWatt = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // ট্যাব ২: লোড ব্যবহার পরিকল্পনা (AC/DC চয়েজ ও ফিক্সড প্রগ্রেস বার সহ)
              // ==========================================
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOverloaded
                              ? Colors.redAccent.withValues(alpha: 0.7)
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isBangla
                                    ? 'কার্যকর চাহিদা: ${totalPlannedEffectiveWh.toStringAsFixed(0)} Wh'
                                    : 'Planned: ${totalPlannedEffectiveWh.toStringAsFixed(0)} Wh',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: plannerStatusColor,
                                ),
                              ),
                              Text(
                                _isBangla
                                    ? 'মোট উৎপাদন: ${dailyGenerationWh.toStringAsFixed(0)} Wh'
                                    : 'Available: ${dailyGenerationWh.toStringAsFixed(0)} Wh',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 🌟 সংশোধিত প্রিমিয়াম ও স্পষ্ট দৃশ্যমান প্রগ্রেস বার
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOverloaded
                                      ? AppColors.alertRed.withValues(
                                          alpha: 0.5,
                                        )
                                      : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1)),
                                  width: 1.0,
                                ),
                              ),
                              child: LinearProgressIndicator(
                                value: usageRatio > 1.0 ? 1.0 : usageRatio,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  plannerStatusColor,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: plannerStatusColor,
                                ),
                              ),
                              Text(
                                '${(usageRatio * 100).toStringAsFixed(0)}% ${_isBangla ? "ব্যবহার" : "Used"}',
                                style: TextStyle(
                                  fontSize: 11,
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
                    const SizedBox(height: 12),
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
                        final double effectiveWh = item.getEffectiveDailyWh();

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
                                      ? Colors.white.withValues(alpha: 0.02)
                                      : Colors.black.withValues(alpha: 0.02)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? (isDark
                                        ? AppColors.accentCyan.withValues(
                                            alpha: 0.35,
                                          )
                                        : const Color(0xFF93C5FD))
                                  : (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isActive
                                        ? (isDark
                                              ? AppColors.accentCyan
                                              : AppColors.primaryGreen)
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
                                          _isBangla ? item.nameBn : item.nameEn,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${effectiveWh.toStringAsFixed(0)} Wh/day ${item.isAc ? "(90% AC eff.)" : "(DC Direct)"}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isActive
                                                ? (isDark
                                                      ? AppColors.solarGold
                                                      : const Color(0xFFB45309))
                                                : (isDark
                                                      ? Colors.white38
                                                      : Colors.grey.shade600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ওয়াট এডিট বাটন
                                  InkWell(
                                    onTap: () => _editApplianceWatt(
                                      context,
                                      item,
                                      isDark,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF0B132B)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.accentCyan.withValues(
                                                  alpha: 0.5,
                                                )
                                              : const Color(0xFF0284C7),
                                        ),
                                      ),
                                      child: Text(
                                        '${item.watt.toInt()} W',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppColors.accentCyan
                                              : const Color(0xFF0284C7),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 🌟 হাই-কনট্রাস্ট ও স্পষ্ট দৃশ্যমান AC/DC সিলেকশন সুইচ
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1),
                                        width: 1.0,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(2.5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // ১. এসি (AC) বাটন
                                        InkWell(
                                          onTap: () {
                                            if (!item.isAc)
                                              setState(() => item.isAc = true);
                                          },
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 4.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: item.isAc
                                                  ? const Color(0xFFD97706)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              boxShadow: item.isAc
                                                  ? [
                                                      BoxShadow(
                                                        color:
                                                            const Color(
                                                              0xFFD97706,
                                                            ).withValues(
                                                              alpha: 0.45,
                                                            ),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Text(
                                              'AC',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                                color: item.isAc
                                                    ? Colors.white
                                                    : (isDark
                                                          ? const Color(
                                                              0xFF94A3B8,
                                                            )
                                                          : const Color(
                                                              0xFF64748B,
                                                            )),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2),

                                        // ২. ডিসি (DC) বাটন
                                        InkWell(
                                          onTap: () {
                                            if (item.isAc)
                                              setState(() => item.isAc = false);
                                          },
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 4.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: !item.isAc
                                                  ? AppColors.energyGreen
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              boxShadow: !item.isAc
                                                  ? [
                                                      BoxShadow(
                                                        color: AppColors
                                                            .energyGreen
                                                            .withValues(
                                                              alpha: 0.45,
                                                            ),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Text(
                                              'DC',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                                color: !item.isAc
                                                    ? Colors.white
                                                    : (isDark
                                                          ? const Color(
                                                              0xFF94A3B8,
                                                            )
                                                          : const Color(
                                                              0xFF64748B,
                                                            )),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // সংখ্যা বাড়ানোর/কমানোর কাউন্টার
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (item.quantity > 0)
                                            setState(() => item.quantity--);
                                        },
                                        child: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () =>
                                            setState(() => item.quantity++),
                                        child: const Icon(
                                          Icons.add_circle_outline,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (item.quantity > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '${item.hours.toStringAsFixed(1)} ${_isBangla ? "ঘণ্টা/দিন" : "hrs/day"}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        value: item.hours,
                                        min: 0.0,
                                        max: 24.0,
                                        divisions: 48,
                                        onChanged: (val) =>
                                            setState(() => item.hours = val),
                                      ),
                                    ),
                                  ],
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

              // ==========================================
              // ট্যাব ৩: উৎপাদন
              // ==========================================
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
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
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isBangla
                                        ? '১ম বছরের উৎপাদন:'
                                        : 'Year 1 Yield:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${(annualGenYr1 / 1000).toStringAsFixed(1)} MWh (${annualGenYr1.toStringAsFixed(0)} kWh)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.energyGreen,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _isBangla
                                        ? '২৫ বছরের মোট উৎপাদন:'
                                        : '25-Yr Lifetime:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${(lifetimeGen25Yrs / 1000).toStringAsFixed(1)} MWh (অবক্ষয় সহ)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.accentCyan
                                          : const Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(
                            height: 1,
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.thermostat_rounded,
                                size: 16,
                                color: thermalLossPercent > 5
                                    ? Colors.orangeAccent
                                    : AppColors.energyGreen,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _isBangla
                                      ? 'তাপমাত্রাজনিত লস: -${thermalLossPercent.toStringAsFixed(1)}% (গ্রীষ্মকালে কার্যকর)'
                                      : 'Thermal Derate Loss: -${thermalLossPercent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (widget.monthlyPsh.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isBangla
                                  ? 'মাসভিত্তিক বিদ্যুৎ উৎপাদন (kWh)'
                                  : 'Monthly Yield Output (kWh)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 110,
                              child: _buildMonthlyGenerationChart(
                                widget.monthlyPsh,
                                systemCapacityKwp,
                                effectivePR,
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isBangla
                                  ? 'সৌর বিকিরণ প্রোফাইল (PSH)'
                                  : 'Solar Radiation (PSH)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: SolarPshChartWithAxis(
                                monthlyPsh: widget.monthlyPsh,
                                annualAvgPsh: psh,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (widget.monthlyTempAvg.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isBangla
                                  ? 'তাপমাত্রা প্রোফাইল (°C)'
                                  : 'Temperature Profile (°C)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 105,
                              child: TemperatureEnvelopeWithAxis(
                                tempAvg: widget.monthlyTempAvg,
                                tempMax: widget.monthlyTempMax,
                                tempMin: widget.monthlyTempMin,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ==========================================
              // ট্যাব ৪: ইনস্টলেশন
              // ==========================================
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStatCard(
                          title: _isBangla ? 'আদর্শ কাত কোণ' : 'Optimal Tilt',
                          value: '${optimalTilt.toStringAsFixed(1)}°',
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
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.wb_sunny_outlined,
                                size: 18,
                                color: AppColors.solarGold,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isBangla
                                    ? 'শীতকালীন ছায়ামুক্ত সারি দূরত্ব (Row Pitch):'
                                    : 'Winter Shadow Pitch Clearance:',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isSingleRow
                                ? (_isBangla
                                      ? '১টি একক সারি হওয়ায় পেছনের সারির ছায়ার ঝুঁকি নেই।'
                                      : 'Single row setup; no inter-row shadow risk.')
                                : (_isBangla
                                      ? 'প্রতি দুই সারির মাঝে অন্তত ${rowPitch.toStringAsFixed(2)} মিটার (${(rowPitch * 3.28084).toStringAsFixed(1)} ফুট) ফাঁকা রাখতে হবে (২১ ডিসেম্বরের সর্বনিম্ন সৌর উচ্চতা অনুযায়ী)।'
                                      : 'Minimum ${rowPitch.toStringAsFixed(2)} m (${(rowPitch * 3.28084).toStringAsFixed(1)} ft) clearance required between rows for Dec 21 winter solstice.'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.architecture_rounded,
                                size: 18,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isBangla
                                    ? 'ছাদের ওপর কাঠামোগত লোড (Dead Load):'
                                    : 'Rooftop Structural Dead Load:',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isBangla
                                ? 'অ্যারে ও মাউন্টিং ফ্রেমের গড় ওজন: ≈ $deadLoadKgM2 kg/m² (মোট ওজন ≈ ${estimatedArrayWeightKg.toStringAsFixed(0)} kg)। সাধারণ RCC পাকা ছাদ এই ওজন অনায়াসে বহন করতে পারে।'
                                : 'Average array dead load: ≈ $deadLoadKgM2 kg/m² (Total weight ≈ ${estimatedArrayWeightKg.toStringAsFixed(0)} kg). Standard RCC concrete roofs support this comfortably.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isCoastal
                              ? Colors.orangeAccent.withValues(alpha: 0.6)
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.air_rounded,
                                size: 18,
                                color: widget.isCoastal
                                    ? Colors.orangeAccent
                                    : Colors.tealAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isBangla
                                    ? 'বাতাসের গতিবেগ ও মাউন্টিং গাইডলাইন:'
                                    : 'Wind Velocity & Mounting Standard:',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isBangla
                                ? (widget.isCoastal
                                      ? '⚠️ উপকূলীয় অঞ্চল: বাতাসের গড় গতিবেগ ${widget.windSpeed.toStringAsFixed(1)} m/s। ঘূর্ণিঝড় ও তীব্র বাতাস থেকে বাঁচতে ফ্রেমে উইন্ড ডিফ্লেক্টর এবং শক্তিশালী কংক্রিট বেস গ্রাউন্ডিং বাধ্যতামূলক।'
                                      : 'বাতাসের স্বাভাবিক গতিবেগ ${widget.windSpeed.toStringAsFixed(1)} m/s। সমতল RCC ছাদে জিআই বা অ্যালুমিনিয়াম ফ্রেমে অ্যাঙ্কর বোল্ট ব্যবহার করুন। টিনের চালার ক্ষেত্রে উপযুক্ত ক্ল্যাম্প দিয়ে সরাসরি পার্লিনে যুক্ত করুন।')
                                : (widget.isCoastal
                                      ? '⚠️ Coastal Zone: Wind speed ${widget.windSpeed.toStringAsFixed(1)} m/s. Wind deflectors & heavy concrete foundation grounding required.'
                                      : 'Normal wind speed ${widget.windSpeed.toStringAsFixed(1)} m/s. Anchor securely on flat RCC roof or clamp directly into tin roof purlins.'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.lightTextSecondary,
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
      ),
    );
  }

  Widget _buildMonthlyGenerationChart(
    Map<String, double> monthlyPsh,
    double capacityKwp,
    double effectivePR,
    bool isDark,
  ) {
    final Map<String, double> monthlyGen = {};
    for (var entry in monthlyPsh.entries) {
      monthlyGen[entry.key] = capacityKwp * entry.value * effectivePR * 30.0;
    }

    final double maxVal = monthlyGen.values.isNotEmpty
        ? monthlyGen.values.reduce(math.max) * 1.15
        : 500.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: monthlyGen.entries.map((entry) {
        final double barRatio = (entry.value / maxVal).clamp(0.08, 1.0);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  entry.value.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.energyGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  height: 60 * barRatio,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.accentCyan
                        : AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.key.substring(0, 1),
                  style: TextStyle(
                    fontSize: 8.5,
                    color: isDark
                        ? Colors.white60
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSystemTypeChip(SolarSystemType type, String label, bool isDark) {
    final bool isSelected = _selectedSystemType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSystemType = type;
            _pricePerWatt = _getDefaultRateForType(
              type,
              _selectedBatteryChemistry,
            );
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppColors.accentCyan.withValues(alpha: 0.2)
                      : const Color(0xFF0284C7).withValues(alpha: 0.12))
                : (isDark ? Colors.black26 : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppColors.accentCyan : const Color(0xFF0284C7))
                  : (isDark ? Colors.white12 : Colors.black12),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.accentCyan : const Color(0xFF0284C7))
                    : (isDark ? Colors.white60 : Colors.black87),
              ),
            ),
          ),
        ),
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
            _pricePerWatt = _getDefaultRateForType(_selectedSystemType, chem);
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.16)
                : (isDark ? Colors.black26 : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.white12 : Colors.black12),
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
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : activeColor)
                      : (isDark ? Colors.white70 : AppColors.lightTextPrimary),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8.5,
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
