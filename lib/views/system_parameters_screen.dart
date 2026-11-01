import 'package:flutter/material.dart';

import '../models/system_sizing_params.dart';
import '../services/solar_radiation_service.dart';
import '../services/solar_calculation_service.dart';
import 'system_calculation_summary_screen.dart';
import 'system_diagram_screen.dart';

class SystemParametersScreen extends StatefulWidget {
  final double dailyTotalWh;
  final double acPeakWatt;
  final double dailyAcWh; // 👈 নতুন যোগ করা হলো
  final double dailyDcWh; // 👈 নতুন যোগ করা হলো
  final bool isBangla;
  final VoidCallback onToggleLanguage;
  final Function(SystemSizingParams params) onProceedToFinalResults;

  const SystemParametersScreen({
    super.key,
    required this.dailyTotalWh,
    required this.acPeakWatt,
    this.dailyAcWh = 0.0, // ডিফল্ট ভ্যালু যাতে আগের কল না ভাঙে
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

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _params = SystemSizingParams.defaultForLoad(
      widget.dailyTotalWh,
      widget.acPeakWatt,
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

  void _showStickerHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF1B6A3B)),
            const SizedBox(width: 8),
            Text(
              _isBangla ? 'প্যানেল স্পেক্স নির্দেশিকা' : 'PV Specs Guide',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _isBangla ? 'বুঝেছি' : 'Got it',
              style: const TextStyle(
                color: Color(0xFF1B6A3B),
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
  }) {
    final controller = TextEditingController(text: currentValue.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF1B6A3B),
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
    final recommendedVoltage = _getRecommendedVoltage();

    final approxPanels = (_params.panelPmax > 0 && _params.peakSunHours > 0)
        ? ((widget.dailyTotalWh /
                  (_params.peakSunHours * _params.panelPmax * 0.75)))
              .ceil()
        : 1;

    final approxBatteries =
        (_params.batteryCapacityAh > 0 &&
            _params.batteryDod > 0 &&
            _params.batteryEfficiency > 0)
        ? ((widget.dailyTotalWh * _params.autonomyDays) /
                  (_params.systemVoltage *
                      _params.batteryCapacityAh *
                      (_params.batteryDod / 100) *
                      (_params.batteryEfficiency / 100)))
              .ceil()
        : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B6A3B),
        elevation: 0,
        title: Text(
          _isBangla ? 'সিস্টেম প্যারামিটার' : 'System Parameters',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _handleLanguageToggle,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  // ১. সৌর বিকিরণ ও অবস্থান
                  _buildCard(
                    title: _isBangla
                        ? '১. সৌর বিকিরণ ও অবস্থান'
                        : '1. Solar Radiation & Location',
                    icon: Icons.wb_sunny_rounded,
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
                                    : (_pshResult?.getMessage(_isBangla) ?? ''),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1B6A3B),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _isLoadingPsh
                                  ? null
                                  : _fetchNasaPshData,
                              icon: _isLoadingPsh
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh,
                                      size: 20,
                                      color: Color(0xFF1B6A3B),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ২. ডিসি বাস ভোল্টেজ ও চার্জ কন্ট্রোলার টাইপ
                  _buildCard(
                    title: _isBangla
                        ? '২. সিস্টেম ভোল্টেজ ও চার্জ কন্ট্রোলার'
                        : '2. Voltage & Charge Controller',
                    icon: Icons.electric_bolt_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ভোল্টেজ সিলেকশন
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
                                  onTap: () =>
                                      setState(() => _params.systemVoltage = v),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF1B6A3B)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1B6A3B)
                                            : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${v.toInt()} V',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
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
                                                  ? Colors.amberAccent
                                                  : const Color(0xFF1B6A3B),
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
                        const Divider(height: 24),
                        // কন্ট্রোলার টাইপ (MPPT / PWM)
                        Text(
                          _isBangla
                              ? 'কন্ট্রোলারের ধরন (Topology):'
                              : 'Controller Technology:',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildControllerTypeButton(
                              type: 'mppt',
                              title: 'MPPT (আধুনিক)',
                              subtitle: _isBangla
                                  ? 'উচ্চ দক্ষতা (৯৭-৯৯%)'
                                  : 'High Efficiency (98%)',
                            ),
                            const SizedBox(width: 8),
                            _buildControllerTypeButton(
                              type: 'pwm',
                              title: 'PWM (সাধারণ)',
                              subtitle: _isBangla
                                  ? 'বাজেট-বান্ধব (৭০-৭৫%)'
                                  : 'Budget (70-75%)',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ৩. সোলার প্যানেল স্পেসিফিকেশন (স্টিকার গাইড সহ)
                  _buildCard(
                    title: _isBangla
                        ? '৩. সোলার প্যানেল স্পেসিফিকেশন'
                        : '3. Solar PV Specs',
                    icon: Icons.solar_power_rounded,
                    action: IconButton(
                      icon: const Icon(
                        Icons.help_outline_rounded,
                        color: Color(0xFF1B6A3B),
                        size: 20,
                      ),
                      onPressed: _showStickerHelpDialog,
                      tooltip: _isBangla ? 'স্টিকার নির্দেশিকা' : 'Specs Guide',
                    ),
                    child: Column(
                      children: [
                        _buildPresetChips(
                          items: _getRecommendedPanelPowers(),
                          selectedValue: _params.panelPmax,
                          unit: 'W',
                          onSelected: (w) => _updatePanelParametersFromWatts(w),
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
                          onChanged: (v) => _updatePanelParametersFromWatts(
                            v.roundToDouble(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // স্টিকার ইনফো স্ট্রিপ
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Color(0xFF1B6A3B),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _isBangla
                                      ? 'প্যানেলের পেছনের স্টিকার অনুযায়ী মান পরিবর্তন করতে বক্সে ট্যাপ করুন।'
                                      : 'Tap on any parameter box below to enter values from panel sticker.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1B6A3B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactMetricField(
                                label: 'Voc',
                                value: '${_params.panelVoc} V',
                                onTap: () => _openDirectValueEditor(
                                  title: 'Voc (V)',
                                  currentValue: _params.panelVoc,
                                  min: 10.0,
                                  max: 70.0,
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
                                onTap: () => _openDirectValueEditor(
                                  title: 'Imp (A)',
                                  currentValue: _params.panelImp,
                                  min: 1.0,
                                  max: 30.0,
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
                                onTap: () => _openDirectValueEditor(
                                  title: 'Isc (A)',
                                  currentValue: _params.panelIsc,
                                  min: 1.0,
                                  max: 35.0,
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
                  const SizedBox(height: 14),

                  // ৪. ব্যাটারি ব্যাংক কনফিগারেশন
                  _buildCard(
                    title: _isBangla
                        ? '৪. ব্যাটারি ব্যাংক কনফিগারেশন'
                        : '4. Battery Bank Configuration',
                    icon: Icons.battery_charging_full_rounded,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildBatteryTypeButton(
                              'lead_acid',
                              _isBangla ? 'লেড-এসিড' : 'Lead-Acid',
                            ),
                            const SizedBox(width: 6),
                            _buildBatteryTypeButton(
                              'tubular',
                              _isBangla ? 'টিউবুলার' : 'Tubular',
                            ),
                            const SizedBox(width: 6),
                            _buildBatteryTypeButton(
                              'lithium',
                              _isBangla ? 'লিথিয়াম' : 'Lithium',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildPresetChips(
                          items: _getRecommendedBatteryCapacities(),
                          selectedValue: _params.batteryCapacityAh,
                          unit: 'Ah',
                          onSelected: (ah) =>
                              setState(() => _params.batteryCapacityAh = ah),
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
                          onChanged: (v) => setState(
                            () => _params.batteryCapacityAh = v.roundToDouble(),
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
                          onChanged: (v) => setState(
                            () => _params.batteryEfficiency = v.roundToDouble(),
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
                          onChanged: (v) =>
                              setState(() => _params.autonomyDays = v.toInt()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ৫. ইনভার্টার স্পেসিফিকেশন (যদি এসি লোড থাকে)
                  if (widget.acPeakWatt > 0)
                    _buildCard(
                      title: _isBangla
                          ? '৫. ইনভার্টার প্যারামিটার'
                          : '5. Inverter Settings',
                      icon: Icons.sync_alt_rounded,
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
                            onChanged: (v) => setState(
                              () => _params.inverterPowerFactor = double.parse(
                                v.toStringAsFixed(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // বটম সামারি বার
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickKPI(
                        label: _isBangla ? 'কন্ট্রোলার' : 'Controller',
                        value: _params.controllerType.toUpperCase(),
                        icon: Icons.tune_rounded,
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.grey.shade300,
                      ),
                      _buildQuickKPI(
                        label: _isBangla ? 'প্যানেল সংখ্যা' : 'Est. Panels',
                        value: '~$approxPanels pcs',
                        icon: Icons.solar_power,
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.grey.shade300,
                      ),
                      _buildQuickKPI(
                        label: _isBangla ? 'ব্যাটারি সংখ্যা' : 'Est. Batteries',
                        value: '~$approxBatteries pcs',
                        icon: Icons.battery_charging_full,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6A3B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        // ১. এসি ও ডিসি লোড নিখুঁতভাবে নেওয়া
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

                        // ২. ক্যালকুলেশন ইঞ্জিন কল
                        final result = SolarCalculationService.calculate(
                          dailyAcWh: acWh,
                          dailyDcWh: dcWh,
                          acPeakWatt: widget.acPeakWatt,
                          params: _params,
                        );

                        // ৩. নেভিগেশন (একদম সরাসরি এবং পরিষ্কার)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SystemCalculationSummaryScreen(
                                  result: result,
                                  params: _params,
                                  isBangla: _isBangla,
                                  onProceedToDiagram: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SystemDiagramScreen(
                                              result: result,
                                              params: _params,
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
                      ),
                      label: Text(
                        _isBangla
                            ? 'পরবর্তী: চূড়ান্ত হিসাব ও ডায়াগ্রাম'
                            : 'Calculate & View Diagram',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  Icon(icon, size: 20, color: const Color(0xFF1B6A3B)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Color(0xFF1B6A3B),
                    ),
                  ),
                ],
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildControllerTypeButton({
    required String type,
    required String title,
    required String subtitle,
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
                ? const Color(0xFF1B6A3B).withAlpha(20)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1B6A3B)
                  : Colors.grey.shade300,
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
                  color: isSelected ? const Color(0xFF1B6A3B) : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isSelected
                      ? const Color(0xFF1B6A3B)
                      : Colors.grey.shade600,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            InkWell(
              onTap: () => _openDirectValueEditor(
                title: label,
                currentValue: value,
                min: min,
                max: max,
                onSubmitted: onChanged,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1B6A3B).withAlpha(40),
                  ),
                ),
                child: Text(
                  unit.isNotEmpty ? '$value $unit' : '$value',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B6A3B),
                  ),
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF1B6A3B),
            inactiveTrackColor: const Color(0xFFE5E7EB),
            thumbColor: const Color(0xFF1B6A3B),
            overlayColor: const Color(0xFF1B6A3B).withAlpha(30),
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
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF1B6A3B),
              backgroundColor: const Color(0xFFF3F4F6),
              showCheckmark: false,
              padding: EdgeInsets.zero,
              onSelected: (_) => onSelected(val),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBatteryTypeButton(String key, String label) {
    final isSelected = _selectedBatteryType == key;
    return Expanded(
      child: InkWell(
        onTap: () => _applyBatteryTypePreset(key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1B6A3B).withAlpha(25)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF1B6A3B) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF1B6A3B) : Colors.black87,
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B6A3B)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
