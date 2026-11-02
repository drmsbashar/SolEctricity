import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/solar_radiation_service.dart';

enum SystemType { onGrid, offGrid, hybrid }

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
  ); // ডিফল্ট ২০ ইউনিট/দিন
  SystemType _selectedSystemType = SystemType.onGrid;

  double _selectedModuleEfficiency = 0.215; // ২১.৫% (Mono-PERC)
  int _selectedModuleWatt = 550; // ৫৫০ ওয়াট
  int _backupHours = 4; // অফ-গ্রিড/হাইব্রিডের জন্য ব্যাকআপ ঘণ্টা
  double _dayLoadPercentage = 60.0; // দিনের লোড ৬০%, রাতের লোড ৪০%

  bool _isLoadingNasa = false;
  SolarRadiationResult? _climateData;

  double _latitude = 23.8103;
  double _longitude = 90.4125;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _fetchLocationClimateData();
  }

  @override
  void dispose() {
    _demandController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationClimateData() async {
    setState(() => _isLoadingNasa = true);
    try {
      final result = await SolarRadiationService.fetchPshByCoordinates(
        _latitude,
        _longitude,
      );
      setState(() => _climateData = result);
    } catch (_) {
      setState(() {
        _climateData = SolarRadiationResult(
          peakSunHours: SolarRadiationService.defaultPsh,
          messageBn: 'ডিফল্ট সৌর বিকিরণ ব্যবহৃত হচ্ছে',
          messageEn: 'Using default solar radiation',
          isSuccess: false,
        );
      });
    } finally {
      if (mounted) setState(() => _isLoadingNasa = false);
    }
  }

  double _calculateDynamicPackingFactor(double latitude) {
    final double absLat = latitude.abs();
    if (absLat <= 15.0) return 0.75;
    if (absLat <= 25.0) return 0.75 - ((absLat - 15.0) / 10.0) * 0.07;
    if (absLat <= 35.0) return 0.68 - ((absLat - 25.0) / 10.0) * 0.08;
    return 0.58;
  }

  double _calculateTempDerateFactor(double ambientTemp) {
    const double noct = 45.0;
    const double tempCoeff = 0.0035;
    final double cellTemp = ambientTemp + (noct - 20.0);
    if (cellTemp <= 25.0) return 1.0;
    final double loss = (cellTemp - 25.0) * tempCoeff;
    return (1.0 - loss).clamp(0.75, 1.0);
  }

  // 🔌 স্ট্রিং কনফিগারেশন হিসাব
  Map<String, int> _calculateStringConfiguration(int totalPanels) {
    if (totalPanels <= 0) return {'strings': 0, 'panelsPerString': 0};
    if (totalPanels <= 8) return {'strings': 1, 'panelsPerString': totalPanels};

    // সাধারণত একটি স্ট্রিংয়ে ৮ থেকে ২০টি প্যানেল আদর্শ
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

  @override
  Widget build(BuildContext context) {
    final double dailyDemandKwh =
        double.tryParse(_demandController.text) ?? 0.0;

    final double psh =
        _climateData?.peakSunHours ?? SolarRadiationService.defaultPsh;
    final double ambTemp = _climateData?.ambientTemp ?? 26.0;
    final double tempDerate = _calculateTempDerateFactor(ambTemp);

    final double basePR = _selectedSystemType == SystemType.onGrid
        ? 0.80
        : 0.72;
    final double effectivePR = basePR * tempDerate;

    // ১. প্রয়োজনীয় ডিসি ক্ষমতা (kWp)
    final double requiredCapacityKwp = (psh > 0 && effectivePR > 0)
        ? (dailyDemandKwh / (psh * effectivePR))
        : 0.0;

    // ২. প্যানেল সংখ্যা ও স্ট্রিং বিন্যাস
    final int totalPanels = (requiredCapacityKwp > 0)
        ? ((requiredCapacityKwp * 1000) / _selectedModuleWatt).ceil()
        : 0;
    final stringConfig = _calculateStringConfiguration(totalPanels);

    // ৩. জায়গা
    final double dynamicPF = _calculateDynamicPackingFactor(_latitude);
    final double netRoofAreaSqM = (requiredCapacityKwp > 0)
        ? (requiredCapacityKwp / (_selectedModuleEfficiency * dynamicPF))
        : 0.0;
    final double netRoofAreaSqFt = netRoofAreaSqM * 10.7639;

    // ৪. দিন ও রাতের লোড বণ্টন
    final double dayEnergyKwh = dailyDemandKwh * (_dayLoadPercentage / 100.0);
    final double nightEnergyKwh = dailyDemandKwh - dayEnergyKwh;

    // ৫. প্রস্তাবিত ব্যাটারি ব্যাংক (DoD ৮০%, ব্যাটারি এফিশিয়েন্সি ৮৫%)
    final double batteryBankKwh =
        (_selectedSystemType != SystemType.onGrid && dailyDemandKwh > 0)
        ? ((nightEnergyKwh * (_backupHours / 12.0).clamp(0.2, 1.0)) /
              (0.80 * 0.85))
        : 0.0;

    // ৬. ইনভার্টার সাইজ (DC/AC Ratio প্রায় ১.১৫ থেকে ১.২০)
    final double inverterKw = requiredCapacityKwp > 0
        ? (requiredCapacityKwp / 1.15).clamp(1.0, 500.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isBangla
              ? 'চাহিদাভিত্তিক সোলার সাইজিং'
              : 'Demand-Based Solar Sizing',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isBangla ? 'প্রপোজাল সারাংশ' : 'Proposal Summary',
            icon: const Icon(
              Icons.description_rounded,
              color: Colors.cyanAccent,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClimateHeader(psh, ambTemp),
            const SizedBox(height: 14),

            _buildDemandInputCard(),
            const SizedBox(height: 14),

            // দিন ও রাতের লোড বণ্টন কার্ড
            _buildDayNightSplitCard(dayEnergyKwh, nightEnergyKwh),
            const SizedBox(height: 14),

            _buildConfigurationCard(),
            const SizedBox(height: 18),

            Text(
              _isBangla ? 'প্রকৌশল সাইজিং ফলাফল' : 'Engineering Sizing Results',
              style: const TextStyle(
                color: Colors.white,
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
                      ? 'বাৎসরিক: ${(dailyDemandKwh * 365).toStringAsFixed(0)} kWh'
                      : 'Annual: ${(dailyDemandKwh * 365).toStringAsFixed(0)} kWh',
                  icon: Icons.flash_on_rounded,
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 10),
                _buildResultStatCard(
                  title: _isBangla ? 'প্যানেল সংখ্যা' : 'Total Panels',
                  value: _isBangla ? '$totalPanels টি' : '$totalPanels pcs',
                  subtitle: '$_selectedModuleWatt Watt Modules',
                  icon: Icons.grid_view_rounded,
                  color: Colors.amberAccent,
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
                  color: Colors.cyanAccent,
                ),
                const SizedBox(width: 10),
                _buildResultStatCard(
                  title: _isBangla
                      ? 'প্রস্তাবিত ইনভার্টার'
                      : 'Recommended Inverter',
                  value: '${inverterKw.toStringAsFixed(1)} kW',
                  subtitle: 'DC/AC Ratio ≈ 1.15',
                  icon: Icons.developer_board_rounded,
                  color: Colors.tealAccent,
                ),
              ],
            ),

            const SizedBox(height: 10),
            // স্ট্রিং ম্যাচিং কনফিগারেশন কার্ড
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cable_rounded,
                    color: Colors.cyanAccent,
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
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isBangla
                              ? '${stringConfig['strings']} টি স্ট্রিং × ${stringConfig['panelsPerString']} টি প্যানেল'
                              : '${stringConfig['strings']} Strings × ${stringConfig['panelsPerString']} Panels',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Voc Safe',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_selectedSystemType != SystemType.onGrid) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.3),
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
                            style: const TextStyle(
                              color: Colors.white70,
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
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            // ১২ মাসের উৎপাদন বনাম চাহিদা বার-গ্রাফ
            if (_climateData != null && _climateData!.monthlyPsh.isNotEmpty)
              _buildSeasonalGenerationChart(
                requiredCapacityKwp,
                effectivePR,
                dailyDemandKwh,
              ),
          ],
        ),
      ),
    );
  }

  // 📊 ১২ মাসের উৎপাদন বনাম দৈনিক চাহিদা গ্রাফ
  Widget _buildSeasonalGenerationChart(
    double capacityKwp,
    double effectivePR,
    double dailyDemandKwh,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, color: Colors.cyanAccent),
                  const SizedBox(width: 4),
                  Text(
                    _isBangla ? 'উৎপাদন' : 'Gen',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 8, height: 2, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(
                    _isBangla ? 'চাহিদা' : 'Target',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
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
            ),
          ),
        ],
      ),
    );
  }

  // ☀️ দিন ও রাতের লোড অনুপাত কার্ড
  Widget _buildDayNightSplitCard(double dayKwh, double nightKwh) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla ? 'দিন ও রাতের লোড বণ্টন' : 'Day vs Night Load Split',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_dayLoadPercentage.toStringAsFixed(0)}% : ${(100 - _dayLoadPercentage).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.amberAccent,
              inactiveTrackColor: Colors.indigoAccent,
              thumbColor: Colors.amberAccent,
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
                    color: Colors.amberAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isBangla
                        ? 'দিনের লোড: ${dayKwh.toStringAsFixed(1)} kWh'
                        : 'Day Load: ${dayKwh.toStringAsFixed(1)} kWh',
                    style: const TextStyle(
                      color: Colors.white70,
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
                    style: const TextStyle(
                      color: Colors.white70,
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

  // 📍 ক্লাইমেট হেডার
  Widget _buildClimateHeader(double psh, double ambTemp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.satellite_alt_rounded,
            color: Colors.cyanAccent,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isBangla
                      ? 'PSH: ${psh.toStringAsFixed(2)} ঘণ্টা | গড় তাপমাত্রা: ${ambTemp.toStringAsFixed(1)}°C'
                      : 'PSH: ${psh.toStringAsFixed(2)} hrs | Avg Temp: ${ambTemp.toStringAsFixed(1)}°C',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          if (_isLoadingNasa)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.cyanAccent,
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white54,
                size: 18,
              ),
              onPressed: _fetchLocationClimateData,
              tooltip: _isBangla ? 'রিফ্রেশ' : 'Refresh',
            ),
        ],
      ),
    );
  }

  // ⚡ চাহিদা ইনপুট কার্ড (টেক্সট ফিল্ড + স্লাইডিং বার)
  Widget _buildDemandInputCard() {
    final double currentVal = double.tryParse(_demandController.text) ?? 20.0;
    // স্লাইডারের সর্বোচ্চ সীমা (ডিফল্ট ১৫০, তবে ব্যবহারকারী বেশি টাইপ করলে তা স্বয়ংক্রিয়ভাবে বাড়বে)
    final double sliderMax = math.max(
      200.0,
      ((currentVal / 50).ceil() * 50).toDouble(),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla ? 'দৈনিক বিদ্যুৎ চাহিদা' : 'Daily Energy Target',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isBangla ? 'ইউনিট বা kWh' : 'Units or kWh',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // টেক্সট ইনপুট ফিল্ড
          TextField(
            controller: _demandController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              prefixIcon: const Icon(
                Icons.bolt_rounded,
                color: Colors.amberAccent,
                size: 24,
              ),
              suffixText: _isBangla ? 'kWh / দিন' : 'kWh / Day',
              suffixStyle: const TextStyle(color: Colors.white54, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 🎚️ রেসপন্সিভ স্লাইডিং বার
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.amberAccent,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.amberAccent,
              overlayColor: Colors.amberAccent.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: currentVal.clamp(1.0, sliderMax),
              min: 1.0,
              max: sliderMax,
              onChanged: (v) {
                setState(() {
                  _demandController.text = v.toStringAsFixed(0);
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 ${_isBangla ? "ইউনিট" : "kWh"}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
                Text(
                  '${(sliderMax / 2).toStringAsFixed(0)} ${_isBangla ? "ইউনিট" : "kWh"}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
                Text(
                  '${sliderMax.toStringAsFixed(0)} ${_isBangla ? "ইউনিট" : "kWh"}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⚙️ কনফিগারেশন কার্ড
  Widget _buildConfigurationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isBangla
                ? 'সিস্টেম ও প্যানেল কনফিগারেশন'
                : 'System & Module Configuration',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildTypeRadio(
                SystemType.onGrid,
                _isBangla ? 'অন-গ্রিড' : 'On-Grid',
              ),
              const SizedBox(width: 8),
              _buildTypeRadio(
                SystemType.hybrid,
                _isBangla ? 'হাইব্রিড' : 'Hybrid',
              ),
              const SizedBox(width: 8),
              _buildTypeRadio(
                SystemType.offGrid,
                _isBangla ? 'অফ-গ্রিড' : 'Off-Grid',
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
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<double>(
                        value: _selectedModuleEfficiency,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(
                          color: Colors.cyanAccent,
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
                    Text(
                      _isBangla ? 'মডিউল ক্ষমতা' : 'Rating',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<int>(
                        value: _selectedModuleWatt,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                        items: const [
                          DropdownMenuItem(value: 150, child: Text('150 W')),
                          DropdownMenuItem(value: 250, child: Text('250 W')),
                          DropdownMenuItem(value: 330, child: Text('330 W')),
                          DropdownMenuItem(value: 400, child: Text('400 W')),
                          DropdownMenuItem(value: 450, child: Text('450 W')),
                          DropdownMenuItem(value: 550, child: Text('550 W')),
                          DropdownMenuItem(value: 620, child: Text('620 W')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedModuleWatt = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_selectedSystemType != SystemType.onGrid) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isBangla ? 'কাঙ্ক্ষিত ব্যাটারি ব্যাকআপ' : 'Required Backup',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
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

  Widget _buildTypeRadio(SystemType type, String title) {
    final bool isSelected = _selectedSystemType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSystemType = type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.cyanAccent.withValues(alpha: 0.15)
                : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.cyanAccent : Colors.white12,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.cyanAccent : Colors.white70,
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
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
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

  // 📑 প্রফেশনাল টেকনিক্যাল প্রপোজাল সামারি ডায়ালগ
  void _showProposalSummaryDialog({
    required double dailyDemandKwh,
    required double capacityKwp,
    required int totalPanels,
    required double roofAreaSqFt,
    required double inverterKw,
    required double batteryBankKwh,
    required int strings,
    required int panelsPerString,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.solar_power_rounded, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            Text(
              _isBangla ? 'সিস্টেম ডিজাইন প্রপোজাল' : 'System Design Proposal',
              style: const TextStyle(color: Colors.white, fontSize: 16),
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
              ),
              _buildSummaryRow(
                _isBangla ? 'ডিসি ক্যাপাসিটি' : 'DC Solar Capacity',
                '${capacityKwp.toStringAsFixed(2)} kWp',
              ),
              _buildSummaryRow(
                _isBangla ? 'মডিউল স্পেসিফিকেশন' : 'Module Rating',
                '$totalPanels pcs × $_selectedModuleWatt W',
              ),
              _buildSummaryRow(
                _isBangla ? 'স্ট্রিং কনফিগারেশন' : 'String Setup',
                '$strings Strings × $panelsPerString Panels',
              ),
              _buildSummaryRow(
                _isBangla ? 'প্রস্তাবিত ইনভার্টার' : 'Inverter Capacity',
                '${inverterKw.toStringAsFixed(1)} kW (Grid-Tied)',
              ),
              _buildSummaryRow(
                _isBangla ? 'প্রয়োজনীয় নেট জায়গা' : 'Required Net Area',
                '${roofAreaSqFt.toStringAsFixed(0)} sq.ft',
              ),
              if (_selectedSystemType != SystemType.onGrid)
                _buildSummaryRow(
                  _isBangla ? 'ব্যাটারি ব্যাংক' : 'Battery Bank',
                  '${batteryBankKwh.toStringAsFixed(1)} kWh',
                ),
              const Divider(color: Colors.white12, height: 16),
              _buildSummaryRow(
                _isBangla ? 'বাৎসরিক উৎপাদন' : 'Est. Annual Generation',
                '≈ ${(dailyDemandKwh * 365).toStringAsFixed(0)} kWh',
                isHighlight: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _isBangla ? 'বন্ধ করুন' : 'Close',
              style: const TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? Colors.amberAccent : Colors.white60,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? Colors.greenAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 📈 ১২ মাসের উৎপাদন বনাম লক্ষ্যমাত্রা বার-চার্ট
// =========================================================================
class SeasonalComparisonChart extends StatelessWidget {
  final Map<String, double> monthlyPsh;
  final double capacityKwp;
  final double effectivePR;
  final double targetDailyKwh;

  const SeasonalComparisonChart({
    super.key,
    required this.monthlyPsh,
    required this.capacityKwp,
    required this.effectivePR,
    required this.targetDailyKwh,
  });

  @override
  Widget build(BuildContext context) {
    // প্রতি মাসের দৈনিক গড় উৎপাদন (kWh)
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
            // লাল টার্গেট ড্যাশড লাইন
            Positioned(
              left: 0,
              right: 0,
              top: targetY.clamp(0.0, constraints.maxHeight - 20),
              child: CustomPaint(
                size: Size(constraints.maxWidth, 2),
                painter: DashedLinePainter(color: Colors.redAccent),
              ),
            ),
            // বার গ্রাফ
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
                                      ? Colors.greenAccent
                                      : Colors.amberAccent,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                height: (constraints.maxHeight - 32) * barRatio,
                                decoration: BoxDecoration(
                                  color: isSurplus
                                      ? Colors.cyanAccent
                                      : Colors.amberAccent.withValues(
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
                        style: const TextStyle(
                          color: Colors.white54,
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
