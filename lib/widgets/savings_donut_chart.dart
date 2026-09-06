import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../services/theme_service.dart';

class SavingsDonutChart extends StatefulWidget {
  final double income;
  final double expense;
  final VoidCallback? onTap;

  const SavingsDonutChart({
    super.key,
    required this.income,
    required this.expense,
    this.onTap,
  });

  @override
  State<SavingsDonutChart> createState() => _SavingsDonutChartState();
}

class _SavingsDonutChartState extends State<SavingsDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _arcAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ThemeService().currentTheme.animDuration,
      vsync: this,
    );
    _arcAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: ThemeService().currentTheme.animationCurve,
      ),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SavingsDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.income != widget.income || oldWidget.expense != widget.expense) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get savingsRate {
    if (widget.income <= 0) return 0;
    return ((widget.income - widget.expense) / widget.income).clamp(0.0, 1.0);
  }

  double get savings => widget.income - widget.expense;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
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
            '貯蓄率',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _DonutChartPainter(
                      savingsRate: savingsRate,
                      expenseRate: widget.expense / widget.income,
                      animationValue: _arcAnimation.value,
                      primaryColor: Theme.of(context).colorScheme.primary,
                      errorColor: Theme.of(context).colorScheme.error,
                      backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    ),
                    child: Center(
                      child: FadeTransition(
                        opacity: _controller,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: savings),
                              duration: ThemeService().currentTheme.animDuration,
                              curve: ThemeService().currentTheme.animationCurve,
                              builder: (context, value, child) {
                                return Text(
                                  '¥ ${_formatNumber(value)}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: savingsRate * 100),
                              duration: ThemeService().currentTheme.animDuration,
                              curve: ThemeService().currentTheme.animationCurve,
                              builder: (context, value, child) {
                                return Text(
                                  '${value.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '貯蓄額',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend('収入', widget.income, Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 8),
          _buildLegend('支出', widget.expense, Theme.of(context).colorScheme.error),
          const SizedBox(height: 8),
          _buildLegend('貯蓄', savings, Theme.of(context).colorScheme.primary),
        ],
      ),
      ),
    );
  }

  Widget _buildLegend(String label, double amount, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const Spacer(),
        Text(
          '¥ ${_formatNumber(amount)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number.round());
  }
}

class _DonutChartPainter extends CustomPainter {
  final double savingsRate;
  final double expenseRate;
  final double animationValue;
  final Color primaryColor;
  final Color errorColor;
  final Color backgroundColor;

  _DonutChartPainter({
    required this.savingsRate,
    required this.expenseRate,
    required this.animationValue,
    required this.primaryColor,
    required this.errorColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 25.0;

    // 背景（全体）
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // 支出部分 - animated
    final expenseAngle = 2 * math.pi * expenseRate * animationValue;
    final expensePaint = Paint()
      ..color = errorColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (expenseAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -math.pi / 2,
        expenseAngle,
        false,
        expensePaint,
      );
    }

    // 貯蓄部分 - animated
    final savingsAngle = 2 * math.pi * savingsRate * animationValue;
    final savingsPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (savingsAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -math.pi / 2 + expenseAngle,
        savingsAngle,
        false,
        savingsPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
