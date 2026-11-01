import 'package:flutter/material.dart';

import '../models/solar_calculation_result.dart';
import '../models/system_sizing_params.dart';
import 'system_diagram_screen.dart';

class SystemCalculationSummaryScreen extends StatefulWidget {
  final SolarCalculationResult result;
  final SystemSizingParams params;
  final bool isBangla;
  final VoidCallback onProceedToDiagram;

  const SystemCalculationSummaryScreen({
    super.key,
    required this.result,
    required this.params,
    this.isBangla = true,
    required this.onProceedToDiagram,
  });

  @override
  State<SystemCalculationSummaryScreen> createState() =>
      _SystemCalculationSummaryScreenState();
}

class _SystemCalculationSummaryScreenState
    extends State<SystemCalculationSummaryScreen> {
  late bool _isBangla;
  bool _showPvDetails = false;
  bool _showBatteryDetails = false;
  bool _showProtectionDetails = false;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
  }

  void _toggleLanguage() {
    setState(() {
      _isBangla = !_isBangla;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final params = widget.params;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B6A3B),
        elevation: 0,
        title: Text(
          _isBangla ? 'সিস্টেম ক্যালকুলেশন সামারি' : 'System Sizing Summary',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleLanguage,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ১. মোট চাহিদা কার্ড
                  _buildDemandHeaderCard(result, params),
                  const SizedBox(height: 14),

                  // ২. সোলার পিভি অ্যারে কার্ড (প্রোগ্রেসিভ ডিসক্লোজার)
                  _buildPvArrayCard(result, params),
                  const SizedBox(height: 14),

                  // ৩. ব্যাটারি ব্যাংক কার্ড (প্রোগ্রেসিভ ডিসক্লোজার)
                  _buildBatteryBankCard(result, params),
                  const SizedBox(height: 14),

                  // ৪. পাওয়ার ইলেকট্রনিক্স কার্ড (বিশুদ্ধ সাইন ওয়েভ উল্লেখসহ)
                  _buildPowerElectronicsCard(result),
                  const SizedBox(height: 14),

                  // ৫. 🛡️ সুরক্ষাব্যবস্থা ও তারের সাইজ কার্ড (নতুন যুক্ত)
                  _buildProtectionAndCablesCard(result),
                  const SizedBox(height: 14),

                  // ৬. সিস্টেম রিক্যাপ কার্ড
                  _buildSystemSpecsRecapCard(result, params),
                ],
              ),
            ),
          ),

          // নিচে ওয়্যারিং ডায়াগ্রামের অ্যাকশন বাটন
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B6A3B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed:
                      widget.onProceedToDiagram, // 👈 সরাসরি কলব্যাক কল হবে
                  icon: const Icon(
                    Icons.account_tree_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isBangla ? 'সংযোগ ডায়াগ্রাম দেখুন' : 'View Wiring Diagram',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandHeaderCard(
    SolarCalculationResult result,
    SystemSizingParams params,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6A3B), Color(0xFF2E8B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B6A3B).withAlpha(60),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'দৈনিক মোট শক্তি চাহিদা'
                    : 'Total Daily Energy Load',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${params.systemVoltage.toInt()}V DC Bus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                result.totalDailyWh.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Wh/day',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '≈ ${result.energyDemandAh.toStringAsFixed(1)} Ah/day',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (result.hasAcLoad && result.hasDcLoad) ...[
            const SizedBox(height: 10),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AC: ${result.dailyAcWh.toStringAsFixed(0)} Wh',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  'DC: ${result.dailyDcWh.toStringAsFixed(0)} Wh',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPvArrayCard(
    SolarCalculationResult result,
    SystemSizingParams params,
  ) {
    return _buildSectionCard(
      title: _isBangla ? 'সোলার পিভি অ্যারে' : 'Solar PV Array',
      icon: Icons.solar_power_rounded,
      highlightText: '${result.totalArrayWatt.toInt()} Wp',
      children: [
        _buildHighlightBadge(
          title: _isBangla ? 'প্রয়োজনীয় মোট প্যানেল' : 'Required Solar Panels',
          value:
              '${result.totalPanels} ${_isBangla ? "টি" : "pcs"} (${params.panelPmax.toInt()} Wp)',
          icon: Icons.view_module_rounded,
        ),
        const SizedBox(height: 8),
        _buildSimpleConnectionBadge(
          text: _isBangla
              ? 'সংযোগ বিন্যাস: প্রতি সারিতে ${result.panelsSeries}টি করে মোট ${result.panelsParallel}টি সারি'
              : 'Wiring: ${result.panelsSeries} in Series × ${result.panelsParallel} Strings Parallel',
        ),
        _buildDisclosureToggle(
          isExpanded: _showPvDetails,
          onTap: () => setState(() => _showPvDetails = !_showPvDetails),
        ),
        if (_showPvDetails) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla ? 'সিরিজ সংযোগ (PVs)' : 'Series (PVs)',
                  value: '${result.panelsSeries} ${_isBangla ? "টি" : "Units"}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla
                      ? 'প্যারালাল স্ট্রিং (PVp)'
                      : 'Parallel (PVp)',
                  value:
                      '${result.panelsParallel} ${_isBangla ? "স্ট্রিং" : "Strings"}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: 'Array Vmp / Voc',
                  value:
                      '${result.arrayVmp.toStringAsFixed(1)}V / ${result.arrayVoc.toStringAsFixed(1)}V',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailMetric(
                  label: 'Array Imp / Isc',
                  value:
                      '${result.arrayImp.toStringAsFixed(1)}A / ${result.arrayIsc.toStringAsFixed(1)}A',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBatteryBankCard(
    SolarCalculationResult result,
    SystemSizingParams params,
  ) {
    return _buildSectionCard(
      title: _isBangla ? 'ব্যাটারি স্টোরেজ ব্যাংক' : 'Battery Storage Bank',
      icon: Icons.battery_charging_full_rounded,
      highlightText:
          '${result.batteryCapacityAh.toStringAsFixed(0)} Ah (${params.systemVoltage.toInt()}V)',
      children: [
        _buildHighlightBadge(
          title: _isBangla ? 'প্রয়োজনীয় ব্যাটারি' : 'Total Batteries Required',
          value:
              '${result.totalBatteries} ${_isBangla ? "টি" : "pcs"} (${params.batteryCapacityAh.toInt()} Ah @ 12V)',
          icon: Icons.layers_rounded,
        ),
        const SizedBox(height: 8),
        _buildSimpleConnectionBadge(
          text: _isBangla
              ? 'ব্যাকআপ স্থায়িত্ব: ${params.autonomyDays} দিন (মেঘলা আকাশ)'
              : 'Backup Autonomy: ${params.autonomyDays} Day(s) (Cloudy weather)',
        ),
        _buildDisclosureToggle(
          isExpanded: _showBatteryDetails,
          onTap: () =>
              setState(() => _showBatteryDetails = !_showBatteryDetails),
        ),
        if (_showBatteryDetails) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla ? 'সিরিজে ব্যাটারি (Bs)' : 'Series (Bs)',
                  value:
                      '${result.batteriesSeries} ${_isBangla ? "টি" : "Units"}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla
                      ? 'প্যারালালে স্ট্রিং (Bp)'
                      : 'Parallel (Bp)',
                  value:
                      '${result.batteriesParallel} ${_isBangla ? "স্ট্রিং" : "Strings"}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: 'Depth of Discharge (DoD)',
                  value: '${params.batteryDod.toInt()}%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla
                      ? 'ব্যাটারি এফিসিয়েন্সি'
                      : 'Battery Efficiency',
                  value: '${params.batteryEfficiency.toInt()}%',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPowerElectronicsCard(SolarCalculationResult result) {
    return _buildSectionCard(
      title: _isBangla
          ? 'পাওয়ার ইলেকট্রনিক্স রেটিং'
          : 'Power Electronics Specs',
      icon: Icons.settings_input_component_rounded,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B6A3B).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF1B6A3B),
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
                          ? 'সোলার চার্জ কন্ট্রোলার'
                          : 'Solar Charge Controller',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${result.controllerVoltage.toInt()}V, ≥ ${result.controllerAmpere.toInt()}A (${result.controllerType.toUpperCase()})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (result.hasAcLoad) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B6A3B).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sync_alt_rounded,
                    color: Color(0xFF1B6A3B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isBangla
                                ? 'অফ-গ্রিড ইনভার্টার ক্যাপাসিটি'
                                : 'Off-grid Inverter Capacity',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B6A3B).withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Pure Sine Wave',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B6A3B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${result.inverterVoltage.toInt()}V DC to 220V AC, ≥ ${result.inverterCapacityVa.toInt()} VA',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 🛡️ সুরক্ষাব্যবস্থা ও তারের সাইজ কার্ড
  Widget _buildProtectionAndCablesCard(SolarCalculationResult result) {
    return _buildSectionCard(
      title: _isBangla
          ? 'সুরক্ষাব্যবস্থা ও ওয়্যারিং ক্যাবল'
          : 'Protection & Wiring Cables',
      icon: Icons.security_rounded,
      children: [
        // প্রোগ্রেসিভ ডিসক্লোজার টগল বাটন
        _buildDisclosureToggle(
          isExpanded: _showProtectionDetails,
          onTap: () =>
              setState(() => _showProtectionDetails = !_showProtectionDetails),
        ),

        // ব্যবহারকারী ট্যাপ করলে বিস্তারিত প্যারামিটার প্রদর্শিত হবে
        if (_showProtectionDetails) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla
                      ? 'পিভি ডিসি ব্রেকার (DC MCB)'
                      : 'PV Array DC Breaker',
                  value: '≥ ${result.pvBreakerAmp.toInt()} A',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla ? 'ব্যাটারি ডিসি ফিউজ' : 'Battery DC Fuse',
                  value: '≥ ${result.batteryFuseAmp.toInt()} A',
                ),
              ),
            ],
          ),
          if (result.hasAcLoad) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailMetric(
                    label: _isBangla
                        ? 'ইনভার্টার এসি ব্রেকার'
                        : 'AC Output Breaker',
                    value: '≥ ${result.acBreakerAmp.toInt()} A (220V)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDetailMetric(
                    label: _isBangla
                        ? 'কন্ট্রোলার-ব্যাটারি ব্রেকার'
                        : 'SCC Battery Breaker',
                    value: '≥ ${result.chargeControllerBreakerAmp.toInt()} A',
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla
                      ? 'পিভি তারের মাপ (কপার)'
                      : 'PV Array Cable Size',
                  value: result.pvCableSizeMm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailMetric(
                  label: _isBangla
                      ? 'ব্যাটারি তারের মাপ'
                      : 'Battery Cable Size',
                  value: result.batteryCableSizeMm,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSystemSpecsRecapCard(
    SolarCalculationResult result,
    SystemSizingParams params,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B6A3B).withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF1B6A3B),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isBangla
                  ? 'আপনার দৈনিক ${result.totalDailyWh.toStringAsFixed(0)} Wh চাহিদার জন্য মোট ${result.totalPanels}টি ${params.panelPmax.toInt()}Wp প্যানেল এবং ${result.totalBatteries}টি ${params.batteryCapacityAh.toInt()}Ah ব্যাটারির এই কনফিগারেশনটি সুপারিশ করা হলো।'
                  : 'For your daily ${result.totalDailyWh.toStringAsFixed(0)} Wh load, a balanced system of ${result.totalPanels}x ${params.panelPmax.toInt()}Wp panels and ${result.totalBatteries}x ${params.batteryCapacityAh.toInt()}Ah batteries is recommended.',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1B6A3B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? highlightText,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
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
              if (highlightText != null)
                Text(
                  highlightText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1B6A3B),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHighlightBadge({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1B6A3B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B6A3B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleConnectionBadge({required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.hub_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclosureToggle({
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isExpanded
                  ? (_isBangla ? 'কারিগরি তথ্য লুকান' : 'Hide Technical Specs')
                  : (_isBangla
                        ? 'বিস্তারিত কারিগরি স্পেসিফিকেশন দেখুন'
                        : 'Show Technical Specs'),
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF1B6A3B),
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
              color: const Color(0xFF1B6A3B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailMetric({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
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
    );
  }
}
