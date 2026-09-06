import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class IncomeTrendChart extends StatefulWidget {
  final VoidCallback? onTap;
  final Function(int? monthIndex, Map<String, double>? data)? onMonthSelected;

  const IncomeTrendChart({
    super.key,
    this.onTap,
    this.onMonthSelected,
  });

  @override
  State<IncomeTrendChart> createState() => _IncomeTrendChartState();
}

class _IncomeTrendChartState extends State<IncomeTrendChart>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late AnimationController _controller;
  late Animation<double> _animation;
  Map<int, Map<String, double>> _monthlyData = {};
  bool _isLoading = true;
  int? _selectedMonthIndex; // タッチで選択された月のインデックス
  Offset? _tooltipPosition; // ツールチップ表示位置

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
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ウィジェットが更新された時もデータを再読み込み
  @override
  void didUpdateWidget(IncomeTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final Map<int, Map<String, double>> monthlyData = {};

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

      monthlyData[i] = {
        'income': income,
        'expense': expense,
        'savings': savings,
      };
    }

    setState(() {
      _monthlyData = monthlyData;
      _isLoading = false;
    });
    _controller.forward();
  }

  void _handleTouchOnChart(Offset localPosition, Size chartSize, Offset globalOffset) {
    if (_monthlyData.isEmpty) return;

    final padding = 50.0;
    final chartWidth = chartSize.width - padding * 2;
    final segmentWidth = chartWidth / 5;

    // タッチ位置から月のインデックスを計算
    final touchX = localPosition.dx - padding;
    if (touchX < -segmentWidth / 2 || touchX > chartWidth + segmentWidth / 2) {
      setState(() {
        _selectedMonthIndex = null;
        _tooltipPosition = null;
      });
      widget.onMonthSelected?.call(null, null);
      return;
    }

    final monthIndex = ((touchX + segmentWidth / 2) / segmentWidth).floor().clamp(0, 5);

    // データポイントのX座標を計算
    final pointX = padding + (monthIndex * segmentWidth);

    setState(() {
      _selectedMonthIndex = monthIndex;
      // ツールチップ位置（データポイントの上）
      _tooltipPosition = Offset(pointX, localPosition.dy);
    });

    // 親に選択月とデータを通知
    final data = _monthlyData[monthIndex];
    widget.onMonthSelected?.call(monthIndex, data != null ? Map<String, double>.from(data) : null);
  }

  void _clearSelection() {
    setState(() {
      _selectedMonthIndex = null;
      _tooltipPosition = null;
    });
    widget.onMonthSelected?.call(null, null);
  }

  String _getMonthLabel(int index) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month - (5 - index));
    return '${month.month}月';
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '収支推移',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLegendItem('収入', Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                _buildLegendItem('支出', Theme.of(context).colorScheme.error),
                const SizedBox(width: 16),
                _buildLegendItem('貯蓄', Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 280,
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onPanStart: (details) => _handleTouchOnChart(
                                details.localPosition,
                                Size(constraints.maxWidth, constraints.maxHeight),
                                details.globalPosition,
                              ),
                              onPanUpdate: (details) => _handleTouchOnChart(
                                details.localPosition,
                                Size(constraints.maxWidth, constraints.maxHeight),
                                details.globalPosition,
                              ),
                              onPanEnd: (_) => _clearSelection(),
                              onTapDown: (details) => _handleTouchOnChart(
                                details.localPosition,
                                Size(constraints.maxWidth, constraints.maxHeight),
                                details.globalPosition,
                              ),
                              onTapUp: (_) => Future.delayed(
                                const Duration(seconds: 2),
                                () {
                                  if (mounted) _clearSelection();
                                },
                              ),
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: _IncomeTrendChartPainter(
                                      monthlyData: _monthlyData,
                                      animationValue: _animation.value,
                                      textColor: Theme.of(context).colorScheme.onSurface,
                                      gridColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.06),
                                      incomeColor: Theme.of(context).colorScheme.primary,
                                      expenseColor: Theme.of(context).colorScheme.error,
                                      savingsColor: Colors.greenAccent,
                                      selectedMonthIndex: _selectedMonthIndex,
                                    ),
                                    child: const SizedBox.expand(),
                                  );
                                },
                              ),
                            ),
                            // ツールチップ
                            if (_selectedMonthIndex != null && _tooltipPosition != null)
                              Positioned(
                                left: _tooltipPosition!.dx - 75, // ツールチップ幅の半分
                                top: 0, // グラフ上部に固定
                                child: _buildTooltip(context),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(BuildContext context) {
    final data = _monthlyData[_selectedMonthIndex];
    final income = data?['income'] ?? 0.0;
    final expense = data?['expense'] ?? 0.0;
    final savings = data?['savings'] ?? 0.0;
    final formatter = NumberFormat('#,###');

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getMonthLabel(_selectedMonthIndex!),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildTooltipRow('収入', income, Theme.of(context).colorScheme.primary, formatter),
            const SizedBox(height: 4),
            _buildTooltipRow('支出', expense, Theme.of(context).colorScheme.error, formatter),
            const SizedBox(height: 4),
            _buildTooltipRow('貯蓄', savings, Colors.greenAccent, formatter),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltipRow(String label, double value, Color color, NumberFormat formatter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
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
        ),
        Text(
          '¥${formatter.format(value.round())}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
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

// ラベル情報を保持するクラス
class _LabelData {
  final String text;
  final double fontSize;
  final Offset position;
  final Color color;
  final double labelOffset;
  final bool isMaxLabel; // true=上側ラベル, false=下側ラベル

  _LabelData({
    required this.text,
    required this.fontSize,
    required this.position,
    required this.color,
    required this.labelOffset,
    required this.isMaxLabel,
  });
}

class _IncomeTrendChartPainter extends CustomPainter {
  final Map<int, Map<String, double>> monthlyData;
  final double animationValue;
  final Color textColor;
  final Color gridColor;
  final Color incomeColor;
  final Color expenseColor;
  final Color savingsColor;
  final int? selectedMonthIndex;

  _IncomeTrendChartPainter({
    required this.monthlyData,
    required this.animationValue,
    required this.textColor,
    required this.gridColor,
    required this.incomeColor,
    required this.expenseColor,
    required this.savingsColor,
    this.selectedMonthIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (monthlyData.isEmpty) return;

    // Find max and min values (including savings which can be negative)
    double maxValue = 0;
    double minValue = 0;
    for (final data in monthlyData.values) {
      final income = data['income'] ?? 0;
      final expense = data['expense'] ?? 0;
      final savings = data['savings'] ?? 0;
      maxValue = math.max(maxValue, math.max(income, math.max(expense, savings)));
      minValue = math.min(minValue, savings);
    }

    // 全てが0の場合はデフォルトの範囲を設定（グリッドとラベルは表示する）
    final bool allZero = maxValue == 0 && minValue == 0;
    if (allZero) {
      maxValue = 100000; // デフォルトの最大値（10万円）
    }

    // Add padding for better visibility (10%)
    final range = maxValue - minValue;
    maxValue = maxValue + range * 0.1;
    if (minValue < 0) {
      minValue = minValue - range.abs() * 0.1;
    }
    final valueRange = maxValue - minValue > 0 ? maxValue - minValue : 1.0; // 0除算防止

    final padding = 50.0;
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
      color: textColor.withOpacity(0.7),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight * i / 4);
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
        Offset(8, y - textPainter.height / 2),
      );
    }

    // Draw zero line if there are negative values
    if (minValue < 0) {
      final zeroY = padding + ((maxValue - 0) / valueRange) * chartHeight;
      final zeroPaint = Paint()
        ..color = textColor.withOpacity(0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(padding, zeroY),
        Offset(size.width - padding, zeroY),
        zeroPaint,
      );
    }

    // Draw lines and collect label data (without drawing labels yet)
    final List<_LabelData> labelsToRender = [];

    labelsToRender.addAll(_drawLineAndCollectLabels(
      canvas,
      size,
      'income',
      incomeColor,
      padding,
      chartHeight,
      segmentWidth,
      maxValue,
      valueRange,
      labelOffset: 0, // 収入: データポイントに最も近い
    ));

    labelsToRender.addAll(_drawLineAndCollectLabels(
      canvas,
      size,
      'expense',
      expenseColor,
      padding,
      chartHeight,
      segmentWidth,
      maxValue,
      valueRange,
      labelOffset: 28, // 支出: 中間（ラベル高さ+余白を考慮）
    ));

    labelsToRender.addAll(_drawLineAndCollectLabels(
      canvas,
      size,
      'savings',
      savingsColor,
      padding,
      chartHeight,
      segmentWidth,
      maxValue,
      valueRange,
      labelOffset: 56, // 貯蓄: 最も上（確実に重ならない距離）
    ));

    // 選択された月のハイライト
    if (selectedMonthIndex != null) {
      final highlightX = padding + (selectedMonthIndex! * segmentWidth);
      final highlightPaint = Paint()
        ..color = incomeColor.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(
          highlightX - segmentWidth / 2,
          padding,
          segmentWidth,
          chartHeight,
        ),
        highlightPaint,
      );
      // 縦線
      final linePaint = Paint()
        ..color = incomeColor.withOpacity(0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(highlightX, padding),
        Offset(highlightX, padding + chartHeight),
        linePaint,
      );
    }

    // X-axis labels
    for (int i = 0; i < 6; i++) {
      final x = padding + (i * segmentWidth);
      final now = DateTime.now();
      final month = DateTime(now.year, now.month - (5 - i));
      final monthLabel = '${month.month}月';
      final isSelected = selectedMonthIndex == i;
      final xAxisStyle = TextStyle(
        color: isSelected ? incomeColor : textColor.withOpacity(0.6),
        fontSize: isSelected ? 12 : 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: monthLabel,
          style: xAxisStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 22),
      );
    }

    // Draw all labels on top layer with boundary checking
    for (final labelData in labelsToRender) {
      _drawLabelWithBoundary(canvas, size, labelData, padding, chartHeight);
    }
  }

  // 線とポイントを描画し、ラベルデータを収集して返す
  List<_LabelData> _drawLineAndCollectLabels(
    Canvas canvas,
    Size size,
    String key,
    Color color,
    double padding,
    double chartHeight,
    double segmentWidth,
    double maxValue,
    double valueRange, {
    double labelOffset = 0,
  }) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    bool firstPoint = true;
    double maxVal = double.negativeInfinity;
    double minVal = double.infinity;
    Offset? maxPos;
    Offset? minPos;

    for (int i = 0; i < 6; i++) {
      final data = monthlyData[i];
      if (data == null) continue;

      final value = data[key] ?? 0;
      final x = padding + (i * segmentWidth);
      final normalizedValue = (maxValue - value) / valueRange;
      final y = padding + (chartHeight * normalizedValue * animationValue);

      // Track max and min values and positions
      if (value > maxVal) {
        maxVal = value;
        maxPos = Offset(x, y);
      }
      if (value < minVal) {
        minVal = value;
        minPos = Offset(x, y);
      }

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }

      // Point
      if (animationValue > i / 6) {
        canvas.drawCircle(Offset(x, y), 5.5, pointPaint);
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = Colors.white.withOpacity(0.4),
        );
      }
    }

    canvas.drawPath(path, linePaint);

    // Collect label data instead of drawing
    final List<_LabelData> labels = [];

    if (maxPos != null && animationValue > 0.8) {
      final formattedMax = _formatNumberWithSize(maxVal);
      labels.add(_LabelData(
        text: formattedMax['text'] as String,
        fontSize: formattedMax['fontSize'] as double,
        position: maxPos,
        color: color,
        labelOffset: labelOffset,
        isMaxLabel: true,
      ));
    }

    if (minPos != null && animationValue > 0.8 && maxVal != minVal) {
      final formattedMin = _formatNumberWithSize(minVal);
      labels.add(_LabelData(
        text: formattedMin['text'] as String,
        fontSize: formattedMin['fontSize'] as double,
        position: minPos,
        color: color,
        labelOffset: labelOffset,
        isMaxLabel: false,
      ));
    }

    return labels;
  }

  // ラベルを境界チェック付きで描画
  void _drawLabelWithBoundary(
    Canvas canvas,
    Size size,
    _LabelData labelData,
    double padding,
    double chartHeight,
  ) {
    final labelStyle = TextStyle(
      color: Colors.white,
      fontSize: labelData.fontSize,
      fontWeight: FontWeight.w700,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelData.text,
        style: labelStyle,
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final labelPadding = 6.0;
    final labelHeight = textPainter.height + 6;
    final labelWidth = textPainter.width + 12;

    double labelX = labelData.position.dx - labelWidth / 2;
    double labelY;

    if (labelData.isMaxLabel) {
      // 上側ラベル（最大値）
      labelY = labelData.position.dy - labelHeight - 10 - labelData.labelOffset;

      // 上端境界チェック
      if (labelY < padding) {
        labelY = padding;
      }
    } else {
      // 下側ラベル（最小値）
      labelY = labelData.position.dy + 4 + labelData.labelOffset;

      // 下端境界チェック
      final bottomBoundary = padding + chartHeight;
      if (labelY + labelHeight > bottomBoundary) {
        labelY = bottomBoundary - labelHeight;
      }
    }

    // 左右の境界チェック
    if (labelX < padding) {
      labelX = padding;
    } else if (labelX + labelWidth > size.width - padding) {
      labelX = size.width - padding - labelWidth;
    }

    // ラベル背景を描画
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelX, labelY, labelWidth, labelHeight),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      labelRect,
      Paint()..color = labelData.color.withOpacity(0.9),
    );

    // テキストを描画
    textPainter.paint(
      canvas,
      Offset(labelX + labelPadding, labelY + 3),
    );
  }

  // 金額フォーマットとフォントサイズを返す
  Map<String, dynamic> _formatNumberWithSize(double number) {
    final absNumber = number.abs();
    String text;
    double fontSize = 12.0; // デフォルトサイズ

    if (absNumber >= 1000000) {
      // 100万以上：「万」表記を使用
      if (absNumber >= 100000000) {
        // 1億以上：整数表示
        text = '${(number / 10000).toStringAsFixed(0)}万';
        fontSize = 10.0;
      } else if (absNumber >= 10000000) {
        // 1000万以上：小数点1桁
        text = '${(number / 10000).toStringAsFixed(1)}万';
        fontSize = 10.5;
      } else {
        // 100万-1000万：小数点1桁
        text = '${(number / 10000).toStringAsFixed(1)}万';
        fontSize = 11.0;
      }
    } else {
      // 100万未満：1円単位で表示（桁数に応じてフォントサイズ調整）
      text = number.toStringAsFixed(0);

      final digitCount = text.replaceAll('-', '').length; // マイナス記号を除いた桁数
      if (digitCount >= 6) {
        // 6桁 (100,000-999,999)
        fontSize = 9.5;
      } else if (digitCount >= 5) {
        // 5桁 (10,000-99,999)
        fontSize = 10.5;
      } else if (digitCount >= 4) {
        // 4桁 (1,000-9,999)
        fontSize = 11.5;
      } else {
        // 3桁以下 (0-999)
        fontSize = 12.0;
      }
    }

    return {'text': text, 'fontSize': fontSize};
  }

  // 後方互換性のため残す
  String _formatNumber(double number) {
    return _formatNumberWithSize(number)['text'] as String;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
