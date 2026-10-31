import 'package:flutter/material.dart';

import '../models/system_sizing_params.dart';
import '../services/solar_radiation_service.dart';
import 'appliance_input_screen.dart'; // DragSpinInputField উইজেটের জন্য

class SystemParametersScreen extends StatefulWidget {
  final double dailyTotalWh;
  final double acPeakWatt;
  final bool isBangla;
  final VoidCallback onToggleLanguage;
  final Function(SystemSizingParams params) onProceedToFinalResults;

  const SystemParametersScreen({
    super.key,
    required this.dailyTotalWh,
    required this.acPeakWatt,
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

  // ব্যাটারির ধরন ট্র্যাকিং
  String _selectedBatteryType = 'lead_acid';

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    // লোড এবং পিক ওয়াট অনুসারে ডিফল্ট প্যারামিটার প্রস্তুত
    _params = SystemSizingParams.defaultForLoad(
      widget.dailyTotalWh,
      widget.acPeakWatt,
    );

    // লোডের ক্যাটাগরি অনুযায়ী প্রারম্ভিক প্যানেল ও ব্যাটারি সেট করা
    final recommendedPanels = _getRecommendedPanelPowers();
    final recommendedBatteries = _getRecommendedBatteryCapacities();

    _applyPanelPreset(recommendedPanels.first);
    _params.batteryCapacityAh = recommendedBatteries.first;

    _fetchNasaPshData();
  }

  // দৈনিক লোডের ওপর ভিত্তি করে উপযুক্ত প্যানেল পাওয়ার চিপস
  List<double> _getRecommendedPanelPowers() {
    if (widget.dailyTotalWh <= 800) {
      return [50.0, 80.0, 100.0, 150.0];
    } else if (widget.dailyTotalWh <= 2500) {
      return [150.0, 200.0, 250.0, 350.0];
    } else {
      return [350.0, 450.0, 550.0, 650.0];
    }
  }

  // দৈনিক লোডের ওপর ভিত্তি করে উপযুক্ত ব্যাটারি Ah চিপস
  List<double> _getRecommendedBatteryCapacities() {
    if (widget.dailyTotalWh <= 800) {
      return [40.0, 50.0, 80.0, 100.0];
    } else if (widget.dailyTotalWh <= 2500) {
      return [100.0, 130.0, 150.0, 200.0];
    } else {
      return [150.0, 200.0, 230.0, 260.0];
    }
  }

  // প্যানেল প্রিসেট মেথড (Wp পরিবর্তনের সাথে Voc, Imp, Isc স্বয়ংক্রিয় মান)
  void _applyPanelPreset(double power) {
    setState(() {
      _params.panelPmax = power;
      if (power == 50.0) {
        _params.panelVoc = 22.70;
        _params.panelImp = 2.63;
        _params.panelIsc = 2.83;
      } else if (power == 80.0) {
        _params.panelVoc = 22.40;
        _params.panelImp = 4.40;
        _params.panelIsc = 4.80;
      } else if (power == 100.0) {
        _params.panelVoc = 22.50;
        _params.panelImp = 5.50;
        _params.panelIsc = 5.90;
      } else if (power == 150.0) {
        _params.panelVoc = 22.70;
        _params.panelImp = 8.20;
        _params.panelIsc = 8.80;
      } else if (power == 200.0) {
        _params.panelVoc = 24.30;
        _params.panelImp = 9.80;
        _params.panelIsc = 10.40;
      } else if (power == 250.0) {
        _params.panelVoc = 37.50;
        _params.panelImp = 8.35;
        _params.panelIsc = 8.90;
      } else if (power == 350.0) {
        _params.panelVoc = 46.50;
        _params.panelImp = 9.10;
        _params.panelIsc = 9.70;
      } else if (power == 450.0) {
        _params.panelVoc = 49.30;
        _params.panelImp = 10.95;
        _params.panelIsc = 11.50;
      } else if (power == 550.0) {
        _params.panelVoc = 49.80;
        _params.panelImp = 13.15;
        _params.panelIsc = 13.95;
      } else if (power == 650.0) {
        _params.panelVoc = 51.20;
        _params.panelImp = 15.30;
        _params.panelIsc = 16.10;
      }
    });
  }

  // ব্যাটারি টাইপ প্রিসেট মেথড
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

  // নাসা ক্লাইমাটোলজি ডেটাবেজ থেকে সৌর-তথ্য সংগ্রহ
  Future<void> _fetchNasaPshData() async {
    setState(() {
      _isLoadingPsh = true;
    });

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
    setState(() {
      _isBangla = !_isBangla;
    });
    widget.onToggleLanguage();
  }

  // স্টিকার হেল্প পপআপ ডায়ালগ
  void _showStickerHelpDialog({
    required String title,
    required String description,
    required String parameterName,
    required String sampleValue,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Color(0xFF1B6A3B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(fontSize: 13.5, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade400, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isBangla
                        ? 'সোলার প্যানেলের পেছনের স্টিকারে লক্ষ্য করুন:'
                        : 'Look at the sticker behind solar panel:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.redAccent, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          parameterName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          sampleValue,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.redAccent,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _isBangla ? 'বুঝেছি' : 'Got it',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B6A3B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B6A3B),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isBangla ? 'সিস্টেম প্যারামিটার ইনপুট' : 'System Parameters Input',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton.icon(
              onPressed: _handleLanguageToggle,
              icon: const Icon(Icons.translate, color: Colors.white, size: 16),
              label: Text(
                _isBangla ? 'ENG' : 'বাংলা',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // লোড সামারি ব্যানার
            _buildLoadBanner(),
            const SizedBox(height: 12),

            // ১. সিস্টেম ও পরিবেশ (গ্রুপ ১)
            _buildSectionCard(
              title: _isBangla
                  ? '১. সিস্টেম ও পরিবেশ'
                  : '1. System & Environment',
              icon: Icons.settings_suggest,
              children: [
                _buildSystemVoltageSelector(),
                const SizedBox(height: 12),
                _buildPeakSunHoursInput(),
              ],
            ),
            const SizedBox(height: 14),

            // ২. সোলার প্যানেল স্পেসিফিকেশন (গ্রুপ ২)
            _buildSectionCard(
              title: _isBangla
                  ? '২. সোলার প্যানেল স্পেসিফিকেশন'
                  : '2. Solar PV Module Specs',
              icon: Icons.solar_power,
              children: [
                _buildFieldWithHelp(
                  label: _isBangla
                      ? 'প্যানেল পাওয়ার (Pmax)'
                      : 'Module Power (Pmax)',
                  unit: 'Wp',
                  value: _params.panelPmax,
                  step: 10.0,
                  min: 10.0,
                  max: 700.0,
                  onChanged: (v) => setState(() => _params.panelPmax = v),
                  onHelp: () => _showStickerHelpDialog(
                    title: _isBangla
                        ? 'প্যানেলের ক্ষমতা (Pmax)'
                        : 'Panel Power (Pmax)',
                    description: _isBangla
                        ? 'সোলার প্যানেলের পেছনে স্টিকারে প্যানেলের পাওয়ার লেখা থাকে। সেখানের “Pmax” এর সংখ্যাটা বসাতে হবে।'
                        : 'Look at the sticker on the back of the solar panel. Enter the value labeled "Pmax".',
                    parameterName: 'Maximum Power (Pmax)',
                    sampleValue: '50 Wp / 150 Wp',
                  ),
                ),
                const SizedBox(height: 6),

                // ডাইনামিক লোড-রেসপনসিভ পাওয়ার চিপস
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _getRecommendedPanelPowers().map((w) {
                      final isSelected = _params.panelPmax == w;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text('${w.toInt()} W'),
                          selected: isSelected,
                          selectedColor: const Color(0xFF1B6A3B).withAlpha(45),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF1B6A3B)
                                : Colors.black87,
                          ),
                          onSelected: (_) => _applyPanelPreset(w),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // ওপেন সার্কিট ভোল্টেজ (Voc)
                _buildFieldWithHelp(
                  label: _isBangla
                      ? 'ওপেন সার্কিট ভোল্টেজ (Voc)'
                      : 'Open Circuit Voltage (Voc)',
                  unit: 'V',
                  value: _params.panelVoc,
                  step: 0.5,
                  min: 10.0,
                  max: 65.0,
                  isDecimal: true,
                  onChanged: (v) => setState(() => _params.panelVoc = v),
                  onHelp: () => _showStickerHelpDialog(
                    title: _isBangla
                        ? 'প্যানেলের ভোল্টেজ (Voc)'
                        : 'Panel Voltage (Voc)',
                    description: _isBangla
                        ? 'সোলার প্যানেলের পেছনে স্টিকারে প্যানেলের ভোল্টেজ লেখা থাকে। সেখানের “Voc” এর সংখ্যাটা বসাতে হবে।'
                        : 'Enter the open circuit voltage labeled "Voc" from the back sticker of the panel.',
                    parameterName: 'Open Circuit Voltage (Voc)',
                    sampleValue: '22.70 V',
                  ),
                ),
                const SizedBox(height: 10),

                // প্রধান কারেন্ট (Imp)
                _buildFieldWithHelp(
                  label: _isBangla
                      ? 'প্রধান কারেন্ট (Imp)'
                      : 'Max Power Current (Imp)',
                  unit: 'A',
                  value: _params.panelImp,
                  step: 0.2,
                  min: 0.5,
                  max: 30.0,
                  isDecimal: true,
                  onChanged: (v) => setState(() => _params.panelImp = v),
                  onHelp: () => _showStickerHelpDialog(
                    title: _isBangla
                        ? 'প্রধান কারেন্ট (Imp)'
                        : 'Operating Current (Imp)',
                    description: _isBangla
                        ? 'সোলার প্যানেলের পেছনে স্টিকারে প্যানেলের প্রধান কারেন্ট লেখা থাকে। সেখানের “Imp” এর সংখ্যাটা বসাতে হবে।'
                        : 'Enter the operating current labeled "Imp" from the panel nameplate sticker.',
                    parameterName: 'Maximum Power Current (Imp)',
                    sampleValue: '2.63 A / 8.20 A',
                  ),
                ),
                const SizedBox(height: 10),

                // সর্বোচ্চ কারেন্ট (Isc)
                _buildFieldWithHelp(
                  label: _isBangla
                      ? 'সর্বোচ্চ কারেন্ট (Isc)'
                      : 'Short Circuit Current (Isc)',
                  unit: 'A',
                  value: _params.panelIsc,
                  step: 0.2,
                  min: 0.5,
                  max: 35.0,
                  isDecimal: true,
                  onChanged: (v) => setState(() => _params.panelIsc = v),
                  onHelp: () => _showStickerHelpDialog(
                    title: _isBangla
                        ? 'সর্বোচ্চ কারেন্ট (Isc)'
                        : 'Short Circuit Current (Isc)',
                    description: _isBangla
                        ? 'সোলার প্যানেলের পেছনে স্টিকারে প্যানেলের সর্বোচ্চ কারেন্ট লেখা থাকে। সেখানের “Isc” এর সংখ্যাটা বসাতে হবে।'
                        : 'Enter the short circuit current labeled "Isc" from the panel nameplate sticker.',
                    parameterName: 'Short Circuit Current (Isc)',
                    sampleValue: '2.83 A / 8.80 A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ৩. ব্যাটারি ব্যাংক স্পেসিফিকেশন (গ্রুপ ৩)
            _buildSectionCard(
              title: _isBangla
                  ? '৩. ব্যাটারি স্পেসিফিকেশন'
                  : '3. Battery Bank Specs',
              icon: Icons.battery_charging_full,
              children: [
                Text(
                  _isBangla
                      ? 'ব্যাটারির ধরন (Technology):'
                      : 'Battery Technology:',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text(_isBangla ? 'লেড-এসিড' : 'Lead-Acid'),
                      selected: _selectedBatteryType == 'lead_acid',
                      selectedColor: const Color(0xFF1B6A3B).withAlpha(45),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedBatteryType == 'lead_acid'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedBatteryType == 'lead_acid'
                            ? const Color(0xFF1B6A3B)
                            : Colors.black87,
                      ),
                      onSelected: (_) => _applyBatteryTypePreset('lead_acid'),
                    ),
                    ChoiceChip(
                      label: Text(
                        _isBangla ? 'টিউবুলার / জেল' : 'Tubular / Gel',
                      ),
                      selected: _selectedBatteryType == 'tubular',
                      selectedColor: const Color(0xFF1B6A3B).withAlpha(45),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedBatteryType == 'tubular'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedBatteryType == 'tubular'
                            ? const Color(0xFF1B6A3B)
                            : Colors.black87,
                      ),
                      onSelected: (_) => _applyBatteryTypePreset('tubular'),
                    ),
                    ChoiceChip(
                      label: Text(
                        _isBangla ? 'লিথিয়াম (LiFePO4)' : 'Lithium (LiFePO4)',
                      ),
                      selected: _selectedBatteryType == 'lithium',
                      selectedColor: const Color(0xFF1B6A3B).withAlpha(45),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedBatteryType == 'lithium'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedBatteryType == 'lithium'
                            ? const Color(0xFF1B6A3B)
                            : Colors.black87,
                      ),
                      onSelected: (_) => _applyBatteryTypePreset('lithium'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ব্যাটারির ধারণ ক্ষমতা (Ah)
                _buildFieldWithHelp(
                  label: _isBangla
                      ? 'ব্যাটারির ধারণ ক্ষমতা'
                      : 'Battery Capacity',
                  unit: 'Ah',
                  value: _params.batteryCapacityAh,
                  step: 10.0,
                  min: 20.0,
                  max: 500.0,
                  onChanged: (v) =>
                      setState(() => _params.batteryCapacityAh = v),
                  onHelp: () => _showStickerHelpDialog(
                    title: _isBangla
                        ? 'ধারণ ক্ষমতা (Ah)'
                        : 'Battery Capacity (Ah)',
                    description: _isBangla
                        ? 'দোকান হতে প্রাপ্ত ব্যাটারির গায়ের লেবেলে “--- AH” আকারে লেখা থাকে (যেমন: 100 Ah, 150 Ah)।'
                        : 'Check your battery side sticker for nominal capacity labeled in "--- AH" (e.g. 100 Ah, 200 Ah).',
                    parameterName: 'Nominal Capacity',
                    sampleValue: '100 Ah / 150 Ah',
                  ),
                ),
                const SizedBox(height: 6),

                // ডাইনামিক লোড-রেসপনসিভ ব্যাটারি Ah চিপস
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _getRecommendedBatteryCapacities().map((ah) {
                      final isSelected = _params.batteryCapacityAh == ah;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text('${ah.toInt()} Ah'),
                          selected: isSelected,
                          selectedColor: const Color(0xFF1B6A3B).withAlpha(45),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF1B6A3B)
                                : Colors.black87,
                          ),
                          onSelected: (_) =>
                              setState(() => _params.batteryCapacityAh = ah),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // ব্যাটারির কর্মক্ষমতা (%)
                _buildFieldWithHelp(
                  label: _isBangla
                      ? 'ব্যাটারির কর্মক্ষমতা'
                      : 'Battery Efficiency',
                  unit: '%',
                  value: _params.batteryEfficiency,
                  step: 1.0,
                  min: 50.0,
                  max: 98.0,
                  onChanged: (v) =>
                      setState(() => _params.batteryEfficiency = v),
                  onHelp: () => _showStickerHelpDialog(
                    title: _isBangla
                        ? 'ব্যাটারির কর্মক্ষমতা'
                        : 'Battery Efficiency',
                    description: _isBangla
                        ? 'চার্জ/রিচার্জ চক্রে ক্ষতির পরিমাপই ব্যাটারি দক্ষতা। লেড-এসিড ব্যাটারিতে প্রায় ৮০%, টিউবুলার ব্যাটারিতে ৮৫% এবং লিথিয়াম ব্যাটারিতে প্রায় ৯৫% দক্ষতা পাওয়া যায়।'
                        : 'Efficiency measures energy recovery in charge/discharge cycles. Lead-acid is ~80%, tubular is ~85%, and lithium achieves ~95%.',
                    parameterName: 'Cycle Efficiency',
                    sampleValue: '80 % / 95 %',
                  ),
                ),
                const SizedBox(height: 10),

                // ব্যবহারের অংশ (DoD %)
                _buildFieldWithHelp(
                  label: _isBangla
                      ? 'ব্যবহারের অংশ (DoD)'
                      : 'Depth of Discharge (DoD)',
                  unit: '%',
                  value: _params.batteryDod,
                  step: 5.0,
                  min: 20.0,
                  max: 95.0,
                  onChanged: (v) => setState(() => _params.batteryDod = v),
                  onHelp: () => _showStickerHelpDialog(
                    title: _isBangla
                        ? 'ডেপ্থ অব ডিসচার্জ (DoD)'
                        : 'Depth of Discharge (DoD)',
                    description: _isBangla
                        ? 'সাধারণ লেড-এসিড ব্যাটারির প্রায় ৭০% পর্যন্ত ডিসচার্জ করা যায়। ডিপ সাইকেল ব্যাটারি দীর্ঘায়ু করতে প্রায় ৫০% রাখা হয় এবং লিথিয়াম ব্যাটারি ৮০-৯০% পর্যন্ত নিরাপদ।'
                        : 'Indicates how deeply the battery can be safely drained. Standard lead-acid is ~70% DoD, deep-cycle tubular is ~50%, and lithium safely allows 80-90%.',
                    parameterName: 'Depth of Discharge',
                    sampleValue: '70 % / 50 % / 85 %',
                  ),
                ),
                const SizedBox(height: 10),

                // মেঘলা দিনের ব্যাকআপ
                _buildFieldWithHelp(
                  label: _isBangla
                      ? 'মেঘলা দিনের ব্যাকআপ'
                      : 'Autonomy Days (Backup)',
                  unit: _isBangla ? 'দিন' : 'Days',
                  value: _params.autonomyDays.toDouble(),
                  step: 1.0,
                  min: 1.0,
                  max: 7.0,
                  onChanged: (v) =>
                      setState(() => _params.autonomyDays = v.toInt()),
                  onHelp: () => _showStickerHelpDialog(
                    title: _isBangla
                        ? 'মেঘলা দিন (Autonomy Days)'
                        : 'Days of Autonomy',
                    description: _isBangla
                        ? 'মেঘলা বা বর্ষার দিনে রোদ না থাকলে ব্যাটারি ব্যাকআপ দেয়। সাধারণত ২ থেকে ৩ দিনের জন্য ব্যাকআপ রাখা হয়।'
                        : 'Number of consecutive cloudy/rainy days the battery can supply power without solar input. Typical is 2 to 3 days.',
                    parameterName: 'Days of Autonomy',
                    sampleValue: '2 Days',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ৪. ইনভার্টার স্পেসিফিকেশন (শুধুমাত্র এসি লোড থাকলেই প্রদর্শিত হবে)
            if (widget.acPeakWatt > 0) ...[
              _buildSectionCard(
                title: _isBangla
                    ? '৪. ইনভার্টার স্পেসিফিকেশন'
                    : '4. Inverter Specifications',
                icon: Icons.power_input,
                children: [
                  _buildFieldWithHelp(
                    label: _isBangla
                        ? 'ইনভার্টারের কর্মক্ষমতা'
                        : 'Inverter Efficiency',
                    unit: '%',
                    value: _params.inverterEfficiency,
                    step: 1.0,
                    min: 70.0,
                    max: 98.0,
                    onChanged: (v) =>
                        setState(() => _params.inverterEfficiency = v),
                    onHelp: () => _showStickerHelpDialog(
                      title: _isBangla
                          ? 'ইনভার্টার কর্মক্ষমতা'
                          : 'Inverter Efficiency',
                      description: _isBangla
                          ? 'ইনভার্টারের কর্মক্ষমতা সাধারণত ৯০% বা তার বেশি হয়ে থাকে। এটি ইনভার্টারের পেছনের নেমপ্লেটে লেখা থাকে।'
                          : 'Inverter operating efficiency is usually 90% or higher, specified on its technical plate.',
                      parameterName: 'Rated Efficiency',
                      sampleValue: '90 %',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFieldWithHelp(
                    label: _isBangla ? 'পাওয়ার ফ্যাক্টর' : 'Power Factor (PF)',
                    unit: '',
                    value: _params.inverterPowerFactor,
                    step: 0.05,
                    min: 0.60,
                    max: 1.0,
                    isDecimal: true,
                    onChanged: (v) =>
                        setState(() => _params.inverterPowerFactor = v),
                    onHelp: () => _showStickerHelpDialog(
                      title: _isBangla ? 'পাওয়ার ফ্যাক্টর' : 'Power Factor',
                      description: _isBangla
                          ? 'সক্রিয় শক্তি ও আপাত শক্তির অনুপাত। স্থানীয় বাজারে প্রাপ্ত ইনভার্টারের পাওয়ার ফ্যাক্টর সাধারণত ০.৮০ থেকে ০.৮৫ হয়ে থাকে।'
                          : 'Ratio of real to apparent power. Commercially available inverters generally have PF around 0.80 to 0.85.',
                      parameterName: 'Power Factor',
                      sampleValue: '0.85',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 10),

            // চূড়ান্ত সাইজিং ক্যালকুলেশন বাটন
            ElevatedButton.icon(
              onPressed: () => widget.onProceedToFinalResults(_params),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B6A3B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.calculate, color: Colors.white),
              label: Text(
                _isBangla
                    ? 'চূড়ান্ত সাইজিং ফলাফল দেখুন →'
                    : 'Calculate System Sizing →',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // লোড সামারি ব্যানার
  Widget _buildLoadBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B6A3B).withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1B6A3B).withAlpha(60)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isBangla ? 'মোট দৈনিক লোড:' : 'Total Daily Load:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            '${widget.dailyTotalWh.toStringAsFixed(1)} Wh/day',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1B6A3B),
            ),
          ),
        ],
      ),
    );
  }

  // কার্ড কন্টেইনার
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1B6A3B), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B6A3B),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  // লোড অনুযায়ী স্বয়ংক্রিয় প্রস্তাবিত ভোল্টেজ নির্ধারণ
  double _getRecommendedVoltage() {
    if (widget.dailyTotalWh <= 1500 && widget.acPeakWatt <= 1000) {
      return 12.0;
    } else if (widget.dailyTotalWh <= 3000 && widget.acPeakWatt <= 2500) {
      return 24.0;
    } else {
      return 48.0;
    }
  }

  Widget _buildSystemVoltageSelector() {
    final double recommended = _getRecommendedVoltage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isBangla ? 'সিস্টেম ভোল্টেজ (V)' : 'System Voltage (V)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.blueGrey,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showStickerHelpDialog(
                title: _isBangla
                    ? 'সিস্টেম ভোল্টেজ নির্দেশিকা'
                    : 'System Voltage Guide',
                description: _isBangla
                    ? '• ১২ V: দৈনিক ১৫০০ Wh বা ১০০০ W লোড পর্যন্ত।\n'
                          '• ২৪ V: দৈনিক ১৫০০ ~ ৩০০০ Wh বা ১০০০ ~ ২৫০০ W লোডের জন্য।\n'
                          '• ৪৮ V: দৈনিক ৩০০০ Wh বা ২৫০০ W-এর বেশি লোডের জন্য।\n\n'
                          'উচ্চ ক্ষমতায় উচ্চ ভোল্টেজ গ্রহণ করলে তারের কারেন্ট (I = P/V) ও অপচয় সর্বনিম্ন থাকে।'
                    : '• 12 V: Up to 1500 Wh/day or <= 1000 W peak load.\n'
                          '• 24 V: 1500 ~ 3000 Wh/day or 1000 ~ 2500 W load.\n'
                          '• 48 V: > 3000 Wh/day or > 2500 W high load.\n\n'
                          'Higher voltage minimizes cable amperage and system heat losses.',
                parameterName: 'Recommended DC Bus',
                sampleValue: '${recommended.toInt()} V',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          children: [12.0, 24.0, 48.0].map((v) {
            final isSelected = _params.systemVoltage == v;
            final isRecommended = recommended == v;

            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${v.toInt()} V'),
                  if (isRecommended) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 14, color: Color(0xFFD97706)),
                  ],
                ],
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF1B6A3B).withAlpha(45),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF1B6A3B) : Colors.black87,
              ),
              onSelected: (val) {
                if (val) setState(() => _params.systemVoltage = v);
              },
            );
          }).toList(),
        ),
        if (_params.systemVoltage < recommended) ...[
          const SizedBox(height: 6),
          Text(
            _isBangla
                ? '⚠️ আপনার লোডের জন্য ${_params.systemVoltage.toInt()}V-এ তারের কারেন্ট অনেক বেশি হবে। ${recommended.toInt()}V ব্যবহারের সুপারিশ করা হচ্ছে।'
                : '⚠️ For this load, ${_params.systemVoltage.toInt()}V requires very thick cables. ${recommended.toInt()}V is recommended.',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFFD97706),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  // সৌর সময় ও নাসা লোকেশন ইনপুট
  Widget _buildPeakSunHoursInput() {
    String displayMessage = '';
    if (_isLoadingPsh) {
      displayMessage = _isBangla
          ? 'নাসা (NASA) ডেটাবেজ হতে সৌর-তথ্য খোঁজা হচ্ছে...'
          : 'Fetching solar data from NASA database...';
    } else if (_pshResult != null) {
      displayMessage = _pshResult!.getMessage(_isBangla);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DragSpinInputField(
                label: _isBangla
                    ? 'গড়পড়তা সৌর-সময় (ঘণ্টা)'
                    : 'Peak Sun Hours (h)',
                value: _params.peakSunHours,
                step: 0.1,
                min: 1.0,
                max: 10.0,
                isDecimal: true,
                onChanged: (v) => setState(() => _params.peakSunHours = v),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isLoadingPsh
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFF1B6A3B)),
              tooltip: _isBangla
                  ? 'নাসা থেকে রিফ্রেশ করুন'
                  : 'Refresh from NASA',
              onPressed: _isLoadingPsh ? null : _fetchNasaPshData,
            ),
          ],
        ),
        if (displayMessage.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            displayMessage,
            style: TextStyle(
              fontSize: 11,
              color: _isLoadingPsh
                  ? Colors.blue.shade800
                  : Colors.teal.shade800,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  // ফিল্ডের সাথে হেল্প আইকন বাটন
  Widget _buildFieldWithHelp({
    required String label,
    required String unit,
    required double value,
    required double step,
    required double min,
    required double max,
    bool isDecimal = false,
    required ValueChanged<double> onChanged,
    required VoidCallback onHelp,
  }) {
    return Row(
      children: [
        Expanded(
          child: DragSpinInputField(
            label: unit.isNotEmpty ? '$label ($unit)' : label,
            value: value,
            step: step,
            min: min,
            max: max,
            isDecimal: isDecimal,
            onChanged: onChanged,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.help_outline,
            color: Colors.blueGrey,
            size: 20,
          ),
          tooltip: _isBangla ? 'নির্দেশনা দেখুন' : 'View Guide',
          onPressed: onHelp,
        ),
      ],
    );
  }
}
