import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.isBangla
        ? widget.category.titleBn
        : widget.category.titleEn;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentItems.length,
                      itemBuilder: (context, index) {
                        return _buildTactileItemCard(index, isDark);
                      },
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: _addNewItem,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.energyGreen
                            : AppColors.primaryGreen,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.energyGreen
                              : AppColors.primaryGreen,
                          width: 1.5,
                        ),
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                      ),
                      label: Text(
                        widget.isBangla
                            ? '+ আরও উপকরণ যোগ করুন'
                            : '+ Add Another Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGuidelineCard(isDark),
                  ],
                ),
              ),
            ),
            _buildBottomSaveBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTactileItemCard(int index, bool isDark) {
    final item = _currentItems[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
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
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
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
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: widget.isBangla ? item.nameBn : item.nameEn,
                      dropdownColor: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down_circle_outlined,
                        color: isDark
                            ? AppColors.energyGreen
                            : AppColors.primaryGreen,
                        size: 20,
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
                              fontSize: 13.5,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        final selectedPreset = widget.category.presets
                            .firstWhere(
                              (p) =>
                                  (widget.isBangla ? p.nameBn : p.nameEn) ==
                                  val,
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
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _removeItem(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.alertRed,
                      size: 22,
                    ),
                  ),
                ),
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
                      widget.isBangla ? 'বিদ্যুতের উৎস' : 'Power Type',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildTypeChip(
                          label: 'AC',
                          isSelected: item.isAC,
                          activeColor: isDark
                              ? AppColors.skyBlue
                              : const Color(0xFF0284C7),
                          isDark: isDark,
                          onTap: () => setState(() => item.isAC = true),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeChip(
                          label: 'DC',
                          isSelected: !item.isAC,
                          activeColor: AppColors.energyGreen,
                          isDark: isDark,
                          onTap: () => setState(() => item.isAC = false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DragSpinInputField(
                  label: widget.isBangla ? 'পাওয়ার (ওয়াট)' : 'Power (Watt)',
                  value: item.watt,
                  step: 5.0,
                  min: 1.0,
                  max: 5000.0,
                  unit: 'W',
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
                  label: widget.isBangla ? 'সংখ্যা (পরিমাণ)' : 'Quantity',
                  value: item.quantity.toDouble(),
                  step: 1.0,
                  min: 1.0,
                  max: 100.0,
                  unit: widget.isBangla ? 'টি' : 'pcs',
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
                  label: widget.isBangla ? 'দৈনিক ব্যবহার' : 'Daily Usage',
                  value: item.hoursPerDay,
                  step: 0.5,
                  min: 0.1,
                  max: 24.0,
                  unit: widget.isBangla ? 'ঘণ্টা' : 'hrs',
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

  Widget _buildTypeChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? activeColor.withValues(alpha: 0.22)
                      : activeColor.withValues(alpha: 0.15))
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 13,
                color: isSelected
                    ? (isDark ? Colors.white : activeColor)
                    : (isDark ? const Color(0xFF94A3B8) : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: isDark ? AppColors.energyGreen : AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isBangla ? 'সহজ ইনপুট টিপস' : 'Input Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark
                      ? AppColors.energyGreen
                      : AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          Divider(height: 16, color: isDark ? Colors.white12 : Colors.black12),
          Text(
            widget.isBangla
                ? 'মান টাইপ করতে পারেন অথবা ইনপুট বক্সে আঙুল রেখে ওপরে/নিচে ড্র্যাগ (টেনে) করে দ্রুত মান বাড়াতে-কমাতে পারবেন।'
                : 'Type directly into the boxes, or drag up/down on any field to quickly increase or decrease values.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSaveBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, _currentItems);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.energyGreen
                  : AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.check_rounded, size: 20),
            label: Text(
              widget.isBangla ? 'সংরক্ষণ করুন ও ফিরুন' : 'Save & Return',
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
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
  final String unit;
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
    this.unit = '',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: widget.isDark
                  ? const Color(0xFF94A3B8)
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: widget.isDecimal,
                    ),
                    style: TextStyle(
                      color: widget.isDark
                          ? Colors.white
                          : AppColors.lightTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      suffixText: widget.unit,
                      suffixStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark
                            ? AppColors.energyGreen
                            : AppColors.primaryGreen,
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
                ),
                Container(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_drop_up_rounded,
                        size: 18,
                        color: widget.isDark
                            ? AppColors.energyGreen
                            : AppColors.primaryGreen,
                      ),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: widget.isDark
                            ? AppColors.energyGreen
                            : AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
