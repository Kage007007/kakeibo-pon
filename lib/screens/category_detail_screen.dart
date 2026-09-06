import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../utils/responsive_utils.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class CategoryDetailScreen extends StatefulWidget {
  final int categoryId;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late MainCategory _category;
  List<Transaction> _transactions = [];
  Map<int, double> _monthlyExpenses = {};

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _category = DefaultMainCategories.categories
        .firstWhere((c) => c.id == widget.categoryId);
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
    final allTransactions = await _storage.getTransactions();
    final categoryTransactions = allTransactions
        .where((t) => t.mainCategoryId == widget.categoryId)
        .toList();

    // 過去6ヶ月の支出を計算
    final now = DateTime.now();
    final Map<int, double> monthlyExpenses = {};

    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - (5 - i));
      final monthTransactions = categoryTransactions.where((t) {
        return t.date.year == month.year && t.date.month == month.month;
      });
      final total =
          monthTransactions.fold<double>(0.0, (sum, t) => sum + t.amount);
      monthlyExpenses[i] = total;
    }

    setState(() {
      _transactions = categoryTransactions
        ..sort((a, b) => b.date.compareTo(a.date));
      _monthlyExpenses = monthlyExpenses;
    });
  }

  Future<void> _confirmDelete(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '削除確認',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'この取引を削除してもよろしいですか？',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                '削除',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _storage.deleteTransaction(transaction.id);
      await _loadData();
    }
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number.round());
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final totalExpense =
        _transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
    final averageExpense =
        _transactions.isNotEmpty ? totalExpense / _transactions.length : 0.0;

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
        title: Row(
          children: [
            Text(
              _category.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Text(
              _category.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
                      // サマリーカード
                      _buildSummaryCards(r, totalExpense, averageExpense),
                      r.verticalSpace(24),

                      // 月別推移グラフ
                      _buildMonthlyTrendChart(r),
                      r.verticalSpace(24),

                      // 取引履歴セクション
                      Text(
                        '取引履歴',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      r.verticalSpace(12),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: r.paddingSymmetric(horizontal: 24),
                  sliver: _transactions.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: r.paddingAll(48),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                  ),
                                  r.verticalSpace(16),
                                  Text(
                                    'まだ取引がありません',
                                    style: TextStyle(
                                      fontSize: r.fontSize(16),
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final transaction = _transactions[index];
                              return _TransactionItem(
                                transaction: transaction,
                                onTap: () => _confirmDelete(transaction),
                                index: index,
                              );
                            },
                            childCount: _transactions.length,
                          ),
                        ),
                ),
                SliverToBoxAdapter(
                  child: r.verticalSpace(100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
      ResponsiveUtils r, double totalExpense, double averageExpense) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: r.paddingAll(16),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(r.borderRadius(16)),
              border: Border.all(
                color: Colors.lightBlueAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '累計',
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
                    '¥ ${_formatNumber(totalExpense)}',
                    style: TextStyle(
                      fontSize: r.fontSize(20),
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        r.horizontalSpace(12),
        Expanded(
          child: Container(
            padding: r.paddingAll(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(r.borderRadius(16)),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '平均',
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
                    '¥ ${_formatNumber(averageExpense)}',
                    style: TextStyle(
                      fontSize: r.fontSize(20),
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        r.horizontalSpace(12),
        Expanded(
          child: Container(
            padding: r.paddingAll(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(r.borderRadius(16)),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '取引数',
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
                    '${_transactions.length}件',
                    style: TextStyle(
                      fontSize: r.fontSize(20),
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendChart(ResponsiveUtils r) {
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
            '月別推移（過去6ヶ月）',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          r.verticalSpace(24),
          SizedBox(
            height: 200,
            child: _MonthlyTrendPainter(
              expenses: _monthlyExpenses,
              textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              gridColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendPainter extends StatefulWidget {
  final Map<int, double> expenses;
  final Color textColor;
  final Color gridColor;

  const _MonthlyTrendPainter({
    required this.expenses,
    required this.textColor,
    required this.gridColor,
  });

  @override
  State<_MonthlyTrendPainter> createState() => _MonthlyTrendPainterState();
}

class _MonthlyTrendPainterState extends State<_MonthlyTrendPainter>
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

  String _formatNumber(double number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}万';
    }
    return number.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _LineChartPainter(
            expenses: widget.expenses,
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

class _LineChartPainter extends CustomPainter {
  final Map<int, double> expenses;
  final double animationValue;
  final Color textColor;
  final Color gridColor;

  _LineChartPainter({
    required this.expenses,
    required this.animationValue,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (expenses.isEmpty) return;

    final maxExpense =
        expenses.values.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxExpense == 0) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final segmentWidth = chartWidth / (expenses.length - 1).clamp(1, 999999);

    // グリッドライン
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

    // Y軸ラベル
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 10,
    );

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight * i / 4);
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
        Offset(5, y - textPainter.height / 2),
      );
    }

    // ラインとポイント
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
      final expense = expenses[i] ?? 0;
      final x = padding + (i * segmentWidth);
      final y = padding +
          chartHeight -
          (expense / maxExpense * chartHeight * animationValue);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }

      // ポイント
      if (animationValue > i / 6) {
        canvas.drawCircle(Offset(x, y), 5, pointPaint);
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = const Color(0xFF050505),
        );
      }

      // X軸ラベル（月）
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

  String _formatNumber(double number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}万';
    }
    return number.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TransactionItem extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final int index;

  const _TransactionItem({
    required this.transaction,
    required this.onTap,
    required this.index,
  });

  @override
  State<_TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<_TransactionItem>
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

    // Staggered animation
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
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('yyyy/MM/dd HH:mm')
                                .format(widget.transaction.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.transaction.note != null &&
                              widget.transaction.note!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.transaction.note!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '¥ ${_formatNumber(widget.transaction.amount)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
