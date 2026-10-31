import 'package:flutter/material.dart';

import '../models/appliance_item.dart';
import '../models/appliance_presets.dart';

class ApplianceInputScreen extends StatefulWidget {
  final CategoryConfig category;
  final List<ApplianceItem> existingItems;
  final bool isBangla;

  const ApplianceInputScreen({
    super.key,
    required this.category,
    required this.existingItems,
    required this.isBangla,
  });

  @override
  State<ApplianceInputScreen> createState() => _ApplianceInputScreenState();
}

class _ApplianceInputScreenState extends State<ApplianceInputScreen> {
  late List<ApplianceItem> _currentItems;

  @override
  void initState() {
    super.initState();
    _currentItems = widget.existingItems
        .map(
          (item) => ApplianceItem(
            id: item.id,
            categoryKey: item.categoryKey,
            nameBn: item.nameBn,
            nameEn: item.nameEn,
            isAC: item.isAC,
            watt: item.watt,
            quantity: item.quantity,
            hoursPerDay: item.hoursPerDay,
          ),
        )
        .toList();

    if (_currentItems.isEmpty && widget.category.presets.isNotEmpty) {
      _addNewItem();
    }
  }

  void _addNewItem() {
    final defaultPreset = widget.category.presets.first;
    setState(() {
      _currentItems.add(
        ApplianceItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          categoryKey: widget.category.key,
          nameBn: defaultPreset.nameBn,
          nameEn: defaultPreset.nameEn,
          isAC: defaultPreset.defaultIsAC,
          watt: defaultPreset.defaultWatt,
          quantity: 1,
          hoursPerDay: 4.0,
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _currentItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isBangla
        ? widget.category.titleBn
        : widget.category.titleEn;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B6A3B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _currentItems),
        ),
        title: Row(
          children: [
            Image.asset(
              widget.category.svgPath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.devices, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              widget.isBangla ? '$title ইনপুট' : '$title Input',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentItems.length,
              itemBuilder: (context, index) {
                return _buildItemCard(index);
              },
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _addNewItem,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B6A3B),
                side: const BorderSide(color: Color(0xFF1B6A3B), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: Text(
                widget.isBangla ? '+ আরও উপকরণ যোগ করুন' : '+ Add Another Item',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildGuidelineCard(),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _currentItems);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B6A3B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: Text(
                widget.isBangla ? 'সংরক্ষণ করুন ও ফিরুন' : 'Save & Return',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _currentItems[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // হেডার: প্রিসেট নির্বাচন এবং ডিলিট বাটন
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.isBangla ? item.nameBn : item.nameEn,
                    decoration: InputDecoration(
                      labelText: widget.isBangla
                          ? 'আইটেম নির্বাচন'
                          : 'Select Item',
                      labelStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: widget.category.presets.map((preset) {
                      final pName = widget.isBangla
                          ? preset.nameBn
                          : preset.nameEn;
                      return DropdownMenuItem<String>(
                        value: pName,
                        child: Text(
                          pName,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final selectedPreset = widget.category.presets.firstWhere(
                        (p) => (widget.isBangla ? p.nameBn : p.nameEn) == val,
                      );
                      setState(() {
                        item.nameBn = selectedPreset.nameBn;
                        item.nameEn = selectedPreset.nameEn;
                        item.watt = selectedPreset.defaultWatt;
                        item.isAC = selectedPreset.defaultIsAC;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                  tooltip: widget.isBangla ? 'মুছুন' : 'Delete',
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ইনপুট রো: উৎস (AC/DC) এবং ওয়াট (Watt)
            Row(
              children: [
                // উৎস (AC/DC)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isBangla ? 'উৎস (Source)' : 'Source',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('AC'),
                            selected: item.isAC,
                            selectedColor: Colors.blue.shade100,
                            onSelected: (selected) {
                              if (selected) setState(() => item.isAC = true);
                            },
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('DC'),
                            selected: !item.isAC,
                            selectedColor: Colors.green.shade100,
                            onSelected: (selected) {
                              if (selected) setState(() => item.isAC = false);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ওয়াট (Drag / Type)
                Expanded(
                  child: DragSpinInputField(
                    label: widget.isBangla ? 'ওয়াট (W)' : 'Power (W)',
                    value: item.watt,
                    step: 5.0,
                    min: 1.0,
                    max: 5000.0,
                    isDecimal: false,
                    onChanged: (val) {
                      setState(() {
                        item.watt = val;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ইনপুট রো: পরিমাণ এবং দৈনিক ব্যবহার
            Row(
              children: [
                // পরিমাণ (Drag / Type)
                Expanded(
                  child: DragSpinInputField(
                    label: widget.isBangla ? 'পরিমাণ (সংখ্যা)' : 'Quantity',
                    value: item.quantity.toDouble(),
                    step: 1.0,
                    min: 1.0,
                    max: 100.0,
                    isDecimal: false,
                    onChanged: (val) {
                      setState(() {
                        item.quantity = val.toInt();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // দৈনিক ব্যবহার (Drag / Type)
                Expanded(
                  child: DragSpinInputField(
                    label: widget.isBangla
                        ? 'দৈনিক ব্যবহার (ঘণ্টা)'
                        : 'Usage (Hours)',
                    value: item.hoursPerDay,
                    step: 0.5,
                    min: 0.1,
                    max: 24.0,
                    isDecimal: true,
                    onChanged: (val) {
                      setState(() {
                        item.hoursPerDay = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFF1B6A3B),
              ),
              const SizedBox(width: 6),
              Text(
                widget.isBangla
                    ? 'ব্যবহার নির্দেশিকা ও টিপস'
                    : 'Usage Guide & Tips',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1B6A3B),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildGuideRow(
            widget.isBangla ? 'ইনপুট টিপস' : 'Input Tip',
            widget.isBangla
                ? 'মান টাইপ করতে পারেন, অথবা বক্সে চাপ দিয়ে ধরে ওপরে/নিচে টেনে (Drag) সহজেই বাড়াতে-কমাতে পারেন।'
                : 'Type directly or drag up/down on the box to increase or decrease values.',
          ),
          _buildGuideRow(
            widget.isBangla ? 'উৎস' : 'Source',
            widget.isBangla
                ? 'বিদ্যুতের ধরন নির্বাচন করুন (এসি অথবা ডিসি)।'
                : 'Select current type used for item (AC or DC).',
          ),
          _buildGuideRow(
            widget.isBangla ? 'ব্যবহার' : 'Usage',
            widget.isBangla
                ? 'যন্ত্রটি দিনে গড়ে কত ঘণ্টা চালানো হয়।'
                : 'Average hours the appliance runs per day.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(String label, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ড্র্যাগ আপ/ডাউন এবং সরাসরি টাইপ করার উইজেট
// ==========================================
class DragSpinInputField extends StatefulWidget {
  final String label;
  final double value;
  final double step;
  final double min;
  final double max;
  final bool isDecimal;
  final ValueChanged<double> onChanged;

  const DragSpinInputField({
    super.key,
    required this.label,
    required this.value,
    required this.step,
    required this.min,
    required this.max,
    required this.isDecimal,
    required this.onChanged,
  });

  @override
  State<DragSpinInputField> createState() => _DragSpinInputFieldState();
}

class _DragSpinInputFieldState extends State<DragSpinInputField> {
  late TextEditingController _controller;
  double _dragAccumulator = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
  }

  @override
  void didUpdateWidget(covariant DragSpinInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final formatted = _formatValue(widget.value);
      if (_controller.text != formatted) {
        _controller.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double val) {
    return widget.isDecimal ? val.toStringAsFixed(1) : val.toInt().toString();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    // ওপরে ড্র্যাগ করলে পজিটিভ, নিচে ড্র্যাগ করলে নেগেটিভ
    _dragAccumulator -= details.primaryDelta ?? 0.0;

    // প্রতি 10 পিক্সেল ড্র্যাগে একটি স্টেপ পরিবর্তন
    const double sensitivity = 10.0;

    if (_dragAccumulator.abs() >= sensitivity) {
      final steps = (_dragAccumulator / sensitivity).truncate();
      double newVal = widget.value + (steps * widget.step);
      newVal = newVal.clamp(widget.min, widget.max);

      _dragAccumulator -= steps * sensitivity;

      if (newVal != widget.value) {
        widget.onChanged(newVal);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: _handleVerticalDragUpdate,
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.numberWithOptions(
          decimal: widget.isDecimal,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_drop_up, size: 16, color: Colors.grey),
              Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
            ],
          ),
        ),
        onChanged: (val) {
          final parsed = double.tryParse(val);
          if (parsed != null) {
            final clamped = parsed.clamp(widget.min, widget.max);
            widget.onChanged(clamped);
          }
        },
      ),
    );
  }
}
