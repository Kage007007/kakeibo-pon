import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../utils/responsive_utils.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class SavingsDetailScreen extends StatefulWidget {
  const SavingsDetailScreen({super.key});

  @override
  State<SavingsDetailScreen> createState() => _SavingsDetailScreenState();
}

class _SavingsDetailScreenState extends State<SavingsDetailScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  Map<int, Map<String, double>> _monthlyData = {};
  double _averageSavingsRate = 0;
  double _maxSavingsRate = 0;
  double _minSavingsRate = 0;
  double _targetSavingsAmount = 0;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCirc,
      ),
    );
    _slideController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final Map<int, Map<String, double>> monthlyData = {};
    final List<double> savingsRates = [];

    // 前月収入を取得するために7か月前から取得
    double? previousIncome;
    final prevMonth = DateTime(now.year, now.month - 6);
    previousIncome = await _storage.getTotalIncomeForMonth(
      prevMonth.year,
      prevMonth.month,
    );

    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - (5 - i));
      final income = await _storage.getTotalIncomeForMonth(
        month.year,
        month.month,
      );
      final expense = await _storage.getTotalExpenseForMonth(
        month.year,
        month.month,
      );
      final savings = income - expense;
      // 前月の収入をベースに貯蓄率を計算
      final savingsRate = previousIncome != null && previousIncome > 0
          ? (savings / previousIncome).clamp(-1.0, 2.0)
          : 0.0;

      monthlyData[i] = {
        'income': income,
        'expense': expense,
        'savings': savings,
        'savingsRate': savingsRate,
      };

      if (previousIncome != null && previousIncome > 0) {
        savingsRates.add(savingsRate);
      }

      // 次の月のために今月の収入を保存
      previousIncome = income;
    }

    final targetAmount = await _storage.getTargetSavingsAmount();

    setState(() {
      _monthlyData = monthlyData;
      _targetSavingsAmount = targetAmount;

      if (savingsRates.isNotEmpty) {
        _averageSavingsRate =
            savingsRates.reduce((a, b) => a + b) / savingsRates.length;
        _maxSavingsRate = savingsRates.reduce((a, b) => a > b ? a : b);
        _minSavingsRate = savingsRates.reduce((a, b) => a < b ? a : b);
      }
    });
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number.round());
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            _slideController.reverse().then((_) {
              Navigator.pop(context);
            });
          },
        ),
        title: Text(
          '貯蓄率の詳細',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
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
                      // 統計サマリー
                      _buildStatisticsCards(r),
                      r.verticalSpace(24),

                      // 貯蓄率推移グラフ
                      _buildSavingsRateTrendChart(r),
                      r.verticalSpace(24),

                      // 収入・支出・貯蓄額推移グラフ
                      _buildAmountTrendChart(r),
                      r.verticalSpace(24),

                      // 月別詳細リスト
                      _buildMonthlyDetailList(r),
                      r.verticalSpace(100),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(ResponsiveUtils r) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '平均貯蓄率',
                '${(_averageSavingsRate * 100).toStringAsFixed(1)}%',
                Theme.of(context).colorScheme.primary,
                r,
              ),
            ),
            r.horizontalSpace(12),
            Expanded(
              child: _buildStatCard(
                '最高貯蓄率',
                '${(_maxSavingsRate * 100).toStringAsFixed(1)}%',
                Colors.greenAccent,
                r,
              ),
            ),
          ],
        ),
        r.verticalSpace(12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '最低貯蓄率',
                '${(_minSavingsRate * 100).toStringAsFixed(1)}%',
                Colors.orangeAccent,
                r,
              ),
            ),
            r.horizontalSpace(12),
            Expanded(
              child: _buildStatCard(
                '目標貯蓄額',
                '¥${_formatNumber(_targetSavingsAmount)}',
                Colors.purpleAccent,
                r,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    ResponsiveUtils r,
  ) {
    return Container(
      padding: r.paddingAll(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(r.borderRadius(16)),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: r.fontSize(12),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          r.verticalSpace(8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: r.fontSize(20),
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRateTrendChart(ResponsiveUtils r) {
    return Container(
      padding: r.paddingAll(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(r.borderRadius(20)),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '貯蓄率推移（過去6ヶ月）',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          r.verticalSpace(24),
          SizedBox(
            height: 200,
            child: _SavingsRateChart(
              monthlyData: _monthlyData,
              textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              gridColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountTrendChart(ResponsiveUtils r) {
    return Container(
      padding: r.paddingAll(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(r.borderRadius(20)),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '収支推移（過去6ヶ月）',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          r.verticalSpace(12),
          Row(
            children: [
              _buildLegendItem('収入', Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              _buildLegendItem('支出', Colors.redAccent.withOpacity(0.7)),
              const SizedBox(width: 16),
              _buildLegendItem('貯蓄', Colors.greenAccent),
            ],
          ),
          r.verticalSpace(24),
          SizedBox(
            height: 200,
            child: _AmountTrendChart(
              monthlyData: _monthlyData,
              textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              gridColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyDetailList(ResponsiveUtils r) {
    return Container(
      padding: r.paddingAll(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(r.borderRadius(20)),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '月別詳細',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          r.verticalSpace(16),
          ...List.generate(6, (i) {
            final data = _monthlyData[i];
            if (data == null) return const SizedBox.shrink();

            final now = DateTime.now();
            final month = DateTime(now.year, now.month - (5 - i));
            final monthLabel = DateFormat('yyyy年MM月').format(month);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _MonthDetailCard(
                monthLabel: monthLabel,
                income: data['income'] ?? 0,
                expense: data['expense'] ?? 0,
                savings: data['savings'] ?? 0,
                savingsRate: data['savingsRate'] ?? 0,
                index: i,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Savings Rate Chart
class _SavingsRateChart extends StatefulWidget {
  final Map<int, Map<String, double>> monthlyData;
  final Color textColor;
  final Color gridColor;

  const _SavingsRateChart({
    required this.monthlyData,
    required this.textColor,
    required this.gridColor,
  });

  @override
  State<_SavingsRateChart> createState() => _SavingsRateChartState();
}

class _SavingsRateChartState extends State<_SavingsRateChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SavingsRateChartPainter(
            monthlyData: widget.monthlyData,
            animationValue: _animation.value,
            textColor: widget.textColor,
            gridColor: widget.gridColor,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _SavingsRateChartPainter extends CustomPainter {
  final Map<int, Map<String, double>> monthlyData;
  final double animationValue;
  final Color textColor;
  final Color gridColor;

  _SavingsRateChartPainter({
    required this.monthlyData,
    required this.animationValue,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (monthlyData.isEmpty) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final segmentWidth = chartWidth / 5;

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Y-axis labels (percentage) - 動的に計算
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 10,
    );

    // データから最大値と最小値を取得
    double maxRate = 0;
    double minRate = 100;
    for (final data in monthlyData.values) {
      final rate = (data['savingsRate'] ?? 0) * 100; // 0-1 を 0-100 に変換
      if (rate > maxRate) maxRate = rate;
      if (rate < minRate) minRate = rate;
    }

    // 範囲を少し広げる（視認性のため）
    final rateRange = maxRate - minRate;
    final paddingRate = rateRange > 0 ? rateRange * 0.1 : 10; // 10%のパディング
    maxRate = (maxRate + paddingRate).clamp(0, 100);
    minRate = (minRate - paddingRate).clamp(0, 100);
    final displayRange = maxRate - minRate;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight * i / 4);
      final value = maxRate - (displayRange * i / 4);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${value.toInt()}%',
          style: textStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(5, y - textPainter.height / 2),
      );
    }

    // Line and points
    final linePaint = Paint()
      ..color = const Color(0xFF40C4FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = const Color(0xFF40C4FF)
      ..style = PaintingStyle.fill;

    final path = Path();
    bool firstPoint = true;

    for (int i = 0; i < 6; i++) {
      final data = monthlyData[i];
      if (data == null) continue;

      final savingsRate = (data['savingsRate'] ?? 0) * 100; // 0-1 を 0-100 に変換
      final normalizedRate = displayRange > 0 ? (savingsRate - minRate) / displayRange : 0;
      final x = padding + (i * segmentWidth);
      final y = padding +
          chartHeight -
          (normalizedRate * chartHeight * animationValue);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }

      // Point
      if (animationValue > i / 6) {
        canvas.drawCircle(Offset(x, y), 5, pointPaint);
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = const Color(0xFF050505),
        );
      }

      // X-axis labels (month)
      final now = DateTime.now();
      final month = DateTime(now.year, now.month - (5 - i));
      final monthLabel = '${month.month}月';
      final textPainter = TextPainter(
        text: TextSpan(
          text: monthLabel,
          style: textStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 25),
      );
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Amount Trend Chart
class _AmountTrendChart extends StatefulWidget {
  final Map<int, Map<String, double>> monthlyData;
  final Color textColor;
  final Color gridColor;

  const _AmountTrendChart({
    required this.monthlyData,
    required this.textColor,
    required this.gridColor,
  });

  @override
  State<_AmountTrendChart> createState() => _AmountTrendChartState();
}

class _AmountTrendChartState extends State<_AmountTrendChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _AmountTrendChartPainter(
            monthlyData: widget.monthlyData,
            animationValue: _animation.value,
            textColor: widget.textColor,
            gridColor: widget.gridColor,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _AmountTrendChartPainter extends CustomPainter {
  final Map<int, Map<String, double>> monthlyData;
  final double animationValue;
  final Color textColor;
  final Color gridColor;

  _AmountTrendChartPainter({
    required this.monthlyData,
    required this.animationValue,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (monthlyData.isEmpty) return;

    // Find max and min values (including negative savings)
    double maxValue = 0;
    double minValue = 0;
    for (final data in monthlyData.values) {
      final income = data['income'] ?? 0;
      final expense = data['expense'] ?? 0;
      final savings = data['savings'] ?? 0;
      maxValue = math.max(maxValue, math.max(income, expense));
      minValue = math.min(minValue, savings);  // savings can be negative
    }

    if (maxValue == 0 && minValue == 0) return;

    // Adjust maxValue to include negative range if needed
    final valueRange = maxValue + minValue.abs();
    if (valueRange == 0) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final segmentWidth = chartWidth / 5;

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Y-axis labels
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 10,
    );

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight * i / 4);
      // Adjust labels to show the full range from maxValue to minValue
      final value = maxValue - (valueRange * i / 4);
      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatNumber(value),
          style: textStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(5, y - textPainter.height / 2),
      );
    }

    // Draw zero line if there are negative values
    if (minValue < 0) {
      final zeroY = padding + (maxValue / valueRange) * chartHeight;
      final zeroPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(padding, zeroY),
        Offset(size.width - padding, zeroY),
        zeroPaint,
      );
    }

    // Draw three lines (income, expense, savings)
    _drawLine(
      canvas,
      size,
      'income',
      const Color(0xFF40C4FF),
      padding,
      chartHeight,
      segmentWidth,
      maxValue,
      valueRange,
    );
    _drawLine(
      canvas,
      size,
      'expense',
      Colors.redAccent.withOpacity(0.7),
      padding,
      chartHeight,
      segmentWidth,
      maxValue,
      valueRange,
    );
    _drawLine(
      canvas,
      size,
      'savings',
      Colors.greenAccent,
      padding,
      chartHeight,
      segmentWidth,
      maxValue,
      valueRange,
    );

    // X-axis labels
    for (int i = 0; i < 6; i++) {
      final x = padding + (i * segmentWidth);
      final now = DateTime.now();
      final month = DateTime(now.year, now.month - (5 - i));
      final monthLabel = '${month.month}月';
      final textPainter = TextPainter(
        text: TextSpan(
          text: monthLabel,
          style: textStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 25),
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    String key,
    Color color,
    double padding,
    double chartHeight,
    double segmentWidth,
    double maxValue,
    double valueRange,
  ) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    bool firstPoint = true;

    for (int i = 0; i < 6; i++) {
      final data = monthlyData[i];
      if (data == null) continue;

      final value = data[key] ?? 0;
      final x = padding + (i * segmentWidth);
      // Calculate Y position relative to the full range (including negatives)
      final normalizedValue = (maxValue - value) / valueRange;
      final y = padding + (chartHeight * normalizedValue * animationValue);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }

      // Point
      if (animationValue > i / 6) {
        canvas.drawCircle(Offset(x, y), 4, pointPaint);
        canvas.drawCircle(
          Offset(x, y),
          2.5,
          Paint()..color = const Color(0xFF050505),
        );
      }
    }

    canvas.drawPath(path, linePaint);
  }

  String _formatNumber(double number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}万';
    }
    return number.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Month Detail Card
class _MonthDetailCard extends StatefulWidget {
  final String monthLabel;
  final double income;
  final double expense;
  final double savings;
  final double savingsRate;
  final int index;

  const _MonthDetailCard({
    required this.monthLabel,
    required this.income,
    required this.expense,
    required this.savings,
    required this.savingsRate,
    required this.index,
  });

  @override
  State<_MonthDetailCard> createState() => _MonthDetailCardState();
}

class _MonthDetailCardState extends State<_MonthDetailCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(Duration(milliseconds: 30 * widget.index), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number.round());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.monthLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(widget.savingsRate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('収入', widget.income, Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              _buildDetailRow(
                  '支出', widget.expense, Colors.redAccent.withOpacity(0.7)),
              const SizedBox(height: 6),
              _buildDetailRow('貯蓄', widget.savings, Colors.greenAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          '¥ ${_formatNumber(amount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
