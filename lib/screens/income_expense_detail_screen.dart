import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../widgets/banner_ad_widget.dart';

// リストアイテムの種類を表す列挙型
enum ListItemType {
  monthData,
  ad,
}

// リストアイテムのラッパークラス（月データと広告を統一的に扱う）
class ListItem {
  final ListItemType type;
  final Map<String, dynamic>? monthData;
  final int? adIndex;

  ListItem.monthData(this.monthData)
      : type = ListItemType.monthData,
        adIndex = null;

  ListItem.ad(this.adIndex)
      : type = ListItemType.ad,
        monthData = null;
}

class IncomeExpenseDetailScreen extends StatefulWidget {
  const IncomeExpenseDetailScreen({super.key});

  @override
  State<IncomeExpenseDetailScreen> createState() =>
      _IncomeExpenseDetailScreenState();
}

class _IncomeExpenseDetailScreenState
    extends State<IncomeExpenseDetailScreen>
    with SingleTickerProviderStateMixin {
  static const int _monthsPerPage = 12; // 1ページあたり12ヶ月
  static const int _adInterval = 6; // 6ヶ月ごとに広告挿入

  final StorageService _storage = StorageService();
  List<Map<String, dynamic>> _allMonthlyData = [];
  List<ListItem> _displayedListItems = []; // 表示用リスト（月データ+広告）
  bool _isLoading = true;

  // ページネーション用の状態
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  DateTime? _oldestLoadedMonth;

  final ScrollController _scrollController = ScrollController();

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

    // スクロールリスナーを追加（無限スクロール用）
    _scrollController.addListener(_onScroll);

    _loadData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// スクロール監視（無限スクロール用）
  void _onScroll() {
    if (_isLoadingMore || !_hasMoreData) return;

    // スクロール位置が80%を超えたら次のページを読み込む
    final scrollPosition = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;

    if (scrollPosition > maxScroll * 0.8) {
      _loadMoreMonths();
    }
  }

  /// 次のページの月データを読み込む
  Future<void> _loadMoreMonths() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 次のページの月データを取得
    final List<Map<String, dynamic>> newData = [];
    final startMonth = _oldestLoadedMonth ?? DateTime.now();

    for (int i = 1; i <= _monthsPerPage; i++) {
      final month = DateTime(startMonth.year, startMonth.month - i);

      // 2020年より前は読み込まない（データがない想定）
      if (month.year < 2020) {
        setState(() {
          _isLoadingMore = false;
          _hasMoreData = false;
        });
        return;
      }

      final income = await _storage.getTotalIncomeForMonth(
        month.year,
        month.month,
      );
      final expense = await _storage.getTotalExpenseForMonth(
        month.year,
        month.month,
      );
      final savings = income - expense;

      newData.add({
        'month': month,
        'income': income,
        'expense': expense,
        'savings': savings,
      });
    }

    setState(() {
      _allMonthlyData.addAll(newData);
      _oldestLoadedMonth = newData.isNotEmpty ? newData.last['month'] : _oldestLoadedMonth;
      _currentPage++;
      _buildDisplayedList();
      _isLoadingMore = false;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMoreData = true;
      _allMonthlyData.clear();
    });

    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    // 最初の12ヶ月分を読み込む
    for (int i = 0; i < _monthsPerPage; i++) {
      final month = DateTime(now.year, now.month - i);
      final income = await _storage.getTotalIncomeForMonth(
        month.year,
        month.month,
      );
      final expense = await _storage.getTotalExpenseForMonth(
        month.year,
        month.month,
      );
      final savings = income - expense;

      data.add({
        'month': month,
        'income': income,
        'expense': expense,
        'savings': savings,
      });
    }

    setState(() {
      _allMonthlyData = data;
      _oldestLoadedMonth = data.isNotEmpty ? data.last['month'] : null;
      _buildDisplayedList();
      _isLoading = false;
    });
  }

  /// 表示用リストを構築（月データ + 広告を定期的に挿入）
  void _buildDisplayedList() {
    final List<ListItem> displayList = [];
    int adCounter = 0;

    for (int i = 0; i < _allMonthlyData.length; i++) {
      // _adInterval個ごとに広告を挿入（最初の1件目の前には挿入しない）
      if (i > 0 && i % _adInterval == 0) {
        displayList.add(ListItem.ad(adCounter));
        adCounter++;
      }

      // 月データを追加
      displayList.add(ListItem.monthData(_allMonthlyData[i]));
    }

    _displayedListItems = displayList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            _slideController.reverse().then((_) {
              Navigator.pop(context);
            });
          },
        ),
        title: Text(
          '収支推移詳細',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
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
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    itemCount: _displayedListItems.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // ローディングインジケーター表示
                      if (index == _displayedListItems.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      }

                      final listItem = _displayedListItems[index];

                      // 広告アイテムの場合
                      if (listItem.type == ListItemType.ad) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: BannerAdWidget.mediumRectangle(),
                        );
                      }

                      // 月データの場合
                      final data = listItem.monthData!;
                      final month = data['month'] as DateTime;
                      final income = data['income'] as double;
                      final expense = data['expense'] as double;
                      final savings = data['savings'] as double;

                      return _MonthCard(
                        month: month,
                        income: income,
                        expense: expense,
                        savings: savings,
                        index: index,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

}

class _MonthCard extends StatefulWidget {
  final DateTime month;
  final double income;
  final double expense;
  final double savings;
  final int index;

  const _MonthCard({
    required this.month,
    required this.income,
    required this.expense,
    required this.savings,
    required this.index,
  });

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard>
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

    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
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
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('yyyy年MM月').format(widget.month),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.savings >= 0
                          ? Colors.greenAccent.withOpacity(0.2)
                          : Theme.of(context).colorScheme.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.savings >= 0 ? '黒字' : '赤字',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.savings >= 0
                            ? Colors.greenAccent
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDataRow(
                '収入',
                widget.income,
                Theme.of(context).colorScheme.primary,
                Icons.arrow_downward,
              ),
              const SizedBox(height: 12),
              _buildDataRow(
                '支出',
                widget.expense,
                Theme.of(context).colorScheme.error,
                Icons.arrow_upward,
              ),
              const SizedBox(height: 16),
              Divider(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                thickness: 1,
              ),
              const SizedBox(height: 16),
              _buildDataRow(
                '貯蓄',
                widget.savings,
                widget.savings >= 0
                    ? Colors.greenAccent
                    : Theme.of(context).colorScheme.error,
                Icons.savings_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, double amount, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Text(
          '¥ ${_formatNumber(amount)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
