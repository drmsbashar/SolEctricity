import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/appliance_item.dart';
import '../models/appliance_presets.dart';
import '../widgets/theme_toggle_button.dart';

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.isBangla
        ? widget.category.titleBn
        : widget.category.titleEn;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _currentItems),
        ),
        title: Row(
          children: [
            Image.asset(
              widget.category.svgPath,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.devices,
                color: isDark ? AppColors.accentCyan : AppColors.energyGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.isBangla ? '$title ইনপুট' : '$title Input',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // ☀️/🌙 স্ট্যান্ডার্ডাইজড থিম টগল বাটন
          ThemeToggleButton(isBangla: widget.isBangla),
        ],
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentItems.length,
                itemBuilder: (context, index) {
                  return _buildItemCard(index, isDark);
                },
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _addNewItem,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.accentCyan
                      : const Color(0xFF1B6A3B),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF1B6A3B),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  widget.isBangla
                      ? '+ আরও উপকরণ যোগ করুন'
                      : '+ Add Another Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildGuidelineCard(isDark),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _currentItems);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.energyGreen
                      : const Color(0xFF1B6A3B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
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
      ),
    );
  }

  Widget _buildItemCard(int index, bool isDark) {
    final item = _currentItems[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: widget.isBangla ? item.nameBn : item.nameEn,
                  dropdownColor: isDark
                      ? AppColors.darkInputBg
                      : AppColors.lightCardBg,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.isBangla
                        ? 'আইটেম নির্বাচন'
                        : 'Select Item',
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkInputBg
                        : AppColors.lightInputBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
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
                  color: AppColors.alertRed,
                  size: 26,
                ),
                tooltip: widget.isBangla ? 'মুছুন' : 'Delete',
                onPressed: () => _removeItem(index),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isBangla ? 'উৎস (Source)' : 'Source',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('AC'),
                          selected: item.isAC,
                          selectedColor: isDark
                              ? AppColors.accentCyan.withValues(alpha: 0.25)
                              : Colors.blue.shade100,
                          labelStyle: TextStyle(
                            color: item.isAC
                                ? (isDark
                                      ? AppColors.accentCyan
                                      : Colors.blue.shade900)
                                : (isDark ? Colors.white60 : Colors.black87),
                            fontWeight: item.isAC
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => item.isAC = true);
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('DC'),
                          selected: !item.isAC,
                          selectedColor: isDark
                              ? AppColors.energyGreen.withValues(alpha: 0.25)
                              : Colors.green.shade100,
                          labelStyle: TextStyle(
                            color: !item.isAC
                                ? (isDark
                                      ? AppColors.energyGreen
                                      : Colors.green.shade900)
                                : (isDark ? Colors.white60 : Colors.black87),
                            fontWeight: !item.isAC
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => item.isAC = false);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: DragSpinInputField(
                  label: widget.isBangla ? 'ওয়াট (W)' : 'Power (W)',
                  value: item.watt,
                  step: 5.0,
                  min: 1.0,
                  max: 5000.0,
                  isDecimal: false,
                  isDark: isDark,
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

          Row(
            children: [
              Expanded(
                child: DragSpinInputField(
                  label: widget.isBangla ? 'পরিমাণ (সংখ্যা)' : 'Quantity',
                  value: item.quantity.toDouble(),
                  step: 1.0,
                  min: 1.0,
                  max: 100.0,
                  isDecimal: false,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() {
                      item.quantity = val.toInt();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
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
                  isDark: isDark,
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
    );
  }

  Widget _buildGuidelineCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.blueGrey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: isDark ? AppColors.energyGreen : const Color(0xFF1B6A3B),
              ),
              const SizedBox(width: 6),
              Text(
                widget.isBangla
                    ? 'ব্যবহার নির্দেশিকা ও টিপস'
                    : 'Usage Guide & Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark
                      ? AppColors.energyGreen
                      : const Color(0xFF1B6A3B),
                ),
              ),
            ],
          ),
          Divider(
            height: 16,
            color: isDark ? AppColors.darkBorder : Colors.blueGrey.shade200,
          ),
          _buildGuideRow(
            widget.isBangla ? 'ইনপুট টিপস' : 'Input Tip',
            widget.isBangla
                ? 'মান টাইপ করতে পারেন, অথবা বক্সে চাপ দিয়ে ধরে ওপরে/নিচে টেনে (Drag) সহজেই বাড়াতে-কমাতে পারেন।'
                : 'Type directly or drag up/down on the box to increase or decrease values.',
            isDark,
          ),
          _buildGuideRow(
            widget.isBangla ? 'উৎস' : 'Source',
            widget.isBangla
                ? 'বিদ্যুতের ধরন নির্বাচন করুন (এসি অথবা ডিসি)।'
                : 'Select current type used for item (AC or DC).',
            isDark,
          ),
          _buildGuideRow(
            widget.isBangla ? 'ব্যবহার' : 'Usage',
            widget.isBangla
                ? 'যন্ত্রটি দিনে গড়ে কত ঘণ্টা চালানো হয়।'
                : 'Average hours the appliance runs per day.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(String label, String desc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark ? AppColors.darkTextPrimary : Colors.black87,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DragSpinInputField extends StatefulWidget {
  final String label;
  final double value;
  final double step;
  final double min;
  final double max;
  final bool isDecimal;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const DragSpinInputField({
    super.key,
    required this.label,
    required this.value,
    required this.step,
    required this.min,
    required this.max,
    required this.isDecimal,
    required this.isDark,
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
    _dragAccumulator -= details.primaryDelta ?? 0.0;
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
        style: TextStyle(
          color: widget.isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: widget.isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          filled: true,
          fillColor: widget.isDark
              ? AppColors.darkInputBg
              : AppColors.lightInputBg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: widget.isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: widget.isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
            ),
          ),
          suffixIcon: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_drop_up,
                size: 16,
                color: widget.isDark ? Colors.white54 : Colors.grey,
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: widget.isDark ? Colors.white54 : Colors.grey,
              ),
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
