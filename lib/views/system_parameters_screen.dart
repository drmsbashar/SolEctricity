import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/system_sizing_params.dart';
import '../services/solar_calculation_service.dart';
import '../services/solar_radiation_service.dart';
import 'system_calculation_summary_screen.dart';
import 'system_diagram_screen.dart';

class SystemParametersScreen extends StatefulWidget {
  final double dailyTotalWh;
  final double acPeakWatt;
  final double dailyAcWh;
  final double dailyDcWh;
  final bool isBangla;
  final VoidCallback onToggleLanguage;
  final Function(SystemSizingParams params) onProceedToFinalResults;

  const SystemParametersScreen({
    super.key,
    required this.dailyTotalWh,
    required this.acPeakWatt,
    this.dailyAcWh = 0.0,
    this.dailyDcWh = 0.0,
    required this.isBangla,
    required this.onToggleLanguage,
    required this.onProceedToFinalResults,
  });

  @override
  State<SystemParametersScreen> createState() => _SystemParametersScreenState();
}

class _SystemParametersScreenState extends State<SystemParametersScreen> {
  late SystemSizingParams _params;
  late bool _isBangla;
  bool _isLoadingPsh = false;
  SolarRadiationResult? _pshResult;
  String _selectedBatteryType = 'lead_acid';
  SolarSystemType _selectedSystemType = SolarSystemType.offGrid;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _params = SystemSizingParams.defaultForLoad(
      widget.dailyTotalWh,
      widget.acPeakWatt,
      systemType: _selectedSystemType,
    );
    final recommendedPanels = _getRecommendedPanelPowers();
    final recommendedBatteries = _getRecommendedBatteryCapacities();
    _updatePanelParametersFromWatts(recommendedPanels.first);
    _params.batteryCapacityAh = recommendedBatteries.first;
    _fetchNasaPshData();
  }

  double _getRecommendedVoltage() {
    if (widget.dailyTotalWh <= 1500 && widget.acPeakWatt <= 1000) return 12.0;
    if (widget.dailyTotalWh <= 3000 && widget.acPeakWatt <= 2500) return 24.0;
    return 48.0;
  }

  List<double> _getRecommendedPanelPowers() {
    if (widget.dailyTotalWh <= 800) return [50.0, 80.0, 100.0, 150.0];
    if (widget.dailyTotalWh <= 2500) return [150.0, 200.0, 250.0, 350.0];
    return [350.0, 450.0, 550.0, 650.0];
  }

  List<double> _getRecommendedBatteryCapacities() {
    if (widget.dailyTotalWh <= 800) return [40.0, 50.0, 80.0, 100.0];
    if (widget.dailyTotalWh <= 2500) return [100.0, 130.0, 150.0, 200.0];
    return [150.0, 200.0, 230.0, 260.0];
  }

  void _updatePanelParametersFromWatts(double watts) {
    setState(() {
      _params.panelPmax = watts;
      if (watts == 50.0) {
        _params.panelVoc = 22.70;
        _params.panelImp = 2.63;
        _params.panelIsc = 2.83;
      } else if (watts == 80.0) {
        _params.panelVoc = 22.40;
        _params.panelImp = 4.40;
        _params.panelIsc = 4.80;
      } else if (watts == 100.0) {
        _params.panelVoc = 22.50;
        _params.panelImp = 5.50;
        _params.panelIsc = 5.90;
      } else if (watts == 150.0) {
        _params.panelVoc = 22.70;
        _params.panelImp = 8.20;
        _params.panelIsc = 8.80;
      } else if (watts == 200.0) {
        _params.panelVoc = 24.30;
        _params.panelImp = 9.80;
        _params.panelIsc = 10.40;
      } else if (watts == 250.0) {
        _params.panelVoc = 37.50;
        _params.panelImp = 8.35;
        _params.panelIsc = 8.90;
      } else if (watts == 350.0) {
        _params.panelVoc = 46.50;
        _params.panelImp = 9.10;
        _params.panelIsc = 9.70;
      } else if (watts == 450.0) {
        _params.panelVoc = 49.30;
        _params.panelImp = 10.95;
        _params.panelIsc = 11.50;
      } else if (watts == 550.0) {
        _params.panelVoc = 49.80;
        _params.panelImp = 13.15;
        _params.panelIsc = 13.95;
      } else if (watts == 650.0) {
        _params.panelVoc = 51.20;
        _params.panelImp = 15.30;
        _params.panelIsc = 16.10;
      } else {
        double estimatedVoc = (watts <= 200.0)
            ? 22.5
            : ((watts <= 300.0) ? 37.0 : 48.0);
        double estimatedVmp = estimatedVoc * 0.81;
        double estimatedImp = watts / estimatedVmp;
        double estimatedIsc = estimatedImp * 1.07;
        _params.panelVoc = double.parse(estimatedVoc.toStringAsFixed(2));
        _params.panelImp = double.parse(estimatedImp.toStringAsFixed(2));
        _params.panelIsc = double.parse(estimatedIsc.toStringAsFixed(2));
      }
    });
  }

  void _applyBatteryTypePreset(String type) {
    setState(() {
      _selectedBatteryType = type;
      if (type == 'lead_acid') {
        _params.batteryEfficiency = 80.0;
        _params.batteryDod = 70.0;
      } else if (type == 'tubular') {
        _params.batteryEfficiency = 85.0;
        _params.batteryDod = 50.0;
      } else if (type == 'lithium') {
        _params.batteryEfficiency = 95.0;
        _params.batteryDod = 85.0;
      }
    });
  }

  Future<void> _fetchNasaPshData() async {
    setState(() => _isLoadingPsh = true);
    final result = await SolarRadiationService.fetchPeakSunHours();
    if (mounted) {
      setState(() {
        _isLoadingPsh = false;
        _pshResult = result;
        _params.peakSunHours = result.peakSunHours;
      });
    }
  }

  void _handleLanguageToggle() {
    setState(() => _isBangla = !_isBangla);
    widget.onToggleLanguage();
  }

  void _showStickerHelpDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: isDark ? AppColors.accentCyan : AppColors.primaryGreen,
            ),
            const SizedBox(width: 8),
            Text(
              _isBangla ? 'প্যানেল স্পেক্স নির্দেশিকা' : 'PV Specs Guide',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          _isBangla
              ? 'সোলার প্যানেলের পেছনে লাগানো সিলভার নেমপ্লেট স্টিকার থেকে Voc, Imp এবং Isc মানগুলো দেখতে পাবেন।\n\n'
                    '• Pmax: রেটেড ক্ষমতা (Watt)\n'
                    '• Voc: ওপেন সার্কিট ভোল্টেজ\n'
                    '• Imp: সর্বোচ্চ পাওয়ার কারেন্ট\n'
                    '• Isc: শর্ট সার্কিট কারেন্ট\n\n'
                    'সঠিক হিসাবের জন্য স্টিকারের সাথে মানগুলো মিলিয়ে এডিট করে নিতে পারেন।'
              : 'Refer to the technical specification sticker on the back of your solar panel (STC ratings):\n\n'
                    '• Pmax: Maximum power rating (W)\n'
                    '• Voc: Open circuit voltage (V)\n'
                    '• Imp: Current at maximum power (A)\n'
                    '• Isc: Short circuit current (A)\n\n'
                    'Tap any value box below to update them according to your exact panel sticker.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _isBangla ? 'বুঝেছি' : 'Got it',
              style: TextStyle(
                color: isDark ? AppColors.accentCyan : AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDirectValueEditor({
    required String title,
    required double currentValue,
    required double min,
    required double max,
    required ValueChanged<double> onSubmitted,
    required bool isDark,
  }) {
    final controller = TextEditingController(text: currentValue.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_isBangla ? "মান নির্ধারণ করুন" : "Set Value"}: $title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.check_circle,
                    color: isDark
                        ? AppColors.accentCyan
                        : AppColors.primaryGreen,
                  ),
                  onPressed: () {
                    final val = double.tryParse(controller.text);
                    if (val != null && val >= min && val <= max) {
                      onSubmitted(val);
                      Navigator.pop(context);
                    }
                  },
                ),
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
    final recommendedVoltage = _getRecommendedVoltage();
    final isGridTied = _selectedSystemType == SolarSystemType.gridTied;
    final isHybrid = _selectedSystemType == SolarSystemType.hybrid;

    int secNum = 1;
    String getSecNum() {
      final current = secNum;
      secNum++;
      if (_isBangla) {
        return '$current'
            .replaceAll('0', '০')
            .replaceAll('1', '১')
            .replaceAll('2', '২')
            .replaceAll('3', '৩')
            .replaceAll('4', '৪')
            .replaceAll('5', '৫')
            .replaceAll('6', '৬')
            .replaceAll('7', '৭')
            .replaceAll('8', '৮')
            .replaceAll('9', '৯');
      }
      return '$current';
    }

    final approxPanels = (_params.panelPmax > 0 && _params.peakSunHours > 0)
        ? (widget.dailyTotalWh /
                  (_params.peakSunHours * _params.panelPmax * 0.75))
              .ceil()
        : 1;

    final approxBatteries =
        (!isGridTied &&
            _params.batteryCapacityAh > 0 &&
            _params.batteryDod > 0 &&
            _params.batteryEfficiency > 0)
        ? (widget.dailyTotalWh *
                  _params.autonomyDays /
                  (_params.systemVoltage *
                      _params.batteryCapacityAh *
                      (_params.batteryDod / 100) *
                      (_params.batteryEfficiency / 100)))
              .ceil()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isBangla ? 'সিস্টেম প্যারামিটার' : 'System Parameters',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: TextButton.icon(
              onPressed: _handleLanguageToggle,
              icon: const Icon(
                Icons.translate_rounded,
                color: Colors.white,
                size: 15,
              ),
              label: Text(
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
        child: Column(
          children: [
            // ১. স্ক্রোলযোগ্য প্যারামিটার কনটেন্ট
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    _buildTactileSystemTypeSelector(isDark),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: _isBangla
                          ? '${getSecNum()}. সৌর বিকিরণ ও অবস্থান'
                          : '${getSecNum()}. Solar Radiation & Location',
                      icon: Icons.wb_sunny_rounded,
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSmartSlider(
                            label: _isBangla
                                ? 'পিক সান আওয়ার (সৌর-সময়)'
                                : 'Peak Sun Hours (PSH)',
                            value: _params.peakSunHours,
                            min: 2.0,
                            max: 8.0,
                            unit: 'h',
                            divisions: 60,
                            isDark: isDark,
                            onChanged: (v) => setState(
                              () => _params.peakSunHours = double.parse(
                                v.toStringAsFixed(1),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _isLoadingPsh
                                      ? (_isBangla
                                            ? 'নাসা থেকে তথ্য নেওয়া হচ্ছে...'
                                            : 'Fetching from NASA...')
                                      : (_pshResult?.getMessage(_isBangla) ??
                                            ''),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? AppColors.energyGreen
                                        : AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _isLoadingPsh
                                    ? null
                                    : _fetchNasaPshData,
                                icon: _isLoadingPsh
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: isDark
                                              ? AppColors.energyGreen
                                              : AppColors.primaryGreen,
                                        ),
                                      )
                                    : Icon(
                                        Icons.refresh_rounded,
                                        size: 22,
                                        color: isDark
                                            ? AppColors.energyGreen
                                            : AppColors.primaryGreen,
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isGridTied) ...[
                      _buildCard(
                        title: _isBangla
                            ? '${getSecNum()}. সিস্টেম ভোল্টেজ ও কন্ট্রোলার'
                            : '${getSecNum()}. Voltage & Controller',
                        icon: Icons.electric_bolt_rounded,
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [12.0, 24.0, 48.0].map((v) {
                                final isSelected = _params.systemVoltage == v;
                                final isRec = recommendedVoltage == v;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: InkWell(
                                      onTap: () => setState(
                                        () => _params.systemVoltage = v,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (isDark
                                                    ? const Color(0xFF064E3B)
                                                    : const Color(0xFFE8F5E9))
                                              : (isDark
                                                    ? const Color(0xFF0F172A)
                                                    : const Color(0xFFF1F5F9)),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.energyGreen
                                                : (isDark
                                                      ? const Color(0xFF334155)
                                                      : const Color(
                                                          0xFFCBD5E1,
                                                        )),
                                            width: isSelected ? 2.0 : 1.2,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.energyGreen
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              '${v.toInt()} V',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                color: isSelected
                                                    ? (isDark
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF047857,
                                                            ))
                                                    : (isDark
                                                          ? Colors.white70
                                                          : AppColors
                                                                .lightTextPrimary),
                                              ),
                                            ),
                                            if (isRec)
                                              Text(
                                                _isBangla
                                                    ? 'প্রস্তাবিত'
                                                    : 'Suggested',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isSelected
                                                      ? AppColors.solarGold
                                                      : AppColors.energyGreen,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (!isHybrid) ...[
                              Divider(
                                height: 26,
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                              Text(
                                _isBangla
                                    ? 'কন্ট্রোলারের ধরন (Technology):'
                                    : 'Controller Technology:',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildControllerTypeButton(
                                    type: 'mppt',
                                    title: 'MPPT (আধুনিক)',
                                    subtitle: _isBangla
                                        ? 'উচ্চ দক্ষতা (৯৮%)'
                                        : 'High Eff (98%)',
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildControllerTypeButton(
                                    type: 'pwm',
                                    title: 'PWM (সাধারণ)',
                                    subtitle: _isBangla
                                        ? 'বাজেট (৭০-৭৫%)'
                                        : 'Budget (75%)',
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildCard(
                      title: _isBangla
                          ? '${getSecNum()}. সোলার প্যানেল স্পেসিফিকেশন'
                          : '${getSecNum()}. Solar PV Specs',
                      icon: Icons.solar_power_rounded,
                      isDark: isDark,
                      action: IconButton(
                        icon: Icon(
                          Icons.help_outline_rounded,
                          color: isDark
                              ? AppColors.energyGreen
                              : AppColors.primaryGreen,
                          size: 22,
                        ),
                        onPressed: () => _showStickerHelpDialog(isDark),
                        tooltip: _isBangla
                            ? 'স্টিকার নির্দেশিকা'
                            : 'Specs Guide',
                      ),
                      child: Column(
                        children: [
                          _buildPresetChips(
                            items: _getRecommendedPanelPowers(),
                            selectedValue: _params.panelPmax,
                            unit: 'W',
                            isDark: isDark,
                            onSelected: (w) =>
                                _updatePanelParametersFromWatts(w),
                          ),
                          const SizedBox(height: 14),
                          _buildSmartSlider(
                            label: _isBangla
                                ? 'প্যানেল ওয়াট (Pmax)'
                                : 'Rated Power (Pmax)',
                            value: _params.panelPmax,
                            min: 20.0,
                            max: 700.0,
                            unit: 'Wp',
                            isDark: isDark,
                            onChanged: (v) => _updatePanelParametersFromWatts(
                              v.roundToDouble(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactMetricField(
                                  label: 'Voc',
                                  value: '${_params.panelVoc} V',
                                  isDark: isDark,
                                  onTap: () => _openDirectValueEditor(
                                    title: 'Voc (V)',
                                    currentValue: _params.panelVoc,
                                    min: 10.0,
                                    max: 70.0,
                                    isDark: isDark,
                                    onSubmitted: (val) =>
                                        setState(() => _params.panelVoc = val),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactMetricField(
                                  label: 'Imp',
                                  value: '${_params.panelImp} A',
                                  isDark: isDark,
                                  onTap: () => _openDirectValueEditor(
                                    title: 'Imp (A)',
                                    currentValue: _params.panelImp,
                                    min: 1.0,
                                    max: 30.0,
                                    isDark: isDark,
                                    onSubmitted: (val) =>
                                        setState(() => _params.panelImp = val),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactMetricField(
                                  label: 'Isc',
                                  value: '${_params.panelIsc} A',
                                  isDark: isDark,
                                  onTap: () => _openDirectValueEditor(
                                    title: 'Isc (A)',
                                    currentValue: _params.panelIsc,
                                    min: 1.0,
                                    max: 35.0,
                                    isDark: isDark,
                                    onSubmitted: (val) =>
                                        setState(() => _params.panelIsc = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isGridTied) ...[
                      _buildCard(
                        title: _isBangla
                            ? '${getSecNum()}. ব্যাটারি ব্যাংক কনফিগারেশন'
                            : '${getSecNum()}. Battery Bank Configuration',
                        icon: Icons.battery_charging_full_rounded,
                        isDark: isDark,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildBatteryTypeButton(
                                  'lead_acid',
                                  _isBangla ? 'লেড-এসিড' : 'Lead-Acid',
                                  isDark,
                                ),
                                const SizedBox(width: 6),
                                _buildBatteryTypeButton(
                                  'tubular',
                                  _isBangla ? 'টিউবুলার' : 'Tubular',
                                  isDark,
                                ),
                                const SizedBox(width: 6),
                                _buildBatteryTypeButton(
                                  'lithium',
                                  _isBangla ? 'লিথিয়াম' : 'Lithium',
                                  isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildPresetChips(
                              items: _getRecommendedBatteryCapacities(),
                              selectedValue: _params.batteryCapacityAh,
                              unit: 'Ah',
                              isDark: isDark,
                              onSelected: (ah) => setState(
                                () => _params.batteryCapacityAh = ah,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildSmartSlider(
                              label: _isBangla
                                  ? 'ব্যাটারি ক্যাপাসিটি'
                                  : 'Battery Capacity',
                              value: _params.batteryCapacityAh,
                              min: 20.0,
                              max: 400.0,
                              unit: 'Ah',
                              isDark: isDark,
                              onChanged: (v) => setState(
                                () => _params.batteryCapacityAh = v
                                    .roundToDouble(),
                              ),
                            ),
                            _buildSmartSlider(
                              label: _isBangla
                                  ? 'ব্যবহারের অংশ (DoD)'
                                  : 'Depth of Discharge (DoD)',
                              value: _params.batteryDod,
                              min: 20.0,
                              max: 95.0,
                              unit: '%',
                              isDark: isDark,
                              onChanged: (v) => setState(
                                () => _params.batteryDod = v.roundToDouble(),
                              ),
                            ),
                            _buildSmartSlider(
                              label: _isBangla
                                  ? 'ব্যাটারির কর্মক্ষমতা'
                                  : 'Battery Efficiency',
                              value: _params.batteryEfficiency,
                              min: 50.0,
                              max: 98.0,
                              unit: '%',
                              isDark: isDark,
                              onChanged: (v) => setState(
                                () => _params.batteryEfficiency = v
                                    .roundToDouble(),
                              ),
                            ),
                            _buildSmartSlider(
                              label: _isBangla
                                  ? 'মেঘলা দিন ব্যাকআপ'
                                  : 'Autonomy (Backup)',
                              value: _params.autonomyDays.toDouble(),
                              min: 1.0,
                              max: 5.0,
                              divisions: 4,
                              unit: _isBangla ? 'দিন' : 'Days',
                              isDark: isDark,
                              onChanged: (v) => setState(
                                () => _params.autonomyDays = v.toInt(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.acPeakWatt > 0 || isGridTied || isHybrid)
                      _buildCard(
                        title: _isBangla
                            ? (isGridTied
                                  ? '${getSecNum()}. অন-গ্রিড ইনভার্টার প্যারামিটার'
                                  : '${getSecNum()}. ইনভার্টার প্যারামিটার')
                            : '${getSecNum()}. Inverter Settings',
                        icon: Icons.sync_alt_rounded,
                        isDark: isDark,
                        child: Column(
                          children: [
                            _buildSmartSlider(
                              label: _isBangla
                                  ? 'কর্মক্ষমতা (Efficiency)'
                                  : 'Efficiency',
                              value: _params.inverterEfficiency,
                              min: 75.0,
                              max: 98.0,
                              unit: '%',
                              isDark: isDark,
                              onChanged: (v) => setState(
                                () => _params.inverterEfficiency = v
                                    .roundToDouble(),
                              ),
                            ),
                            _buildSmartSlider(
                              label: _isBangla
                                  ? 'পাওয়ার ফ্যাক্টর'
                                  : 'Power Factor',
                              value: _params.inverterPowerFactor,
                              min: 0.70,
                              max: 1.0,
                              divisions: 30,
                              unit: '',
                              isDark: isDark,
                              onChanged: (v) => setState(
                                () => _params.inverterPowerFactor =
                                    double.parse(v.toStringAsFixed(2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ২. নিচে থাকা ৩ডি ইঞ্জিনিয়ারিং কন্ট্রোল ডক (আলাদা বটম প্ল্যাটফর্ম)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF070D18)
                    : const Color(0xFFFFFFFF),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF10B981).withValues(alpha: 0.45)
                        : const Color(0xFF94A3B8).withValues(alpha: 0.7),
                    width: 1.6,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.75 : 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                  if (!isDark)
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 0,
                      offset: Offset(0, -1),
                    ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // কেপিআই ডিসপ্লে ডক
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickKPI(
                            label: _isBangla ? 'সিস্টেম' : 'Architecture',
                            value: isGridTied
                                ? 'On-Grid'
                                : (isHybrid
                                      ? 'Hybrid'
                                      : _params.controllerType.toUpperCase()),
                            icon: isGridTied
                                ? Icons.solar_power_rounded
                                : (isHybrid
                                      ? Icons.sync_alt_rounded
                                      : Icons.tune_rounded),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickKPI(
                            label: _isBangla ? 'প্যানেল সংখ্যা' : 'Est. Panels',
                            value: '~$approxPanels pcs',
                            icon: Icons.grid_view_rounded,
                            isDark: isDark,
                          ),
                        ),
                        if (!isGridTied) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickKPI(
                              label: _isBangla
                                  ? 'ব্যাটারি সংখ্যা'
                                  : 'Est. Batteries',
                              value: '~$approxBatteries pcs',
                              icon: Icons.battery_charging_full_rounded,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // প্রধান অ্যাকশন বাটন
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.energyGreen
                              : AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: isDark
                              ? AppColors.energyGreen.withValues(alpha: 0.5)
                              : const Color(0xFF063A24).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final double acWh = widget.dailyAcWh > 0
                              ? widget.dailyAcWh
                              : (widget.acPeakWatt > 0
                                    ? widget.dailyTotalWh
                                    : 0.0);
                          final double dcWh = widget.dailyDcWh > 0
                              ? widget.dailyDcWh
                              : (widget.acPeakWatt == 0
                                    ? widget.dailyTotalWh
                                    : 0.0);

                          final finalParams = _params.copyWith(
                            systemType: _selectedSystemType,
                          );

                          final result = SolarCalculationService.calculate(
                            dailyAcWh: acWh,
                            dailyDcWh: dcWh,
                            acPeakWatt: widget.acPeakWatt,
                            params: finalParams,
                          );

                          widget.onProceedToFinalResults(finalParams);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SystemCalculationSummaryScreen(
                                    result: result,
                                    params: finalParams,
                                    isBangla: _isBangla,
                                    onProceedToDiagram: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SystemDiagramScreen(
                                                result: result,
                                                params: finalParams,
                                                isBangla: _isBangla,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          _isBangla
                              ? 'পরবর্তী: চূড়ান্ত হিসাব ও ডায়াগ্রাম'
                              : 'Calculate & View Diagram',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTactileSystemTypeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 1.4,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isBangla
                ? 'সিস্টেম আর্কিটেকচার নির্বাচন করুন:'
                : 'Select System Architecture:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTypeCard(
                type: SolarSystemType.offGrid,
                title: _isBangla ? 'অফ-গ্রিড' : 'Off-Grid',
                subtitle: _isBangla ? 'ব্যাটারি + কন্ট্রোলার' : 'Battery + SCC',
                icon: Icons.power_off_rounded,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTypeCard(
                type: SolarSystemType.hybrid,
                title: _isBangla ? 'হাইব্রিড' : 'Hybrid',
                subtitle: _isBangla
                    ? 'অল-ইন-ওয়ান + গ্রিড'
                    : 'All-in-One + Grid',
                icon: Icons.sync_alt_rounded,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTypeCard(
                type: SolarSystemType.gridTied,
                title: _isBangla ? 'অন-গ্রিড' : 'On-Grid',
                subtitle: _isBangla
                    ? 'নেট-মিটার (ব্যাটারিহীন)'
                    : 'Net-Meter (No Bat)',
                icon: Icons.solar_power_rounded,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required SolarSystemType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedSystemType == type;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSystemType = type;
            if (type == SolarSystemType.hybrid) {
              _params.controllerType = 'mppt';
            }
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9))
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.energyGreen
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.energyGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.energyGreen
                    : (isDark ? Colors.white60 : Colors.grey.shade600),
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF047857))
                      : (isDark ? Colors.white70 : AppColors.lightTextPrimary),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (isDark
                            ? const Color(0xFF6EE7B7)
                            : AppColors.energyGreen)
                      : (isDark
                            ? const Color(0xFF64748B)
                            : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 1.4,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 0,
                  offset: Offset(0, -2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppColors.energyGreen
                                  : AppColors.primaryGreen)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isDark
                          ? AppColors.energyGreen
                          : AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildControllerTypeButton({
    required String type,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    final isSelected = _params.controllerType == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _params.controllerType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9))
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.energyGreen
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF047857))
                      : (isDark ? Colors.white70 : AppColors.lightTextPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isSelected
                      ? AppColors.energyGreen
                      : (isDark
                            ? const Color(0xFF64748B)
                            : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    int? divisions,
    required ValueChanged<double> onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            InkWell(
              onTap: () => _openDirectValueEditor(
                title: label,
                currentValue: value,
                min: min,
                max: max,
                onSubmitted: onChanged,
                isDark: isDark,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.energyGreen.withValues(alpha: 0.5)
                        : const Color(0xFFF59E0B),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  unit.isNotEmpty ? '$value $unit' : '$value',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppColors.energyGreen
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.energyGreen,
            inactiveTrackColor: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFCBD5E1),
            thumbColor: isDark ? AppColors.energyGreen : AppColors.primaryGreen,
            overlayColor: AppColors.energyGreen.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChips({
    required List<double> items,
    required double selectedValue,
    required String unit,
    required ValueChanged<double> onSelected,
    required bool isDark,
  }) {
    return Row(
      children: items.map((val) {
        final isSelected = selectedValue == val;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: ChoiceChip(
              label: Center(
                child: Text(
                  '${val.toInt()} $unit',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              selected: isSelected,
              selectedColor: isDark
                  ? AppColors.energyGreen
                  : AppColors.primaryGreen,
              backgroundColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
              showCheckmark: false,
              padding: EdgeInsets.zero,
              onSelected: (_) => onSelected(val),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBatteryTypeButton(String key, String label, bool isDark) {
    final isSelected = _selectedBatteryType == key;

    return Expanded(
      child: InkWell(
        onTap: () => _applyBatteryTypePreset(key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9))
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.energyGreen
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF047857))
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : AppColors.lightTextPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMetricField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : AppColors.lightTextSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickKPI({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: isDark ? AppColors.energyGreen : AppColors.primaryGreen,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
