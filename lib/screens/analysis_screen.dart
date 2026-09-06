import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../services/ad_service.dart';
import '../services/share_service.dart';
import '../widgets/income_trend_chart.dart';
import '../widgets/month_comparison_chart.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/share_preview_widget.dart';
import '../utils/responsive_utils.dart';
import '../main.dart' show currentTabIndex;
import 'transaction_history_screen.dart';
import 'category_detail_screen.dart';
import 'income_expense_detail_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  final StorageService _storage = StorageService();

  double _currentIncome = 0;
  double _currentExpense = 0;
  double _previousMonthIncome = 0;
  double _targetSavingsAmount = 50000.0;
  Map<int, double> _currentMonthExpenses = {};
  Map<int, double> _previousMonthExpenses = {};

  // Animation controllers
  late AnimationController _savingsAmountController;
  late AnimationController _incomeController;
  late AnimationController _expenseController;

  // Previous values for transition animations
  double _previousSavingsAmount = 0;
  double _previousIncome = 0;
  double _previousExpense = 0;

  int _lastTabIndex = -1; // 前回のタブインデックスを記録
  int _dataVersion = 0; // データ更新カウンター（グラフ再構築用）

  @override
  void initState() {
    super.initState();
    _savingsAmountController = AnimationController(
      duration: ThemeService().currentTheme.animDuration,
      vsync: this,
    );
    _incomeController = AnimationController(
      duration: ThemeService().currentTheme.animDuration,
      vsync: this,
    );
    _expenseController = AnimationController(
      duration: ThemeService().currentTheme.animDuration,
      vsync: this,
    );
    _loadData();

    // タブが分析画面(index=0)に切り替わったときにデータを再読み込み
    currentTabIndex.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // 分析画面(index=0)に「切り替わった」時のみデータ再読み込み
    // （前回が別のタブで、今回が分析画面の場合のみ）
    if (currentTabIndex.value == 0 && _lastTabIndex != 0 && mounted) {
      _loadData();
    }
    _lastTabIndex = currentTabIndex.value;
  }

  @override
  void dispose() {
    currentTabIndex.removeListener(_onTabChanged);
    _savingsAmountController.dispose();
    _incomeController.dispose();
    _expenseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // 前月を計算
    final previousMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final previousYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    final currentIncome =
        await _storage.getTotalIncomeForMonth(currentYear, currentMonth);
    final currentExpense =
        await _storage.getTotalExpenseForMonth(currentYear, currentMonth);
    final previousMonthIncome =
        await _storage.getTotalIncomeForMonth(previousYear, previousMonth);
    final targetAmount = await _storage.getTargetSavingsAmount();

    final currentMonthExpenses =
        await _storage.getExpensesByCategoryForMonth(currentYear, currentMonth);
    final previousMonthExpenses =
        await _storage.getExpensesByCategoryForMonth(previousYear, previousMonth);

    // Calculate remaining amount from previous month's income
    final newSavingsAmount = previousMonthIncome - currentExpense;

    // Trigger animations if values changed
    if (newSavingsAmount != _previousMonthIncome - _currentExpense) {
      _previousSavingsAmount = _previousMonthIncome - _currentExpense;
      _savingsAmountController.forward(from: 0);
    }
    if (currentIncome != _currentIncome) {
      _previousIncome = _currentIncome;
      _incomeController.forward(from: 0);
    }
    if (currentExpense != _currentExpense) {
      _previousExpense = _currentExpense;
      _expenseController.forward(from: 0);
    }

    setState(() {
      _currentIncome = currentIncome;
      _currentExpense = currentExpense;
      _previousMonthIncome = previousMonthIncome;
      _targetSavingsAmount = targetAmount;
      _currentMonthExpenses = currentMonthExpenses;
      _previousMonthExpenses = previousMonthExpenses;
      _dataVersion++; // データ更新カウンターを増やしてグラフを再構築
    });
  }


  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    // 使える予算 = 前月収入 - 目標貯蓄額
    final usableBudget = _previousMonthIncome - _targetSavingsAmount;
    // あと使ってもいいお金 = 使える予算 - 今月支出
    final remainingBudget = usableBudget - _currentExpense;
    // 実際の貯蓄額（目標達成判定用）
    final actualSavings = _previousMonthIncome - _currentExpense;
    // 貯蓄率 = 実際の貯蓄額 / 前月収入
    final savingsRate = _previousMonthIncome > 0
        ? (actualSavings / _previousMonthIncome).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          backgroundColor: Theme.of(context).colorScheme.surface,
          color: Theme.of(context).colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: r.paddingAll(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 前月収入からの残額ヘッダー（貯蓄目標統合版）
                    Container(
                      padding: r.paddingSymmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(r.borderRadius(20)),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'あと使えるお金',
                                style: TextStyle(
                                  fontSize: r.fontSize(14),
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showShareSavingsDialog(
                                      savingsRate: savingsRate,
                                      savingsAmount: actualSavings,
                                      targetAmount: _targetSavingsAmount,
                                      isAchieved: actualSavings >= _targetSavingsAmount,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(r.spacing(6)),
                                      margin: EdgeInsets.only(right: r.spacing(8)),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.share,
                                        size: r.fontSize(16),
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: r.spacing(10),
                                      vertical: r.spacing(4),
                                    ),
                                    decoration: BoxDecoration(
                                      color: actualSavings >= _targetSavingsAmount
                                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                          : Theme.of(context).colorScheme.error.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(r.borderRadius(8)),
                                    ),
                                    child: Text(
                                      actualSavings >= _targetSavingsAmount ? '目標達成' : '未達成',
                                      style: TextStyle(
                                        fontSize: r.fontSize(11),
                                        fontWeight: FontWeight.w700,
                                        color: actualSavings >= _targetSavingsAmount
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          r.verticalSpace(8),
                          ClipRect(
                            child: _AnimatedNumber(
                              value: remainingBudget,
                              previousValue: _previousSavingsAmount,
                              controller: _savingsAmountController,
                              fontSize: r.fontSize(48),
                              color: remainingBudget >= 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                              formatter: (value) => '¥ ${_formatNumber(value)}',
                              useBounce: true,
                            ),
                          ),
                          r.verticalSpace(12),
                          // プログレスバー（使える予算に対する残り予算の割合）
                          ClipRRect(
                            borderRadius: BorderRadius.circular(r.borderRadius(6)),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: usableBudget > 0
                                    ? (remainingBudget / usableBudget).clamp(0.0, 1.0)
                                    : 0.0,
                              ),
                              duration: ThemeService().currentTheme.animDuration,
                              curve: ThemeService().currentTheme.animationCurve,
                              builder: (context, value, child) {
                                return LinearProgressIndicator(
                                  value: value,
                                  minHeight: r.heightSize(8),
                                  backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    actualSavings >= _targetSavingsAmount
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.error,
                                  ),
                                );
                              },
                            ),
                          ),
                          r.verticalSpace(8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: savingsRate * 100),
                                duration: ThemeService().currentTheme.animDuration,
                                curve: ThemeService().currentTheme.animationCurve,
                                builder: (context, value, child) {
                                  return Text(
                                    '貯蓄率: ${value.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: r.fontSize(12),
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                              Text(
                                '目標: ¥${_formatNumber(_targetSavingsAmount)}',
                                style: TextStyle(
                                  fontSize: r.fontSize(12),
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          r.verticalSpace(8),
                          Row(
                            children: [
                              Text(
                                '前月収入: ¥${_formatNumber(_previousMonthIncome)}',
                                style: TextStyle(
                                  fontSize: r.fontSize(11),
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                '  |  ',
                                style: TextStyle(
                                  fontSize: r.fontSize(11),
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
                                ),
                              ),
                              Text(
                                '使える予算: ¥${_formatNumber(usableBudget)}',
                                style: TextStyle(
                                  fontSize: r.fontSize(11),
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    r.verticalSpace(24),

                    // 今月のサマリー
                    _buildSummaryRow(r),
                    r.verticalSpace(16),

                    // Medium Rectangle広告（サマリー行の下）
                    BannerAdWidget.mediumRectangle(),

                    r.verticalSpace(24),

                    // 履歴ボタン
                    _HistoryCard(onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const TransactionHistoryScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCirc,
                                ),
                              ),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      );
                    }),
                    r.verticalSpace(24),

                    // 収支推移グラフ
                    IncomeTrendChart(
                      key: ValueKey(_dataVersion), // データ更新時に強制再構築
                      onTap: () async {
                        // インタースティシャル広告の表示判定
                        final shouldShowAd = await AdService().shouldShowInterstitialOnNavigation();
                        if (shouldShowAd) {
                          await AdService().showInterstitialAd(
                            onAdDismissed: () {
                              debugPrint('Interstitial ad dismissed after income trend navigation');
                            },
                          );
                          await AdService().markInterstitialShown();
                        }

                        // 広告表示後に画面遷移
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  const IncomeExpenseDetailScreen(),
                              transitionsBuilder:
                                  (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1.0, 0.0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCirc,
                                    ),
                                  ),
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 400),
                            ),
                          );
                        }
                      },
                    ),
                    r.verticalSpace(24),

                    // 対前月比較ヒストグラム
                    MonthComparisonChart(
                      key: ValueKey('month_comparison_$_dataVersion'), // データ更新時に強制再構築
                      currentMonthExpenses: _currentMonthExpenses,
                      previousMonthExpenses: _previousMonthExpenses,
                      onCategoryTap: (categoryId) async {
                        // インタースティシャル広告の表示判定
                        final shouldShowAd = await AdService().shouldShowInterstitialOnNavigation();
                        if (shouldShowAd) {
                          await AdService().showInterstitialAd(
                            onAdDismissed: () {
                              debugPrint('Interstitial ad dismissed after category navigation');
                            },
                          );
                          await AdService().markInterstitialShown();
                        }

                        // 広告表示後に画面遷移
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  CategoryDetailScreen(categoryId: categoryId),
                              transitionsBuilder:
                                  (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1.0, 0.0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCirc,
                                    ),
                                  ),
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 400),
                            ),
                          );
                        }
                      },
                    ),

                    r.verticalSpace(100), // 下部余白
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ResponsiveUtils r) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            '今月の収入',
            _currentIncome,
            Theme.of(context).colorScheme.primary,
            r,
            onTap: () => _navigateToFilteredHistory(InitialFilter.incomeOnly),
          ),
        ),
        r.horizontalSpace(12),
        Expanded(
          child: _buildSummaryCard(
            '今月の支出',
            _currentExpense,
            Theme.of(context).colorScheme.error,
            r,
            onTap: () => _navigateToFilteredHistory(InitialFilter.expenseOnly),
          ),
        ),
      ],
    );
  }

  void _navigateToFilteredHistory(InitialFilter filter) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TransactionHistoryScreen(initialFilter: filter),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCirc,
              ),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color, ResponsiveUtils r, {VoidCallback? onTap}) {
    // Determine which controller to use based on label
    final controller = label.contains('収入') ? _incomeController : _expenseController;
    final previousValue = label.contains('収入') ? _previousIncome : _previousExpense;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: r.paddingAll(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(r.borderRadius(16)),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: r.fontSize(12),
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
            r.verticalSpace(8),
            ClipRect(
              child: _AnimatedNumber(
                value: amount,
                previousValue: previousValue,
                controller: controller,
                fontSize: r.fontSize(24),
                color: color,
                formatter: (value) => '¥ ${_formatNumber(value)}',
                useBounce: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetProgressCard(ResponsiveUtils r) {
    final currentSavingsAmount = _previousMonthIncome - _currentExpense;
    final progress = _targetSavingsAmount > 0
        ? (currentSavingsAmount / _targetSavingsAmount).clamp(0.0, 1.0)
        : 0.0;
    final isAchieved = currentSavingsAmount >= _targetSavingsAmount;

    return Container(
      padding: r.paddingAll(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(r.borderRadius(20)),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '目標達成度',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isAchieved
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Theme.of(context).colorScheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color:
                        isAchieved ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAchieved ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '現在の貯蓄額: ¥ ${_formatNumber(currentSavingsAmount)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                '目標: ¥ ${_formatNumber(_targetSavingsAmount)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number.round());
  }

  Future<void> _showShareSavingsDialog({
    required double savingsRate,
    required double savingsAmount,
    required double targetAmount,
    required bool isAchieved,
  }) async {
    final previewKey = GlobalKey();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '貯蓄状況をシェア',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  key: previewKey,
                  child: SavingsSharePreview(
                    savingsRate: savingsRate,
                    savingsAmount: savingsAmount,
                    targetAmount: targetAmount,
                    isAchieved: isAchieved,
                    primaryColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    textColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'キャンセル',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ShareService().shareSavingsComparison(
                  savingsRate: savingsRate,
                  savingsAmount: savingsAmount,
                  targetAmount: targetAmount,
                  isTargetAchieved: isAchieved,
                  previewKey: previewKey,
                );
              },
              icon: const Icon(Icons.share, size: 18),
              label: const Text('シェア'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Animated number widget with slide transition
class _AnimatedNumber extends StatelessWidget {
  final double value;
  final double previousValue;
  final AnimationController controller;
  final double fontSize;
  final Color color;
  final String Function(double) formatter;
  final bool useBounce;

  const _AnimatedNumber({
    required this.value,
    required this.previousValue,
    required this.controller,
    required this.fontSize,
    required this.color,
    required this.formatter,
    this.useBounce = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final slideUpAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -1),
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.easeOutCubic,
          ),
        );

        final slideInAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: useBounce ? ThemeService().currentTheme.animationCurve : Curves.easeOutCubic,
          ),
        );

        final fadeOutAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.0, 0.5),
          ),
        );

        final fadeInAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.3, 1.0),
          ),
        );

        return SizedBox(
          height: fontSize * 1.3,
          child: Stack(
            children: [
              // Old value sliding up and fading out
              if (controller.value > 0 && controller.value < 1)
                SlideTransition(
                  position: slideUpAnimation,
                  child: FadeTransition(
                    opacity: fadeOutAnimation,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatter(previousValue),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              // New value sliding in from bottom and fading in
              SlideTransition(
                position: controller.value > 0 ? slideInAnimation : AlwaysStoppedAnimation(Offset.zero),
                child: FadeTransition(
                  opacity: controller.value > 0 ? fadeInAnimation : const AlwaysStoppedAnimation(1.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatter(value),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// History Card with scale animation
class _HistoryCard extends StatefulWidget {
  final VoidCallback onTap;

  const _HistoryCard({required this.onTap});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.primary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.history,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '取引履歴',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '過去の取引を確認・編集',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
