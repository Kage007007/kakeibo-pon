import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/category.dart';

class MonthComparisonChart extends StatefulWidget {
  final Map<int, double> currentMonthExpenses;
  final Map<int, double> previousMonthExpenses;
  final Function(int categoryId)? onCategoryTap;

  const MonthComparisonChart({
    super.key,
    required this.currentMonthExpenses,
    required this.previousMonthExpenses,
    this.onCategoryTap,
  });

  @override
  State<MonthComparisonChart> createState() => _MonthComparisonChartState();
}

class _MonthComparisonChartState extends State<MonthComparisonChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(MonthComparisonChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMonthExpenses != widget.currentMonthExpenses ||
        oldWidget.previousMonthExpenses != widget.previousMonthExpenses) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '対前月比較',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem('今月', Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              _buildLegendItem('前月', Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return GestureDetector(
                  onTapDown: (details) {
                    if (widget.onCategoryTap == null) return;

                    final categories = DefaultMainCategories.categories;
                    const leftPadding = 50.0;
                    const rightPadding = 10.0;
                    final chartWidth = context.size!.width - leftPadding - rightPadding;
                    final segmentWidth = chartWidth / categories.length;

                    for (int i = 0; i < categories.length; i++) {
                      final segmentStart = leftPadding + (i * segmentWidth);
                      final segmentEnd = leftPadding + ((i + 1) * segmentWidth);

                      if (details.localPosition.dx >= segmentStart &&
                          details.localPosition.dx <= segmentEnd) {
                        widget.onCategoryTap!(categories[i].id);
                        break;
                      }
                    }
                  },
                  child: CustomPaint(
                    painter: _BarChartPainter(
                      currentMonthExpenses: widget.currentMonthExpenses,
                      previousMonthExpenses: widget.previousMonthExpenses,
                      animationValue: _barAnimation.value,
                      primaryColor: Theme.of(context).colorScheme.primary,
                      errorColor: Theme.of(context).colorScheme.error,
                      previousColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      textColor: Theme.of(context).colorScheme.onSurface,
                      gridColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<int, double> currentMonthExpenses;
  final Map<int, double> previousMonthExpenses;
  final double animationValue;
  final Color primaryColor;
  final Color errorColor;
  final Color previousColor;
  final Color textColor;
  final Color gridColor;

  _BarChartPainter({
    required this.currentMonthExpenses,
    required this.previousMonthExpenses,
    required this.animationValue,
    required this.primaryColor,
    required this.errorColor,
    required this.previousColor,
    required this.textColor,
    required this.gridColor,
  });

  String _formatNumber(double number) {
    if (number.abs() >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}万';
    }
    return number.toStringAsFixed(0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final categories = DefaultMainCategories.categories;
    final maxExpense = _getMaxExpense();

    if (maxExpense == 0) return;

    // パディング設定
    final leftPadding = 50.0;
    final rightPadding = 10.0;
    final bottomPadding = 30.0;
    final topPadding = 20.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final barWidth = chartWidth / (categories.length * 2.5);

    // グリッド線とY軸ラベル
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: textColor.withOpacity(0.7),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight * i / 4);

      // グリッド線
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      // Y軸ラベル
      final value = maxExpense * (1 - i / 4);
      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatNumber(value),
          style: textStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(8, y - textPainter.height / 2),
      );
    }

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final currentExpense = currentMonthExpenses[category.id] ?? 0;
      final previousExpense = previousMonthExpenses[category.id] ?? 0;

      final x = leftPadding + (i * chartWidth / categories.length) + barWidth / 2;

      // 前月の棒（背景） - animated from bottom
      if (previousExpense > 0) {
        final previousHeight = (previousExpense / maxExpense) * chartHeight * animationValue;
        final previousPaint = Paint()
          ..color = previousColor
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x - barWidth / 2,
              topPadding + chartHeight - previousHeight,
              barWidth,
              previousHeight,
            ),
            const Radius.circular(6),
          ),
          previousPaint,
        );
      }

      // 今月の棒（前面） - animated from bottom
      if (currentExpense > 0) {
        final currentHeight = (currentExpense / maxExpense) * chartHeight * animationValue;
        final isIncrease = currentExpense > previousExpense;
        final isDecrease = currentExpense < previousExpense && previousExpense > 0;
        final currentPaint = Paint()
          ..color = isIncrease
              ? errorColor.withOpacity(0.8)
              : primaryColor
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x - barWidth / 2 + barWidth * 0.3,
              topPadding + chartHeight - currentHeight,
              barWidth * 0.7,
              currentHeight,
            ),
            const Radius.circular(6),
          ),
          currentPaint,
        );

        // Celebration emoji for reduced expenses
        if (isDecrease && animationValue > 0.8 && (previousExpense - currentExpense) / previousExpense > 0.1) {
          final emojiPainter = TextPainter(
            text: const TextSpan(
              text: '🎉',
              style: TextStyle(fontSize: 16),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final emojiOpacity = ((animationValue - 0.8) / 0.2).clamp(0.0, 1.0);
          if (emojiOpacity > 0) {
            canvas.save();
            canvas.translate(x - emojiPainter.width / 2, topPadding + chartHeight - currentHeight - 20 - (5 * emojiOpacity));
            final paint = Paint()..color = Colors.white.withOpacity(emojiOpacity);
            emojiPainter.paint(canvas, Offset.zero);
            canvas.restore();
          }
        }

        // 差分の矢印表示
        if ((currentExpense - previousExpense).abs() > maxExpense * 0.05 && animationValue > 0.7) {
          _drawDifferenceIndicator(
            canvas,
            x,
            topPadding + chartHeight - currentHeight - 15,
            currentExpense - previousExpense,
          );
        }
      }

      // カテゴリーアイコンは常に表示
      final textPainter = TextPainter(
        text: TextSpan(
          text: category.icon,
          style: const TextStyle(fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 15),
      );
    }
  }

  void _drawDifferenceIndicator(
      Canvas canvas, double x, double y, double difference) {
    final isIncrease = difference > 0;
    final paint = Paint()
      ..color = isIncrease ? errorColor : primaryColor
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isIncrease) {
      // 上向き矢印
      path.moveTo(x, y - 8);
      path.lineTo(x - 4, y - 2);
      path.lineTo(x + 4, y - 2);
    } else {
      // 下向き矢印
      path.moveTo(x, y + 8);
      path.lineTo(x - 4, y + 2);
      path.lineTo(x + 4, y + 2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _getMaxExpense() {
    final allExpenses = [
      ...currentMonthExpenses.values,
      ...previousMonthExpenses.values,
    ];
    if (allExpenses.isEmpty) return 0;
    return allExpenses.reduce((a, b) => a > b ? a : b);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
