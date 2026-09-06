import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/income.dart';
import '../services/storage_service.dart';
import '../widgets/custom_numpad.dart';
import '../widgets/category_button.dart';
import '../utils/responsive_utils.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen>
    with TickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final PageController _pageController = PageController();
  String _amountText = '';
  int? _selectedMainCategoryId;
  int? _selectedIncomeCategoryId;
  int? _predictedCategoryId;
  List<SubCategory> _subCategories = [];
  int _currentPageIndex = 0; // 0: 支出, 1: 収入
  String? _note; // メモ
  DateTime _selectedDate = DateTime.now(); // 選択された日付

  late AnimationController _saveAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _amountScaleController;
  late Animation<double> _amountScaleAnimation;

  @override
  void initState() {
    super.initState();

    // 保存アニメーション
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _saveAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.3),
    ).animate(
      CurvedAnimation(
        parent: _saveAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 金額入力時のスケールアニメーション
    _amountScaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _amountScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _amountScaleController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _saveAnimationController.dispose();
    _amountScaleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNumberTap(String value) {
    setState(() {
      if (value == '.' && _amountText.contains('.')) return;

      // 入力上限チェック（999,999,999円まで）
      final newAmountText = _amountText + value;
      final newAmount = double.tryParse(newAmountText);
      if (newAmount != null && newAmount > 999999999) {
        return; // 上限を超える場合は入力を無視
      }

      _amountText += value;
      _updatePrediction();
    });

    // 金額入力時のスケールアニメーション
    _amountScaleController.forward().then((_) {
      _amountScaleController.reverse();
    });
  }

  void _onDelete() {
    setState(() {
      if (_amountText.isNotEmpty) {
        _amountText = _amountText.substring(0, _amountText.length - 1);
        _updatePrediction();
      }
    });
  }

  void _onClear() {
    setState(() {
      _amountText = '';
      _selectedMainCategoryId = null;
      _selectedIncomeCategoryId = null;
      _predictedCategoryId = null;
      _note = null;
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updatePrediction() async {
    // 予測は支出ページでのみ有効
    if (_currentPageIndex != 0) {
      setState(() {
        _predictedCategoryId = null;
      });
      return;
    }

    final amount = double.tryParse(_amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _predictedCategoryId = null;
      });
      return;
    }

    final frequency = await _storage.getCategoryFrequencyByAmount(amount);
    if (frequency.isEmpty) {
      setState(() {
        _predictedCategoryId = null;
      });
      return;
    }

    // 最も頻度が高い費目を予測
    final predictedId = frequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    setState(() {
      _predictedCategoryId = predictedId;
      // ユーザーがまだ費目を選択していない場合、予測された費目を自動選択
      if (_selectedMainCategoryId == null) {
        _selectedMainCategoryId = predictedId;
      }
    });
  }

  Future<void> _onCategoryTap(int categoryId) async {
    final subCategories =
        await _storage.getSubCategoriesByMainId(categoryId);

    setState(() {
      _selectedMainCategoryId = categoryId;
      _selectedIncomeCategoryId = null;
      _subCategories = subCategories;
    });
  }

  Future<void> _onCategoryLongPress(int categoryId) async {
    final TextEditingController noteController = TextEditingController(
      text: _note ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'メモを入力',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: noteController,
            autofocus: true,
            maxLines: 3,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: '例: 電気代、ガス代など',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(
                'キャンセル',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, noteController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '保存',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _note = result.isEmpty ? null : result;
      });

      // メモを保存したら、そのカテゴリーを選択
      await _onCategoryTap(categoryId);
    }
  }

  void _onIncomeCategoryTap(int categoryId) {
    setState(() {
      _selectedIncomeCategoryId = categoryId;
      _selectedMainCategoryId = null;
      _subCategories = [];
    });
  }

  Future<void> _onConfirm() async {
    // 収入ページの場合
    if (_currentPageIndex == 1) {
      if (_selectedIncomeCategoryId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('収入源を選択してください'),
              duration: const Duration(milliseconds: 800),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent.withOpacity(0.9),
            ),
          );
        }
        return;
      }
      await _saveIncome();
      return;
    }

    // 支出ページの場合
    if (_selectedMainCategoryId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('費目を選択してください'),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent.withOpacity(0.9),
          ),
        );
      }
      return;
    }

    // サブカテゴリの選択を省略して直接保存
    await _saveTransaction(null);
  }

  void _showSubCategoryModal() {
    showModalBottomSheet(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '詳細を選択',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._subCategories.map((sub) {
                    return _buildSubCategoryChip(sub);
                  }),
                  _buildSubCategoryChip(null, label: 'なし'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubCategoryChip(SubCategory? subCategory, {String? label}) {
    return Material(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _saveTransaction(subCategory?.id);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label ?? subCategory!.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction(String? subCategoryId) async {
    final amount = double.tryParse(_amountText);

    // 選択されたカテゴリーがない場合、予測されたカテゴリーを使用
    final categoryId = _selectedMainCategoryId ?? _predictedCategoryId;

    if (amount == null ||
        amount <= 0 ||
        categoryId == null) {
      return;
    }

    final transaction = Transaction(
      date: _selectedDate,
      amount: amount,
      mainCategoryId: categoryId,
      subCategoryId: subCategoryId,
      note: _note,
    );

    await _storage.saveTransaction(transaction);

    // 保存アニメーション実行
    await _saveAnimationController.forward();

    setState(() {
      _amountText = '';
      _selectedMainCategoryId = null;
      _predictedCategoryId = null;
      _note = null;
      _selectedDate = DateTime.now();
    });

    _saveAnimationController.reset();

    // フィードバック
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('保存しました'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
        ),
      );
    }
  }

  Future<void> _saveIncome() async {
    final amount = double.tryParse(_amountText);
    if (amount == null ||
        amount <= 0 ||
        _selectedIncomeCategoryId == null) {
      return;
    }

    final incomeCategory = DefaultIncomeCategories.getById(_selectedIncomeCategoryId!);
    final income = Income(
      date: _selectedDate,
      amount: amount,
      incomeType: incomeCategory.name,
      isRecurring: false,
    );

    await _storage.saveIncome(income);

    // 保存アニメーション実行
    await _saveAnimationController.forward();

    setState(() {
      _amountText = '';
      _selectedIncomeCategoryId = null;
      _selectedDate = DateTime.now();
    });

    _saveAnimationController.reset();

    // フィードバック
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('収入を保存しました'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
        ),
      );
    }
  }

  String get _formattedAmount {
    if (_amountText.isEmpty) return '¥ 0';
    final amount = double.tryParse(_amountText) ?? 0;
    return '¥ ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  String _formatSelectedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selected == today) {
      return '今日';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return '昨日';
    } else if (_selectedDate.year == now.year) {
      return DateFormat('M/d').format(_selectedDate);
    } else {
      return DateFormat('yyyy/M/d').format(_selectedDate);
    }
  }

  Widget _buildPageIndicator(int pageIndex, String label) {
    final isActive = _currentPageIndex == pageIndex;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCategoriesPage(ResponsiveUtils r) {
    return Container(
      padding: r.paddingAll(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: r.gridColumns(4),
          childAspectRatio: 0.9,
          crossAxisSpacing: r.spacing(12),
          mainAxisSpacing: r.spacing(12),
        ),
        itemCount: DefaultMainCategories.categories.length,
        itemBuilder: (context, index) {
          final category = DefaultMainCategories.categories[index];
          return CategoryButton(
            category: category,
            isSelected: _selectedMainCategoryId == category.id,
            isPredicted: _predictedCategoryId == category.id,
            onTap: () => _onCategoryTap(category.id),
            onLongPress: () => _onCategoryLongPress(category.id),
          );
        },
      ),
    );
  }

  Widget _buildIncomeCategoriesPage(ResponsiveUtils r) {
    return Container(
      padding: r.paddingAll(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: r.gridColumns(4),
          childAspectRatio: 0.9,
          crossAxisSpacing: r.spacing(12),
          mainAxisSpacing: r.spacing(12),
        ),
        itemCount: DefaultIncomeCategories.categories.length,
        itemBuilder: (context, index) {
          final category = DefaultIncomeCategories.categories[index];
          return _buildIncomeCategoryButton(category, r);
        },
      ),
    );
  }

  Widget _buildIncomeCategoryButton(IncomeCategory category, ResponsiveUtils r) {
    final isSelected = _selectedIncomeCategoryId == category.id;

    Color backgroundColor;
    Color borderColor;

    if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.3);
      borderColor = Theme.of(context).colorScheme.primary;
    } else {
      backgroundColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.05);
      borderColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.1);
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(r.borderRadius(16)),
      child: InkWell(
        onTap: () => _onIncomeCategoryTap(category.id),
        borderRadius: BorderRadius.circular(r.borderRadius(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r.borderRadius(16)),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          padding: r.paddingSymmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    category.icon,
                    style: TextStyle(fontSize: r.iconSize(28)),
                  ),
                ),
              ),
              r.verticalSpace(4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: r.fontSize(12),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
        children: [
          // 金額プレビューエリア
          Container(
            height: r.heightSize(120),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Stack(
                  children: [
                    // 日付表示（右上）
                    Positioned(
                      top: r.spacing(8),
                      right: r.spacing(24),
                      child: GestureDetector(
                        onTap: _showDatePicker,
                        child: Container(
                          padding: r.paddingSymmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(r.borderRadius(8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: r.iconSize(14),
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
                              SizedBox(width: r.spacing(4)),
                              Text(
                                _formatSelectedDate(),
                                style: TextStyle(
                                  fontSize: r.fontSize(13),
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 金額表示（中央）
                    Container(
                      alignment: Alignment.center,
                      padding: r.paddingHorizontal(24),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: _amountScaleAnimation,
                              child: TweenAnimationBuilder<Color?>(
                                tween: ColorTween(
                                  begin: Theme.of(context).colorScheme.onSurface,
                                  end: _amountText.isEmpty
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                builder: (context, color, child) {
                                  return Text(
                                    _formattedAmount,
                                    style: TextStyle(
                                      fontSize: r.fontSize(48),
                                      fontWeight: FontWeight.w900,
                                      color: color,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 費目選択エリア（スライド対応）
          Expanded(
            child: Column(
              children: [
                // ページインジケーター
                Padding(
                  padding: r.paddingSymmetric(vertical: 8, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPageIndicator(0, '支出'),
                      r.horizontalSpace(24),
                      _buildPageIndicator(1, '収入'),
                    ],
                  ),
                ),
                // PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                        _selectedMainCategoryId = null;
                        _selectedIncomeCategoryId = null;
                        _predictedCategoryId = null;
                      });
                    },
                    children: [
                      // 支出カテゴリーページ
                      _buildExpenseCategoriesPage(r),
                      // 収入カテゴリーページ
                      _buildIncomeCategoriesPage(r),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // テンキーエリア
          CustomNumpad(
            onNumberTap: _onNumberTap,
            onDelete: _onDelete,
            onClear: _onClear,
            onConfirm: _onConfirm,
          ),
        ],
        ),
      ),
    );
  }
}
