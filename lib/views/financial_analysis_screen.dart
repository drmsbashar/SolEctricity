import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../services/solar_calculation_service.dart';
import '../services/solar_radiation_service.dart';
import '../services/tariff_config_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/app_bar_title.dart';

enum BusinessModel { capex, opex }

/// ২৫ বছরের আর্থিক প্রো-ফরমা স্টেটমেন্ট রো মডেল
class CashFlowRow {
  final int year;
  final double generationKwh;
  final double gridTariff;
  final double grossRevenue;
  final double omExpense;
  final double debtService;
  final double netCashFlow;
  final double cumulativeCashFlow;

  CashFlowRow({
    required this.year,
    required this.generationKwh,
    required this.gridTariff,
    required this.grossRevenue,
    required this.omExpense,
    required this.debtService,
    required this.netCashFlow,
    required this.cumulativeCashFlow,
  });
}

/// ব্যাংক-গ্রেড ফাইন্যান্সিয়াল ক্যালকুলেশন ইঞ্জিন
class FinancialCalculationEngine {
  final double systemCapacityKw;
  final double costPerWatt;
  final double psh;
  final double effectivePR;
  final double gridTariff;
  final double ppaTariff;
  final double selfConsumptionRatio;
  final BusinessModel businessModel;

  final bool isDebtFinanced;
  final double debtRatio;
  final double loanInterestRate;
  final int loanTenureYears;

  final double discountRate;
  final double tariffEscalationRate;
  final double generationDeviationPercent;

  FinancialCalculationEngine({
    required this.systemCapacityKw,
    required this.costPerWatt,
    required this.psh,
    required this.effectivePR,
    required this.gridTariff,
    required this.ppaTariff,
    this.selfConsumptionRatio = 0.70,
    required this.businessModel,
    this.isDebtFinanced = false,
    this.debtRatio = 0.70,
    this.loanInterestRate = 8.5,
    this.loanTenureYears = 5,
    this.discountRate = 8.5,
    this.tariffEscalationRate = 4.0,
    this.generationDeviationPercent = 0.0,
  });

  double get totalCapex => systemCapacityKw * 1000.0 * costPerWatt;
  double get loanPrincipal =>
      isDebtFinanced && businessModel == BusinessModel.capex
      ? totalCapex * debtRatio
      : 0.0;
  double get upfrontEquity => totalCapex - loanPrincipal;

  double get annualDebtService {
    if (!isDebtFinanced || loanPrincipal <= 0 || loanTenureYears <= 0)
      return 0.0;
    final double r = (loanInterestRate / 100.0);
    if (r <= 0) return loanPrincipal / loanTenureYears;
    final double factor = math.pow(1.0 + r, loanTenureYears).toDouble();
    return loanPrincipal * (r * factor) / (factor - 1.0);
  }

  double get monthlyEmi => annualDebtService / 12.0;

  double get annualGenYear1 {
    final double baseDailyGen = systemCapacityKw * psh * effectivePR;
    final double nominalGen = baseDailyGen * 365.0;
    return nominalGen * (1.0 + (generationDeviationPercent / 100.0));
  }

  List<CashFlowRow> generateCashFlowSchedule() {
    final List<CashFlowRow> schedule = [];
    final double omBase = totalCapex * 0.012;
    final double inverterReplProvision = totalCapex * 0.18;

    double runningCumulative = businessModel == BusinessModel.capex
        ? -upfrontEquity
        : 0.0;

    for (int y = 1; y <= 25; y++) {
      final double degradation = math.pow(0.995, y - 1).toDouble();
      final double genYearY = annualGenYear1 * degradation;
      final double tariffYearY =
          gridTariff * math.pow(1.0 + (tariffEscalationRate / 100.0), y - 1);
      final double omYearY = omBase * math.pow(1.0 + 0.035, y - 1);

      double grossRevenue = 0.0;
      if (businessModel == BusinessModel.capex) {
        grossRevenue = genYearY * tariffYearY;
      } else {
        final double ppaTariffYearY = ppaTariff * math.pow(1.0 + 0.02, y - 1);
        grossRevenue = genYearY * (tariffYearY - ppaTariffYearY);
      }

      double debtPayment = 0.0;
      if (businessModel == BusinessModel.capex &&
          isDebtFinanced &&
          y <= loanTenureYears) {
        debtPayment = annualDebtService;
      }

      double expenseThisYear = omYearY;
      if (businessModel == BusinessModel.capex && y == 10) {
        expenseThisYear += inverterReplProvision;
      }

      final double netCashFlow = grossRevenue - expenseThisYear - debtPayment;
      runningCumulative += netCashFlow;

      schedule.add(
        CashFlowRow(
          year: y,
          generationKwh: genYearY,
          gridTariff: tariffYearY,
          grossRevenue: grossRevenue,
          omExpense: expenseThisYear,
          debtService: debtPayment,
          netCashFlow: netCashFlow,
          cumulativeCashFlow: runningCumulative,
        ),
      );
    }

    return schedule;
  }

  double calculatePaybackYears(List<CashFlowRow> schedule) {
    if (businessModel == BusinessModel.opex) return 0.0;
    final double target = upfrontEquity;
    if (target <= 0) return 0.0;

    double cum = 0.0;
    for (var row in schedule) {
      final double currentNet =
          row.grossRevenue - row.omExpense - row.debtService;
      cum += currentNet;
      if (cum >= target) {
        final double prev = cum - currentNet;
        final double needed = target - prev;
        return (row.year - 1) + (needed / (currentNet > 0 ? currentNet : 1.0));
      }
    }
    return 25.0;
  }

  double calculateNPV(List<CashFlowRow> schedule) {
    double npv = businessModel == BusinessModel.capex ? -upfrontEquity : 0.0;
    final double r = discountRate / 100.0;

    for (var row in schedule) {
      final double factor = math.pow(1.0 + r, row.year).toDouble();
      npv += row.netCashFlow / factor;
    }
    return npv;
  }

  double calculateIRR(List<CashFlowRow> schedule) {
    if (businessModel == BusinessModel.opex) return 0.0;
    final double initialOutflow = upfrontEquity;
    if (initialOutflow <= 0) return 0.0;

    double rate = 0.12;
    for (int iter = 0; iter < 100; iter++) {
      double npv = -initialOutflow;
      double dNpv = 0.0;

      for (var row in schedule) {
        final double factor = math.pow(1.0 + rate, row.year).toDouble();
        npv += row.netCashFlow / factor;
        dNpv -= (row.year * row.netCashFlow) / (factor * (1.0 + rate));
      }

      if (dNpv == 0) break;
      final double nextRate = rate - (npv / dNpv);
      if ((nextRate - rate).abs() < 0.0001) {
        rate = nextRate;
        break;
      }
      rate = nextRate;
    }
    return (rate * 100.0).clamp(-50.0, 100.0);
  }

  double calculateLCOE(List<CashFlowRow> schedule) {
    final double r = discountRate / 100.0;
    double totalDiscountedCosts = totalCapex;
    double totalDiscountedGen = 0.0;

    for (var row in schedule) {
      final double factor = math.pow(1.0 + r, row.year).toDouble();
      totalDiscountedCosts += row.omExpense / factor;
      totalDiscountedGen += row.generationKwh / factor;
    }

    return totalDiscountedGen > 0
        ? (totalDiscountedCosts / totalDiscountedGen)
        : 0.0;
  }

  double calculateDSCR(List<CashFlowRow> schedule) {
    if (!isDebtFinanced || annualDebtService <= 0) return 0.0;
    double minDscr = 999.0;
    for (int y = 0; y < loanTenureYears && y < schedule.length; y++) {
      final row = schedule[y];
      final double operationalCash = row.grossRevenue - row.omExpense;
      final double dscr = operationalCash / annualDebtService;
      if (dscr < minDscr) minDscr = dscr;
    }
    return minDscr == 999.0 ? 0.0 : minDscr;
  }

  double calculateLifetimeROI(List<CashFlowRow> schedule) {
    final double investment = businessModel == BusinessModel.capex
        ? upfrontEquity
        : 1.0;
    if (investment <= 0) return 0.0;
    final double totalNetProfit = schedule.fold(
      0.0,
      (sum, r) => sum + r.netCashFlow,
    );
    return (totalNetProfit / investment) * 100.0;
  }

  Map<String, double> calculateCarbonESGMetrics() {
    const double co2FactorPerKwh = 0.62;
    const double carbonCreditUsdPerTon = 7.50;
    const double bdtPerUsd = 120.0;

    final double annualCo2Tons = (annualGenYear1 * co2FactorPerKwh) / 1000.0;
    final double lifetimeCo2Tons = annualCo2Tons * 25.0 * 0.94;
    final double annualCarbonRevenueBdt =
        annualCo2Tons * carbonCreditUsdPerTon * bdtPerUsd;

    return {
      'annualCo2Tons': annualCo2Tons,
      'lifetimeCo2Tons': lifetimeCo2Tons,
      'annualCarbonRevenueBdt': annualCarbonRevenueBdt,
    };
  }
}

class FinancialAnalysisScreen extends StatefulWidget {
  final bool isBangla;
  final VoidCallback? onToggleLanguage;

  const FinancialAnalysisScreen({
    super.key,
    this.isBangla = true,
    this.onToggleLanguage,
  });

  @override
  State<FinancialAnalysisScreen> createState() =>
      _FinancialAnalysisScreenState();
}

class _FinancialAnalysisScreenState extends State<FinancialAnalysisScreen> {
  late bool _isBangla;

  TariffConfig _tariffConfig = TariffConfig.defaultConfig();
  BusinessModel _selectedModel = BusinessModel.capex;

  final TextEditingController _monthlyBillController = TextEditingController(
    text: '8500',
  );
  final TextEditingController _sanctionedLoadController = TextEditingController(
    text: '10',
  );
  final TextEditingController _customTariffController = TextEditingController(
    text: '9.50',
  );
  final TextEditingController _ppaTariffController = TextEditingController(
    text: '7.50',
  );

  double _systemCapacityKw = 6.0;
  String _consumerCategory = 'commercial';
  double _costPerWatt = 72.0;
  double _discountRate = 8.5;
  double _tariffEscalationRate = 4.0;
  double _selfConsumptionPercent = 70.0;
  double _generationDeviationPercent = 0.0;

  bool _isDebtFinanced = false;
  double _debtRatioPercent = 70.0;
  double _loanInterestRate = 8.5;
  int _loanTenureYears = 5;

  bool _isLoadingNasa = false;
  bool _isProFormaExpanded = false;
  SolarRadiationResult? _climateData;

  static const double _defaultLat = 23.8103;
  static const double _defaultLon = 90.4125;

  @override
  void initState() {
    super.initState();
    _isBangla = widget.isBangla;
    _initTariffAndSync();
    _fetchClimateData();
  }

  Future<void> _initTariffAndSync() async {
    final config = await TariffConfigService.getActiveConfig();
    if (mounted) {
      setState(() {
        _tariffConfig = config;
        _costPerWatt = config.costPerWatt > 0 ? config.costPerWatt : 72.0;
        _updatePpaTariff();
      });
    }
    await TariffConfigService.syncRemoteConfig();
  }

  void _updatePpaTariff() {
    final double gridTariff = _getEffectiveGridTariff();
    _ppaTariffController.text = (gridTariff * 0.80).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _monthlyBillController.dispose();
    _sanctionedLoadController.dispose();
    _customTariffController.dispose();
    _ppaTariffController.dispose();
    super.dispose();
  }

  Future<void> _fetchClimateData() async {
    setState(() => _isLoadingNasa = true);
    try {
      final result = await SolarRadiationService.fetchPshByCoordinates(
        _defaultLat,
        _defaultLon,
      );
      if (mounted) setState(() => _climateData = result);
    } catch (_) {
      if (mounted) {
        setState(() {
          _climateData = SolarRadiationResult(
            peakSunHours: SolarRadiationService.defaultPsh,
            messageBn: 'ডিফল্ট সৌর বিকিরণ ব্যবহৃত হচ্ছে',
            messageEn: 'Using default solar radiation',
            isSuccess: false,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingNasa = false);
    }
  }

  double _getEffectiveGridTariff() {
    switch (_consumerCategory) {
      case 'residential':
        return _tariffConfig.residential;
      case 'commercial':
        return _tariffConfig.commercial;
      case 'industrial':
        return 10.80;
      case 'institutional':
        return _tariffConfig.institutional;
      case 'custom':
        return double.tryParse(_customTariffController.text) ??
            _tariffConfig.commercial;
      default:
        return _tariffConfig.commercial;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double sanctionedLoad =
        double.tryParse(_sanctionedLoadController.text.replaceAll(',', '')) ??
        0.0;
    final double monthlyBill =
        double.tryParse(_monthlyBillController.text.replaceAll(',', '')) ?? 0.0;
    final double gridTariff = _getEffectiveGridTariff();
    final double ppaTariff =
        double.tryParse(_ppaTariffController.text) ?? (gridTariff * 0.80);

    final double maxAllowedSolarKw = sanctionedLoad * 0.70;
    final bool isExceedingDpdcCap =
        sanctionedLoad > 0 && _systemCapacityKw > maxAllowedSolarKw;

    final double psh =
        _climateData?.peakSunHours ?? SolarRadiationService.defaultPsh;
    final double ambTemp = _climateData?.ambientTemp ?? 26.0;
    final double tempDerate = SolarCalculationService.calculateTempDerateFactor(
      ambTemp,
    );
    final double effectivePR = 0.80 * tempDerate;

    final engine = FinancialCalculationEngine(
      systemCapacityKw: _systemCapacityKw,
      costPerWatt: _costPerWatt,
      psh: psh,
      effectivePR: effectivePR,
      gridTariff: gridTariff,
      ppaTariff: ppaTariff,
      selfConsumptionRatio: _selfConsumptionPercent / 100.0,
      businessModel: _selectedModel,
      isDebtFinanced: _isDebtFinanced,
      debtRatio: _debtRatioPercent / 100.0,
      loanInterestRate: _loanInterestRate,
      loanTenureYears: _loanTenureYears,
      discountRate: _discountRate,
      tariffEscalationRate: _tariffEscalationRate,
      generationDeviationPercent: _generationDeviationPercent,
    );

    final cashFlowSchedule = engine.generateCashFlowSchedule();
    final double paybackYears = engine.calculatePaybackYears(cashFlowSchedule);
    final double npv = engine.calculateNPV(cashFlowSchedule);
    final double irr = engine.calculateIRR(cashFlowSchedule);
    final double lcoe = engine.calculateLCOE(cashFlowSchedule);
    final double dscr = engine.calculateDSCR(cashFlowSchedule);
    final double lifetimeRoi = engine.calculateLifetimeROI(cashFlowSchedule);
    final esgMetrics = engine.calculateCarbonESGMetrics();

    final double monthlyGenKwh = (engine.annualGenYear1 / 12.0);
    final double monthlySavings = _selectedModel == BusinessModel.capex
        ? (monthlyGenKwh * gridTariff)
        : (monthlyGenKwh * (gridTariff - ppaTariff));
    final double billOffsetPercent = monthlyBill > 0
        ? ((monthlySavings / monthlyBill) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: TwoLineAppBarTitle(
          title: _isBangla ? 'আর্থিক বিশ্লেষণ' : 'Financial Analysis',
          subtitle: _isBangla
              ? 'রিটার্ন, ঋণ ও কার্বন মূল্যায়ন'
              : 'ROI, Debt & ESG Model',
        ),
        actions: [
          ThemeToggleButton(isBangla: _isBangla),
          IconButton(
            onPressed: () {
              setState(() => _isBangla = !_isBangla);
              widget.onToggleLanguage?.call();
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
            tooltip: _isBangla ? 'হোম' : 'Home',
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModelSelector(isDark),
              const SizedBox(height: 14),
              _buildInputConsoleCard(
                sanctionedLoad: sanctionedLoad,
                maxAllowedSolarKw: maxAllowedSolarKw,
                isExceedingDpdcCap: isExceedingDpdcCap,
                gridTariff: gridTariff,
                ppaTariff: ppaTariff,
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              if (_selectedModel == BusinessModel.capex) ...[
                _buildDebtFinancingCard(
                  totalCapex: engine.totalCapex,
                  monthlyEmi: engine.monthlyEmi,
                  dscr: dscr,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
              ],
              _buildSensitivityCard(isDark),
              const SizedBox(height: 16),
              Text(
                _isBangla
                    ? 'আর্থিক মূল্যায়ন সূচক'
                    : 'Bankable Feasibility Metrics',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildKpiCard(
                    title: _isBangla
                        ? 'লাইফটাইম ROI (২৫ বছর)'
                        : 'Lifetime ROI (25-Yr)',
                    value: '${lifetimeRoi.toStringAsFixed(0)}%',
                    subtitle: _isBangla
                        ? 'বিনিয়োগের লাভজনকতা'
                        : 'Equity Return Factor',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.energyGreen,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    title: _isBangla ? 'পে-ব্যাক সময়কাল' : 'Payback Period',
                    value: _selectedModel == BusinessModel.capex
                        ? '${paybackYears.toStringAsFixed(1)} ${_isBangla ? "বছর" : "Yrs"}'
                        : (_isBangla
                              ? '০ দিন (জিরো ক্যাপেক্স)'
                              : '0 Days (OPEX)'),
                    subtitle: _isBangla
                        ? 'অবক্ষয় ও ঋণ সমন্বিত'
                        : 'Degradation & Debt factored',
                    icon: Icons.hourglass_bottom_rounded,
                    color: AppColors.solarGold,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildKpiCard(
                    title: _isBangla
                        ? (_isDebtFinanced
                              ? 'ইক্যুইটি IRR (%)'
                              : 'প্রজেক্ট IRR (%)')
                        : (_isDebtFinanced
                              ? 'Equity IRR (%)'
                              : 'Project IRR (%)'),
                    value: _selectedModel == BusinessModel.capex
                        ? '${irr.toStringAsFixed(1)}%'
                        : 'N/A (PPA)',
                    subtitle: _isBangla
                        ? 'ব্যাংক এফডিআর রেটের বেশি'
                        : 'Hurdle Rate Benchmark',
                    icon: Icons.auto_graph_rounded,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    title: _isBangla
                        ? 'সোলার ইউনিট খরচ'
                        : 'Unit Generation Cost',
                    value: '৳ ${lcoe.toStringAsFixed(2)} / kWh',
                    subtitle: _isBangla
                        ? 'গ্রিড দর: ৳${gridTariff.toStringAsFixed(1)}'
                        : 'Grid: ৳${gridTariff.toStringAsFixed(1)}',
                    icon: Icons.energy_savings_leaf_rounded,
                    color: isDark ? Colors.tealAccent : const Color(0xFF0D9488),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildKpiCard(
                    title: _isBangla
                        ? '২৫ বছরের নিট লাভ (NPV)'
                        : '25-Yr Net Value (NPV)',
                    value:
                        '৳ ${(npv / 100000).toStringAsFixed(1)} ${_isBangla ? "লাখ" : "Lakh"}',
                    subtitle: _isBangla
                        ? '@${_discountRate.toStringAsFixed(1)}% ডিসকাউন্ট রেট'
                        : '@${_discountRate.toStringAsFixed(1)}% WACC',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.energyGreen,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    title: _isBangla
                        ? 'মাসিক বিদ্যুৎ সাশ্রয়'
                        : 'Monthly Bill Offset',
                    value: '৳ ${monthlySavings.toStringAsFixed(0)}',
                    subtitle: _isBangla
                        ? 'বিল সাশ্রয়: ${billOffsetPercent.toStringAsFixed(0)}%'
                        : 'Bill Offset: ${billOffsetPercent.toStringAsFixed(0)}%',
                    icon: Icons.payments_rounded,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedModel == BusinessModel.capex && _isDebtFinanced)
                _buildDscrComplianceBadge(dscr, isDark),
              const SizedBox(height: 16),
              _buildProFormaTableCard(cashFlowSchedule, isDark),
              const SizedBox(height: 16),
              _buildEsgCarbonValuationCard(esgMetrics, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModelTab(
              model: BusinessModel.capex,
              title: _isBangla
                  ? 'CAPEX মডেল (মালিকানা)'
                  : 'CAPEX (Direct Ownership)',
              subtitle: _isBangla
                  ? 'নিজস্ব বিনিয়োগ, সর্বোচ্চ দীর্ঘমেয়াদী লাভ'
                  : 'Upfront investment, 100% savings',
              isSelected: _selectedModel == BusinessModel.capex,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModelTab(
              model: BusinessModel.opex,
              title: _isBangla ? 'OPEX মডেল (PPA/RESCO)' : 'OPEX (PPA / RESCO)',
              subtitle: _isBangla
                  ? 'বিনিয়োগ ০ টাকা, সস্তায় সোলার বিদ্যুৎ ক্রয়'
                  : 'Zero Capex, pay per unit consumed',
              isSelected: _selectedModel == BusinessModel.opex,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelTab({
    required BusinessModel model,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeColor = isDark ? AppColors.accentCyan : AppColors.primaryGreen;

    return InkWell(
      onTap: () => setState(() => _selectedModel = model),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.20 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: activeColor, width: 1.4)
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.primaryGreen)
                    : (isDark ? Colors.white60 : AppColors.lightTextSecondary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.25,
                color: isDark ? Colors.white60 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputConsoleCard({
    required double sanctionedLoad,
    required double maxAllowedSolarKw,
    required bool isExceedingDpdcCap,
    required double gridTariff,
    required double ppaTariff,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _isBangla
                      ? 'গ্রিড ট্যারিফ: ৳${gridTariff.toStringAsFixed(2)}/kWh'
                      : 'Grid: ৳${gridTariff.toStringAsFixed(2)}/kWh',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _selectedModel == BusinessModel.capex
                      ? (_isBangla
                            ? 'টার্নকি: ৳${_costPerWatt.toStringAsFixed(0)}/Wp'
                            : 'Capex: ৳${_costPerWatt.toStringAsFixed(0)}/Wp')
                      : (_isBangla
                            ? 'PPA দর: ৳${ppaTariff.toStringAsFixed(2)}/kWh'
                            : 'PPA: ৳${ppaTariff.toStringAsFixed(2)}/kWh'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _selectedModel == BusinessModel.capex
                        ? (isDark
                              ? AppColors.solarGold
                              : const Color(0xFFB45309))
                        : AppColors.energyGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(
                  'commercial',
                  _isBangla ? 'বাণিজ্যিক' : 'Commercial',
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  'industrial',
                  _isBangla ? 'শিল্প কারখানা' : 'Industrial',
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  'residential',
                  _isBangla ? 'আবাসিক' : 'Residential',
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  'institutional',
                  _isBangla ? 'শিক্ষাপ্রতিষ্ঠান' : 'Institute',
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  'custom',
                  _isBangla ? 'কাস্টম' : 'Custom',
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isBangla ? 'অনুমোদিত লোড' : 'Sanctioned Load',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _sanctionedLoadController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightInputBg,
                        suffixText: 'kW',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
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
                      _isBangla
                          ? 'মাসিক বিদ্যুৎ বিল'
                          : 'Monthly Electricity Bill',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _monthlyBillController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkInputBg
                            : AppColors.lightInputBg,
                        prefixText: '৳ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'সোলার সিস্টেম ক্ষমতা:'
                    : 'Proposed Solar Capacity:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                '${_systemCapacityKw.toStringAsFixed(1)} kWp',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isExceedingDpdcCap
                      ? AppColors.alertRed
                      : AppColors.energyGreen,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isExceedingDpdcCap
                  ? AppColors.alertRed
                  : AppColors.energyGreen,
              thumbColor: isExceedingDpdcCap
                  ? AppColors.alertRed
                  : AppColors.energyGreen,
              trackHeight: 4,
            ),
            child: Slider(
              value: _systemCapacityKw,
              min: 1.0,
              max: 100.0,
              divisions: 99,
              onChanged: (val) => setState(() => _systemCapacityKw = val),
            ),
          ),
          if (isExceedingDpdcCap)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
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
                    Icons.warning_amber_rounded,
                    color: AppColors.alertRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isBangla
                          ? 'সতর্কতা: ডিপিডিসি/স্রেডা নেট-মিটারিং নীতিমালা অনুযায়ী সোলার ক্ষমতা অনুমোদিত লোডের ৭০% (সর্বোচ্চ ${maxAllowedSolarKw.toStringAsFixed(1)} kWp) অতিক্রম করতে পারবে না।'
                          : 'Warning: Under DPDC net-metering regulations, solar capacity cannot exceed 70% of sanctioned load (${maxAllowedSolarKw.toStringAsFixed(1)} kWp).',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.alertRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'গ্রিড ট্যারিফ: ৳${gridTariff.toStringAsFixed(2)} / kWh'
                    : 'Grid Tariff: ৳${gridTariff.toStringAsFixed(2)} / kWh',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.accentCyan
                      : const Color(0xFF0284C7),
                ),
              ),
              if (_selectedModel == BusinessModel.capex)
                Text(
                  _isBangla
                      ? 'টার্নকি দর: ৳${_costPerWatt.toStringAsFixed(0)} / Wp'
                      : 'Capex Rate: ৳${_costPerWatt.toStringAsFixed(0)} / Wp',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.solarGold
                        : const Color(0xFFB45309),
                  ),
                )
              else
                Text(
                  _isBangla
                      ? 'সোলার PPA দর: ৳${ppaTariff.toStringAsFixed(2)} / kWh'
                      : 'PPA Tariff: ৳${ppaTariff.toStringAsFixed(2)} / kWh',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.energyGreen,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String catKey, String label, bool isDark) {
    final bool isSelected = _consumerCategory == catKey;
    final activeColor = isDark ? AppColors.accentCyan : AppColors.primaryGreen;

    return InkWell(
      onTap: () {
        setState(() {
          _consumerCategory = catKey;
          _updatePpaTariff();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.18)
              : (isDark ? AppColors.darkInputBg : AppColors.lightInputBg),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : activeColor)
                : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSensitivityCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'সংবেদনশীলতা বিশ্লেষণ'
                    : 'Sensitivity & Risk Simulation',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                '${_generationDeviationPercent >= 0 ? "+" : ""}${_generationDeviationPercent.toStringAsFixed(0)}% Gen',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: _generationDeviationPercent >= 0
                      ? AppColors.energyGreen
                      : AppColors.alertRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.solarGold,
              thumbColor: AppColors.solarGold,
              trackHeight: 3,
            ),
            child: Slider(
              value: _generationDeviationPercent,
              min: -15.0,
              max: 15.0,
              divisions: 6,
              onChanged: (v) => setState(() => _generationDeviationPercent = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBangla
                    ? 'খারাপ পরিস্থিতি (-১৫% উৎপাদন)'
                    : 'Worst Case (-15%)',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                ),
              ),
              Text(
                _isBangla ? 'সেরা পরিস্থিতি (+১৫% উৎপাদন)' : 'Best Case (+15%)',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDscrComplianceBadge(double dscr, bool isDark) {
    final bool isDscrSafe = dscr >= 1.25;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDscrSafe
            ? AppColors.energyGreen.withValues(alpha: 0.12)
            : AppColors.alertRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDscrSafe
              ? AppColors.energyGreen.withValues(alpha: 0.4)
              : AppColors.alertRed.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDscrSafe ? Icons.verified_rounded : Icons.gpp_bad_rounded,
            color: isDscrSafe ? AppColors.energyGreen : AppColors.alertRed,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBangla
                      ? 'ব্যাংক ঋণ নিরাপত্তা অনুপাত (DSCR): ${dscr.toStringAsFixed(2)}x'
                      : 'Debt Service Coverage (DSCR): ${dscr.toStringAsFixed(2)}x',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDscrSafe
                        ? AppColors.energyGreen
                        : AppColors.alertRed,
                  ),
                ),
                Text(
                  isDscrSafe
                      ? (_isBangla
                            ? 'প্রকল্পটি বাণিজ্যিক ব্যাংকের ঋণ অনুমোদনের জন্য সম্পূর্ণরূপে উপযুক্ত (মানদণ্ড: ≥ ১.২৫)'
                            : 'Project comfortably passes bank debt eligibility (Threshold: ≥ 1.25x).')
                      : (_isBangla
                            ? 'ঋণ পরিশোধের চাপ বেশি; ইকুইটি বৃদ্ধি বা ঋণের মেয়াদ বাড়ানো প্রয়োজন।'
                            : 'Debt coverage tight; consider increasing equity ratio or tenure.'),
                  style: TextStyle(
                    fontSize: 10,
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
    );
  }

  Widget _buildProFormaTableCard(List<CashFlowRow> schedule, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text(
              _isBangla
                  ? '২৫ বছরের ক্যাশফ্লো বিবরণী'
                  : '25-Year Pro-Forma Cash Flow Table',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            trailing: Icon(
              _isProFormaExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: isDark ? AppColors.accentCyan : AppColors.primaryGreen,
            ),
            onTap: () =>
                setState(() => _isProFormaExpanded = !_isProFormaExpanded),
          ),
          if (_isProFormaExpanded)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: DataTable(
                headingRowHeight: 34,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 32,
                horizontalMargin: 8,
                columnSpacing: 14,
                columns: [
                  DataColumn(
                    label: Text(
                      _isBangla ? 'বছর' : 'Yr',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      _isBangla ? 'উৎপাদন (kWh)' : 'Gen (kWh)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      _isBangla ? 'ট্যারিফ (৳)' : 'Tariff',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      _isBangla ? 'মোট আয় (৳)' : 'Gross (৳)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      _isBangla ? 'ওঅ্যান্ডএম (৳)' : 'O&M (৳)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (_isDebtFinanced)
                    DataColumn(
                      label: Text(
                        _isBangla ? 'ঋণ কিস্তি (৳)' : 'EMI (৳)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  DataColumn(
                    label: Text(
                      _isBangla ? 'নিট ক্যাশ (৳)' : 'Net (৳)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      _isBangla ? 'ব্যালান্স (৳)' : 'Cum. Bal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                rows: schedule.map((row) {
                  final isEven = row.year % 2 == 0;
                  return DataRow(
                    color: WidgetStateProperty.all(
                      isEven
                          ? (isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.black.withValues(alpha: 0.02))
                          : Colors.transparent,
                    ),
                    cells: [
                      DataCell(
                        Text(
                          'Y${row.year}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          row.generationKwh.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10.5),
                        ),
                      ),
                      DataCell(
                        Text(
                          row.gridTariff.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10.5),
                        ),
                      ),
                      DataCell(
                        Text(
                          row.grossRevenue.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.energyGreen,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          row.omExpense.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ),
                      if (_isDebtFinanced)
                        DataCell(
                          Text(
                            row.debtService.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.alertRed,
                            ),
                          ),
                        ),
                      DataCell(
                        Text(
                          row.netCashFlow.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          row.cumulativeCashFlow.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: row.cumulativeCashFlow >= 0
                                ? AppColors.energyGreen
                                : AppColors.alertRed,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEsgCarbonValuationCard(Map<String, double> esg, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF042416) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.energyGreen.withValues(alpha: 0.4)
              : Colors.green.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco_rounded,
                color: AppColors.energyGreen,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isBangla
                      ? 'পরিবেশগত ও কার্বন ক্রেডিট মূল্যায়ন (ESG)'
                      : 'ESG & Carbon Credit Monetization',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1B6A3B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _isBangla
                      ? 'বাৎসরিক কার্বন হ্রাস: ${esg['annualCo2Tons']?.toStringAsFixed(1)} টন CO₂'
                      : 'Annual Offset: ${esg['annualCo2Tons']?.toStringAsFixed(1)} tCO₂',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isBangla
                    ? '২৫ বছরে: ${esg['lifetimeCo2Tons']?.toStringAsFixed(0)} টন'
                    : '25-Yr: ${esg['lifetimeCo2Tons']?.toStringAsFixed(0)} tCO₂',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.energyGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isBangla
                ? 'আন্তর্জাতিক ভলান্টারি কার্বন মার্কেটে (VCM) প্রতি বছর প্রায় ৳ ${esg['annualCarbonRevenueBdt']?.toStringAsFixed(0)} মূল্যের অতিরিক্ত কার্বন ক্রেডিট রাজস্ব আয় সম্ভব।'
                : 'Potential to earn ~৳ ${esg['annualCarbonRevenueBdt']?.toStringAsFixed(0)} annually in Voluntary Carbon Markets (VCM).',
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? Colors.white70 : Colors.green.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 🌟 এই অংশটি আপডেট করা হয়েছে যাতে বড় সংখ্যা বক্সের বাইরে না যায়
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                ),
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

  Widget _buildDebtFinancingCard({
    required double totalCapex,
    required double monthlyEmi,
    required double dscr,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDebtFinanced
              ? (isDark
                    ? AppColors.accentCyan.withValues(alpha: 0.5)
                    : const Color(0xFF0284C7))
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.accentCyan
                          : const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isBangla
                            ? 'ব্যাংক ঋণ ও ইএমআই ফাইন্যান্সিং'
                            : 'Bank Debt & Financing Simulator',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isDebtFinanced,
                activeColor: isDark
                    ? AppColors.accentCyan
                    : AppColors.primaryGreen,
                onChanged: (val) => setState(() => _isDebtFinanced = val),
              ),
            ],
          ),
          if (_isDebtFinanced) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isBangla ? 'ঋণের অনুপাত:' : 'Debt Ratio:',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? Colors.white70
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Flexible(
                  child: Text(
                    '${_debtRatioPercent.toInt()}% Loan : ${(100 - _debtRatioPercent).toInt()}% Equity',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.energyGreen,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: _debtRatioPercent,
              min: 30.0,
              max: 85.0,
              divisions: 11,
              onChanged: (v) => setState(() => _debtRatioPercent = v),
            ),

            // সুদের হার (Interest Rate) স্লাইডার
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isBangla ? 'বার্ষিক সুদের হার:' : 'Annual Interest Rate:',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? Colors.white70
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  '${_loanInterestRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.accentCyan
                        : const Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
            Slider(
              value: _loanInterestRate,
              min: 4.0,
              max: 15.0,
              divisions: 22,
              onChanged: (v) => setState(() => _loanInterestRate = v),
            ),

            // ঋণের মেয়াদ (Tenure) স্লাইডার
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isBangla ? 'ঋণ পরিশোধের মেয়াদ:' : 'Loan Tenure:',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? Colors.white70
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  '$_loanTenureYears ${_isBangla ? "বছর" : "Years"}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.solarGold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _loanTenureYears.toDouble(),
              min: 2.0,
              max: 12.0,
              divisions: 10,
              onChanged: (v) => setState(() => _loanTenureYears = v.round()),
            ),

            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildMiniInputBox(
                    label: _isBangla ? 'সুদের হার' : 'Interest',
                    value: '${_loanInterestRate.toStringAsFixed(1)}%',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniInputBox(
                    label: _isBangla ? 'মেয়াদ' : 'Tenure',
                    value: '$_loanTenureYears ${_isBangla ? "বছর" : "Yrs"}',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniInputBox(
                    label: _isBangla ? 'মাসিক কিস্তি' : 'Monthly EMI',
                    value: '৳ ${monthlyEmi.toStringAsFixed(0)}',
                    isDark: isDark,
                    isHighlight: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniInputBox({
    required String label,
    required String value,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? AppColors.energyGreen
              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isHighlight
                    ? AppColors.energyGreen
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
