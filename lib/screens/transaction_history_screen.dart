import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../services/share_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/share_preview_widget.dart';

enum DateFilter {
  thisMonth,
  lastMonth,
  custom,
}

// 統合取引アイテム（収入と支出を統一的に扱う）
class TransactionItem {
  final String id;
  final DateTime date;
  final double amount;
  final String categoryName;
  final String categoryIcon;
  final bool isIncome;
  final String? note;
  final Transaction? transaction;
  final Income? income;

  TransactionItem({
    required this.id,
    required this.date,
    required this.amount,
    required this.categoryName,
    required this.categoryIcon,
    required this.isIncome,
    this.note,
    this.transaction,
    this.income,
  });

  factory TransactionItem.fromTransaction(Transaction transaction) {
    final category = DefaultMainCategories.getById(transaction.mainCategoryId);
    return TransactionItem(
      id: transaction.id,
      date: transaction.date,
      amount: transaction.amount,
      categoryName: category.name,
      categoryIcon: category.icon,
      isIncome: false,
      note: transaction.note,
      transaction: transaction,
    );
  }

  factory TransactionItem.fromFixedCost(Transaction fixedCost, DateTime displayDate) {
    final category = DefaultMainCategories.getById(fixedCost.mainCategoryId);
    return TransactionItem(
      id: '${fixedCost.id}_${displayDate.year}_${displayDate.month}',
      date: displayDate,
      amount: fixedCost.amount,
      categoryName: category.name,
      categoryIcon: '🔄', // 固定費を示すアイコン
      isIncome: false,
      note: fixedCost.note != null ? '【固定費】${fixedCost.note}' : '【固定費】',
      transaction: fixedCost,
    );
  }

  factory TransactionItem.fromIncome(Income income) {
    return TransactionItem(
      id: income.id,
      date: income.date,
      amount: income.amount,
      categoryName: income.incomeType,
      categoryIcon: _getIncomeIcon(income.incomeType),
      isIncome: true,
      income: income,
    );
  }

  static String _getIncomeIcon(String incomeType) {
    switch (incomeType) {
      case '給与':
        return '💼';
      case 'ボーナス':
        return '🎁';
      case '副収入':
        return '💰';
      default:
        return '💵';
    }
  }
}

// リストアイテムの種類を表す列挙型
enum ListItemType {
  transaction,
  ad,
}

// リストアイテムのラッパークラス（取引と広告を統一的に扱う）
class ListItem {
  final ListItemType type;
  final TransactionItem? transactionItem;
  final int? adIndex;

  ListItem.transaction(this.transactionItem)
      : type = ListItemType.transaction,
        adIndex = null;

  ListItem.ad(this.adIndex)
      : type = ListItemType.ad,
        transactionItem = null;
}

enum InitialFilter {
  all,
  incomeOnly,
  expenseOnly,
}

class TransactionHistoryScreen extends StatefulWidget {
  final InitialFilter initialFilter;

  const TransactionHistoryScreen({
    super.key,
    this.initialFilter = InitialFilter.all,
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  static const int _incomeFilterValue = -1; // 収入フィルター用の特別な値
  static const int _itemsPerPage = 20; // 1ページあたりのアイテム数
  static const int _adInterval = 10; // 広告挿入間隔（10アイテムごとに1つの広告）

  final StorageService _storage = StorageService();
  List<TransactionItem> _allItems = [];
  List<TransactionItem> _filteredItems = [];
  List<ListItem> _displayedListItems = []; // 表示用リスト（取引+広告）
  DateFilter _dateFilter = DateFilter.thisMonth;
  Set<int> _categoryFilters = {}; // 支出カテゴリー複数選択対応
  Set<String> _incomeTypeFilters = {}; // 収入タイプ複数選択対応
  bool _showIncomeOnly = false; // 収入のみ表示フラグ
  bool _showExpenseOnly = false; // 支出のみ表示フラグ
  DateTimeRange? _customDateRange;

  // 収入タイプの定義
  static const List<Map<String, String>> _incomeTypes = [
    {'type': '給与', 'icon': '💼'},
    {'type': 'ボーナス', 'icon': '🎁'},
    {'type': '副収入', 'icon': '💰'},
    {'type': 'その他', 'icon': '💵'},
  ];

  // ページネーション用の状態
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

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

    // 初期フィルターを設定
    switch (widget.initialFilter) {
      case InitialFilter.incomeOnly:
        _showIncomeOnly = true;
        break;
      case InitialFilter.expenseOnly:
        _showExpenseOnly = true;
        break;
      case InitialFilter.all:
        break;
    }

    // スクロールリスナーを追加（無限スクロール用）
    _scrollController.addListener(_onScroll);

    _loadTransactions();
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
      _loadMoreItems();
    }
  }

  /// 次のページのアイテムを読み込む
  void _loadMoreItems() {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 次のページのデータを取得
    final nextPageStartIndex = (_currentPage + 1) * _itemsPerPage;
    if (nextPageStartIndex >= _filteredItems.length) {
      // これ以上データがない
      setState(() {
        _isLoadingMore = false;
        _hasMoreData = false;
      });
      return;
    }

    // 次のページのアイテムを追加
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        _currentPage++;
        _buildDisplayedList();
        _isLoadingMore = false;
      });
    });
  }

  // 固定費を保持
  List<Transaction> _fixedCosts = [];

  Future<void> _loadTransactions() async {
    final transactions = await _storage.getTransactions();
    final incomes = await _storage.getIncomes();

    final List<TransactionItem> items = [];

    // 通常の支出を追加（固定費は別管理）
    for (final transaction in transactions) {
      if (!transaction.isRecurring) {
        items.add(TransactionItem.fromTransaction(transaction));
      }
    }

    // 固定費を別途保持
    _fixedCosts = transactions.where((t) => t.isRecurring).toList();

    // 収入を追加（固定費を除外）
    for (final income in incomes) {
      if (!income.isRecurring) {
        items.add(TransactionItem.fromIncome(income));
      }
    }

    setState(() {
      _allItems = items;
      _currentPage = 0;
      _hasMoreData = true;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<TransactionItem> filtered = List.from(_allItems);

    // 日付フィルター
    final now = DateTime.now();
    int? filterYear;
    int? filterMonth;

    switch (_dateFilter) {
      case DateFilter.thisMonth:
        filterYear = now.year;
        filterMonth = now.month;
        filtered = filtered.where((t) {
          return t.date.year == now.year && t.date.month == now.month;
        }).toList();
        break;
      case DateFilter.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        filterYear = lastMonth.year;
        filterMonth = lastMonth.month;
        filtered = filtered.where((t) {
          return t.date.year == lastMonth.year &&
              t.date.month == lastMonth.month;
        }).toList();
        break;
      case DateFilter.custom:
        if (_customDateRange != null) {
          filtered = filtered.where((t) {
            return t.date.isAfter(_customDateRange!.start
                    .subtract(const Duration(days: 1))) &&
                t.date
                    .isBefore(_customDateRange!.end.add(const Duration(days: 1)));
          }).toList();
        }
        break;
    }

    // 固定費を追加（今月・先月フィルターの場合のみ）
    if (filterYear != null && filterMonth != null && !_showIncomeOnly) {
      for (final fixedCost in _fixedCosts) {
        // 固定費の登録月が指定月以前なら表示
        if (fixedCost.date.year < filterYear ||
            (fixedCost.date.year == filterYear && fixedCost.date.month <= filterMonth)) {
          // その月の1日として表示（固定費マーク付き）
          final displayDate = DateTime(filterYear, filterMonth, 1);
          filtered.add(TransactionItem.fromFixedCost(fixedCost, displayDate));
        }
      }
    }

    // カテゴリーフィルター（複数選択対応）
    if (_showIncomeOnly) {
      // 収入のみ表示
      filtered = filtered.where((t) => t.isIncome).toList();
      // さらに収入タイプでフィルター
      if (_incomeTypeFilters.isNotEmpty) {
        filtered = filtered.where((t) {
          if (t.income != null) {
            return _incomeTypeFilters.contains(t.income!.incomeType);
          }
          return false;
        }).toList();
      }
    } else if (_showExpenseOnly) {
      // 支出のみ表示
      filtered = filtered.where((t) => !t.isIncome).toList();
      // さらに支出カテゴリーでフィルター
      if (_categoryFilters.isNotEmpty) {
        filtered = filtered.where((t) {
          if (t.transaction != null) {
            return _categoryFilters.contains(t.transaction!.mainCategoryId);
          }
          return false;
        }).toList();
      }
    } else if (_categoryFilters.isNotEmpty || _incomeTypeFilters.isNotEmpty) {
      // 支出カテゴリーまたは収入タイプでフィルター（複数選択）
      filtered = filtered.where((t) {
        if (t.transaction != null && _categoryFilters.isNotEmpty) {
          return _categoryFilters.contains(t.transaction!.mainCategoryId);
        }
        if (t.income != null && _incomeTypeFilters.isNotEmpty) {
          return _incomeTypeFilters.contains(t.income!.incomeType);
        }
        return false;
      }).toList();
    }

    // 日付の降順でソート
    filtered.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _filteredItems = filtered;
      _buildDisplayedList();
    });
  }

  /// 表示用リストを構築（取引アイテム + 広告を定期的に挿入）
  void _buildDisplayedList() {
    final List<ListItem> displayList = [];

    // 現在のページまでのアイテム数を計算
    final endIndex = ((_currentPage + 1) * _itemsPerPage).clamp(0, _filteredItems.length);

    int adCounter = 0;

    for (int i = 0; i < endIndex; i++) {
      // _adInterval個ごとに広告を挿入（最初の1件目の前には挿入しない）
      if (i > 0 && i % _adInterval == 0) {
        displayList.add(ListItem.ad(adCounter));
        adCounter++;
      }

      // 取引アイテムを追加
      displayList.add(ListItem.transaction(_filteredItems[i]));
    }

    _displayedListItems = displayList;
    _hasMoreData = endIndex < _filteredItems.length;
  }

  Future<void> _showDateFilterMenu() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption(
                '今月',
                DateFilter.thisMonth,
                Icons.calendar_today,
              ),
              const SizedBox(height: 12),
              _buildFilterOption(
                '先月',
                DateFilter.lastMonth,
                Icons.calendar_month,
              ),
              const SizedBox(height: 12),
              _buildFilterOption(
                'カスタム期間',
                DateFilter.custom,
                Icons.date_range,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, DateFilter filter, IconData icon) {
    final isSelected = _dateFilter == filter;
    final theme = Theme.of(context);
    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(0.2)
          : theme.colorScheme.onSurface.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () async {
          if (filter == DateFilter.custom) {
            Navigator.pop(context);
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) {
                final isDark = theme.brightness == Brightness.dark;
                return Theme(
                  data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
                    colorScheme: ColorScheme(
                      primary: theme.colorScheme.primary,
                      onPrimary: isDark ? Colors.white : Colors.black,
                      surface: theme.colorScheme.surface,
                      onSurface: theme.colorScheme.onSurface,
                      background: theme.colorScheme.background,
                      onBackground: theme.colorScheme.onBackground,
                      secondary: theme.colorScheme.primary,
                      onSecondary: theme.colorScheme.onPrimary,
                      error: theme.colorScheme.error,
                      onError: Colors.white,
                      brightness: theme.brightness,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (range != null) {
              setState(() {
                _dateFilter = filter;
                _customDateRange = range;
                _applyFilters();
              });
            }
          } else {
            setState(() {
              _dateFilter = filter;
              _applyFilters();
            });
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCategoryFilterMenu() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ヘッダー
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'カテゴリーフィルター',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _categoryFilters.clear();
                                _incomeTypeFilters.clear();
                                _showIncomeOnly = false;
                                _showExpenseOnly = false;
                                _currentPage = 0;
                                _hasMoreData = true;
                                _applyFilters();
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              'リセット',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // フィルターオプション
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // 基本フィルター
                            _buildCategoryOption(
                              '全て',
                              null,
                              '🌐',
                              isAllOption: true,
                              setModalState: setModalState,
                            ),
                            const SizedBox(height: 12),
                            _buildCategoryOption(
                              '収入のみ',
                              _incomeFilterValue,
                              '💰',
                              isIncomeOption: true,
                              setModalState: setModalState,
                            ),
                            const SizedBox(height: 12),
                            _buildCategoryOption(
                              '支出のみ',
                              _incomeFilterValue,
                              '💸',
                              isExpenseOption: true,
                              setModalState: setModalState,
                            ),
                            const SizedBox(height: 20),
                            // 収入カテゴリーセクション
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '収入カテゴリー（複数選択可）',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                            ..._incomeTypes.map((incomeType) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildIncomeTypeOption(
                                  incomeType['type']!,
                                  incomeType['icon']!,
                                  setModalState: setModalState,
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            // 支出カテゴリーセクション
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '支出カテゴリー（複数選択可）',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                            ...DefaultMainCategories.categories.map((category) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildCategoryOption(
                                  category.name,
                                  category.id,
                                  category.icon,
                                  setModalState: setModalState,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      // 適用ボタン
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentPage = 0;
                              _hasMoreData = true;
                              _applyFilters();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'フィルターを適用',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryOption(
    String label,
    int? categoryId,
    String icon, {
    bool isAllOption = false,
    bool isIncomeOption = false,
    bool isExpenseOption = false,
    required StateSetter setModalState,
  }) {
    // 選択状態の判定
    bool isSelected;
    if (isAllOption) {
      isSelected = _categoryFilters.isEmpty && _incomeTypeFilters.isEmpty && !_showIncomeOnly && !_showExpenseOnly;
    } else if (isIncomeOption) {
      isSelected = _showIncomeOnly;
    } else if (isExpenseOption) {
      isSelected = _showExpenseOnly;
    } else {
      isSelected = _categoryFilters.contains(categoryId);
    }

    final theme = Theme.of(context);
    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(0.2)
          : theme.colorScheme.onSurface.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          setModalState(() {
            if (isAllOption) {
              // 全てを選択 - フィルターをクリア
              _categoryFilters.clear();
              _incomeTypeFilters.clear();
              _showIncomeOnly = false;
              _showExpenseOnly = false;
            } else if (isIncomeOption) {
              // 収入のみを選択
              _showIncomeOnly = !_showIncomeOnly;
              if (_showIncomeOnly) {
                _showExpenseOnly = false;
                _categoryFilters.clear();
              }
            } else if (isExpenseOption) {
              // 支出のみを選択
              _showExpenseOnly = !_showExpenseOnly;
              if (_showExpenseOnly) {
                _showIncomeOnly = false;
                _incomeTypeFilters.clear();
              }
            } else if (categoryId != null) {
              // 支出カテゴリーをトグル
              _showIncomeOnly = false;
              if (_categoryFilters.contains(categoryId)) {
                _categoryFilters.remove(categoryId);
              } else {
                _categoryFilters.add(categoryId);
              }
            }
          });
          // 親のstateも更新
          setState(() {});
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              // チェックボックス風のアイコン
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeTypeOption(
    String incomeType,
    String icon, {
    required StateSetter setModalState,
  }) {
    final isSelected = _incomeTypeFilters.contains(incomeType);
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? Colors.greenAccent.withOpacity(0.2)
          : theme.colorScheme.onSurface.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          setModalState(() {
            // 収入タイプをトグル
            _showExpenseOnly = false;
            if (_incomeTypeFilters.contains(incomeType)) {
              _incomeTypeFilters.remove(incomeType);
            } else {
              _incomeTypeFilters.add(incomeType);
            }
          });
          // 親のstateも更新
          setState(() {});
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  incomeType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.greenAccent : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              // チェックボックス風のアイコン
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.greenAccent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? Colors.greenAccent
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(TransactionItem item) async {
    final TextEditingController amountController = TextEditingController(
      text: item.amount.round().toString(),
    );
    final TextEditingController noteController = TextEditingController(
      text: item.note ?? '',
    );
    DateTime selectedDate = item.date;
    int? selectedCategoryId = item.transaction?.mainCategoryId;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Text(
                    item.categoryIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.isIncome ? '収入を編集' : '取引を編集',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 日付選択
                    Text(
                      '日付',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: theme.colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              final isDark = theme.brightness == Brightness.dark;
                              return Theme(
                                data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
                                  colorScheme: ColorScheme(
                                    primary: theme.colorScheme.primary,
                                    onPrimary: isDark ? Colors.white : Colors.black,
                                    surface: theme.colorScheme.surface,
                                    onSurface: theme.colorScheme.onSurface,
                                    background: theme.colorScheme.background,
                                    onBackground: theme.colorScheme.onBackground,
                                    secondary: theme.colorScheme.primary,
                                    onSecondary: theme.colorScheme.onPrimary,
                                    error: theme.colorScheme.error,
                                    onError: Colors.white,
                                    brightness: theme.brightness,
                                  ),
                                  textTheme: TextTheme(
                                    headlineMedium: TextStyle(color: theme.colorScheme.onSurface),
                                    bodyLarge: TextStyle(color: theme.colorScheme.onSurface),
                                    bodyMedium: TextStyle(color: theme.colorScheme.onSurface),
                                    labelLarge: TextStyle(color: theme.colorScheme.onSurface),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('yyyy年MM月dd日').format(selectedDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 金額入力
                    Text(
                      '金額',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        prefixText: '¥ ',
                        prefixStyle: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // カテゴリー選択（支出のみ）
                    if (!item.isIncome) ...[
                      Text(
                        'カテゴリー',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: theme.colorScheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () async {
                            final selected = await showModalBottomSheet<int>(
                              context: context,
                              backgroundColor: theme.colorScheme.surface,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) {
                                final categoryTheme = Theme.of(context);
                                return SingleChildScrollView(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: DefaultMainCategories.categories.map((category) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Material(
                                            color: categoryTheme.colorScheme.onSurface.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(12),
                                            child: InkWell(
                                              onTap: () => Navigator.pop(context, category.id),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Row(
                                                  children: [
                                                    Text(category.icon, style: const TextStyle(fontSize: 24)),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      category.name,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: categoryTheme.colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            );
                            if (selected != null) {
                              setDialogState(() {
                                selectedCategoryId = selected;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Text(
                                  DefaultMainCategories.getById(selectedCategoryId ?? 8).icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DefaultMainCategories.getById(selectedCategoryId ?? 8).name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // メモ入力
                    Text(
                      'メモ',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        hintText: 'メモを入力（任意）',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _confirmDelete(item);
                  },
                  child: Text(
                    '削除',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'キャンセル',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('正しい金額を入力してください')),
                      );
                      return;
                    }

                    if (item.transaction != null) {
                      // 支出の更新
                      final updatedTransaction = item.transaction!.copyWith(
                        date: selectedDate,
                        amount: amount,
                        mainCategoryId: selectedCategoryId,
                        note: noteController.text.isEmpty ? null : noteController.text,
                      );
                      await _storage.updateTransaction(updatedTransaction);
                    } else if (item.income != null) {
                      // 収入の更新
                      final updatedIncome = item.income!.copyWith(
                        date: selectedDate,
                        amount: amount,
                      );
                      await _storage.updateIncome(updatedIncome);
                    }

                    Navigator.pop(context);
                    await _loadTransactions();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(item.isIncome ? '収入を更新しました' : '取引を更新しました'),
                          backgroundColor: Colors.greenAccent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(TransactionItem item) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '削除確認',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            item.isIncome ? 'この収入を削除してもよろしいですか？' : 'この取引を削除してもよろしいですか？',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'キャンセル',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                '削除',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (item.transaction != null) {
        await _storage.deleteTransaction(item.id);
      } else if (item.income != null) {
        await _storage.deleteIncome(item.id);
      }
      await _loadTransactions();
    }
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number.round());
  }

  String _getDateFilterLabel() {
    switch (_dateFilter) {
      case DateFilter.thisMonth:
        return '今月';
      case DateFilter.lastMonth:
        return '先月';
      case DateFilter.custom:
        if (_customDateRange != null) {
          final start = DateFormat('MM/dd').format(_customDateRange!.start);
          final end = DateFormat('MM/dd').format(_customDateRange!.end);
          return '$start - $end';
        }
        return 'カスタム';
    }
  }

  String _getCategoryFilterLabel() {
    if (_showIncomeOnly) {
      if (_incomeTypeFilters.isEmpty) return '💰 収入のみ';
      if (_incomeTypeFilters.length == 1) {
        final type = _incomeTypeFilters.first;
        final icon = _incomeTypes.firstWhere((t) => t['type'] == type)['icon']!;
        return '$icon $type';
      }
      return '💰 ${_incomeTypeFilters.length}件選択';
    }
    if (_showExpenseOnly) {
      if (_categoryFilters.isEmpty) return '💸 支出のみ';
      if (_categoryFilters.length == 1) {
        final categoryId = _categoryFilters.first;
        final category = DefaultMainCategories.categories
            .firstWhere((c) => c.id == categoryId);
        return '${category.icon} ${category.name}';
      }
      return '💸 ${_categoryFilters.length}件選択';
    }

    final totalSelected = _categoryFilters.length + _incomeTypeFilters.length;
    if (totalSelected == 0) return '全て';
    if (totalSelected == 1) {
      if (_categoryFilters.isNotEmpty) {
        final categoryId = _categoryFilters.first;
        final category = DefaultMainCategories.categories
            .firstWhere((c) => c.id == categoryId);
        return '${category.icon} ${category.name}';
      } else {
        final type = _incomeTypeFilters.first;
        final icon = _incomeTypes.firstWhere((t) => t['type'] == type)['icon']!;
        return '$icon $type';
      }
    }
    return '$totalSelected件選択中';
  }

  Future<void> _showShareSummaryDialog() async {
    final previewKey = GlobalKey();
    final total = _filteredItems.fold<double>(
      0.0,
      (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '取引履歴をシェア',
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
                  child: TransactionSummarySharePreview(
                    dateRange: _getDateFilterLabel(),
                    categoryFilter: _getCategoryFilterLabel(),
                    totalAmount: total,
                    transactionCount: _filteredItems.length,
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
                await ShareService().shareTransactionSummary(
                  dateRange: _getDateFilterLabel(),
                  categoryFilter: _getCategoryFilterLabel(),
                  totalAmount: total,
                  transactionCount: _filteredItems.length,
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

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final total = _filteredItems.fold<double>(
      0.0,
      (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
    );

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
          '取引履歴',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
            onPressed: _showShareSummaryDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Column(
            children: [
              // フィルターバー
              Container(
                padding: r.paddingAll(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterChip(
                            _getDateFilterLabel(),
                            Icons.calendar_today,
                            _showDateFilterMenu,
                          ),
                        ),
                        r.horizontalSpace(12),
                        Expanded(
                          child: _buildFilterChip(
                            _getCategoryFilterLabel(),
                            Icons.category,
                            _showCategoryFilterMenu,
                          ),
                        ),
                      ],
                    ),
                    r.verticalSpace(12),
                    // 合計表示
                    Container(
                      padding: r.paddingSymmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(r.borderRadius(12)),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '合計: ${_filteredItems.length}件',
                            style: TextStyle(
                              fontSize: r.fontSize(14),
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            '¥ ${_formatNumber(total)}',
                            style: TextStyle(
                              fontSize: r.fontSize(18),
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 取引リスト
              Expanded(
                child: _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            r.verticalSpace(16),
                            Text(
                              '取引がありません',
                              style: TextStyle(
                                fontSize: r.fontSize(16),
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: r.paddingAll(16),
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
                              padding: const EdgeInsets.only(bottom: 12),
                              child: BannerAdWidget.mediumRectangle(),
                            );
                          }

                          // 取引アイテムの場合
                          final item = listItem.transactionItem!;
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Text(
                                    item.isIncome ? '収入を削除' : '取引を削除',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  content: Text(
                                    item.isIncome
                                        ? '「${item.categoryName}」を削除しますか?'
                                        : '「${item.categoryName}${item.note != null ? " - ${item.note}" : ""}」を削除しますか?',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text(
                                        'キャンセル',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        '削除',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              if (item.transaction != null) {
                                await _storage.deleteTransaction(item.id);
                              } else if (item.income != null) {
                                await _storage.deleteIncome(item.id);
                              }
                              await _loadTransactions();
                            },
                            child: _TransactionCard(
                              item: item,
                              onTap: () => _showEditDialog(item),
                              index: index,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final TransactionItem item;
  final VoidCallback onTap;
  final int index;

  const _TransactionCard({
    required this.item,
    required this.onTap,
    required this.index,
  });

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard>
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

    // ステージングアニメーション
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
    // 収入は緑色、支出は青色
    final amountColor = widget.item.isIncome
        ? Colors.greenAccent
        : Theme.of(context).colorScheme.primary;
    final iconBgColor = widget.item.isIncome
        ? Colors.greenAccent.withOpacity(0.1)
        : Theme.of(context).colorScheme.primary.withOpacity(0.1);

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
                    // カテゴリーアイコン
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.item.categoryIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // カテゴリー名、メモ、日付
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.categoryName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (widget.item.note != null && widget.item.note!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.item.note!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('yyyy/MM/dd HH:mm')
                                .format(widget.item.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 金額
                    Text(
                      '${widget.item.isIncome ? "+" : ""}¥ ${_formatNumber(widget.item.amount)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: amountColor,
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
