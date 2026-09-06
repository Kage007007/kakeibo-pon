import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../models/app_theme.dart';

class StorageService {
  static const String _transactionsKey = 'transactions';
  static const String _incomesKey = 'incomes';
  static const String _subCategoriesKey = 'subCategories';
  static const String _targetSavingsRateKey = 'targetSavingsRate';
  static const String _targetSavingsAmountKey = 'targetSavingsAmount';
  static const String _migrationCompletedKey = 'migrationCompleted_v1';
  static const String _customThemesKey = 'customThemes';
  static const int maxCustomThemeSlots = 2; // 無料枠は2つ

  // シングルトンパターン
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return; // 既に初期化済み
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;

    // データマイグレーション実行
    await _migrateFixedCostsToTransactions();
  }

  SharedPreferences get prefs {
    if (_prefs == null || !_isInitialized) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // --- Transactions ---
  Future<List<Transaction>> getTransactions() async {
    final String? jsonString = prefs.getString(_transactionsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Transaction.fromJson(json)).toList();
  }

  Future<void> saveTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    transactions.add(transaction);
    await _saveTransactions(transactions);
  }

  Future<void> _saveTransactions(List<Transaction> transactions) async {
    final jsonString = json.encode(
      transactions.map((t) => t.toJson()).toList(),
    );
    await prefs.setString(_transactionsKey, jsonString);
  }

  Future<void> deleteTransaction(String id) async {
    final transactions = await getTransactions();
    transactions.removeWhere((t) => t.id == id);
    await _saveTransactions(transactions);
  }

  Future<void> updateTransaction(Transaction updatedTransaction) async {
    final transactions = await getTransactions();
    final index = transactions.indexWhere((t) => t.id == updatedTransaction.id);
    if (index != -1) {
      transactions[index] = updatedTransaction;
      await _saveTransactions(transactions);
    }
  }

  // 月ごとのトランザクション取得
  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    final allTransactions = await getTransactions();
    return allTransactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();
  }

  // 費目予測のための統計データ取得
  Future<Map<int, int>> getCategoryFrequencyByAmount(double amount) async {
    final transactions = await getTransactions();

    // 金額の範囲を設定（±20%）
    final minAmount = amount * 0.8;
    final maxAmount = amount * 1.2;

    final matchingTransactions = transactions.where((t) {
      return t.amount >= minAmount && t.amount <= maxAmount;
    }).toList();

    // 費目ごとの出現頻度をカウント
    final Map<int, int> frequency = {};
    for (final transaction in matchingTransactions) {
      frequency[transaction.mainCategoryId] =
          (frequency[transaction.mainCategoryId] ?? 0) + 1;
    }

    return frequency;
  }

  // --- Incomes ---
  Future<List<Income>> getIncomes() async {
    final String? jsonString = prefs.getString(_incomesKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Income.fromJson(json)).toList();
  }

  Future<void> saveIncome(Income income) async {
    final incomes = await getIncomes();
    incomes.add(income);
    await _saveIncomes(incomes);
  }

  Future<void> _saveIncomes(List<Income> incomes) async {
    final jsonString = json.encode(
      incomes.map((i) => i.toJson()).toList(),
    );
    await prefs.setString(_incomesKey, jsonString);
  }

  Future<void> deleteIncome(String id) async {
    final incomes = await getIncomes();
    incomes.removeWhere((i) => i.id == id);
    await _saveIncomes(incomes);
  }

  Future<void> updateIncome(Income updatedIncome) async {
    final incomes = await getIncomes();
    final index = incomes.indexWhere((i) => i.id == updatedIncome.id);
    if (index != -1) {
      incomes[index] = updatedIncome;
      await _saveIncomes(incomes);
    }
  }

  // 月ごとの収入取得
  Future<List<Income>> getIncomesByMonth(int year, int month) async {
    final allIncomes = await getIncomes();
    return allIncomes.where((i) {
      return i.date.year == year && i.date.month == month;
    }).toList();
  }

  // --- SubCategories ---
  Future<List<SubCategory>> getSubCategories() async {
    final String? jsonString = prefs.getString(_subCategoriesKey);
    if (jsonString == null) return _getDefaultSubCategories();

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => SubCategory.fromJson(json)).toList();
  }

  Future<void> saveSubCategory(SubCategory subCategory) async {
    final subCategories = await getSubCategories();
    subCategories.add(subCategory);
    await _saveSubCategories(subCategories);
  }

  Future<void> _saveSubCategories(List<SubCategory> subCategories) async {
    final jsonString = json.encode(
      subCategories.map((s) => s.toJson()).toList(),
    );
    await prefs.setString(_subCategoriesKey, jsonString);
  }

  Future<List<SubCategory>> getSubCategoriesByMainId(int mainCategoryId) async {
    final allSubCategories = await getSubCategories();
    return allSubCategories
        .where((s) => s.mainCategoryId == mainCategoryId)
        .toList();
  }

  // デフォルトのサブカテゴリー
  List<SubCategory> _getDefaultSubCategories() {
    return [
      // 食費
      SubCategory(mainCategoryId: 1, name: '外食'),
      SubCategory(mainCategoryId: 1, name: '食材'),
      SubCategory(mainCategoryId: 1, name: 'コンビニ'),
      // 住居
      SubCategory(mainCategoryId: 2, name: '家賃'),
      SubCategory(mainCategoryId: 2, name: '光熱費'),
      SubCategory(mainCategoryId: 2, name: '家具'),
      // 交通
      SubCategory(mainCategoryId: 3, name: '電車'),
      SubCategory(mainCategoryId: 3, name: 'バス'),
      SubCategory(mainCategoryId: 3, name: 'ガソリン'),
      // その他のカテゴリーも追加可能
    ];
  }

  // --- Settings ---
  Future<double> getTargetSavingsRate() async {
    return prefs.getDouble(_targetSavingsRateKey) ?? 0.3; // デフォルト30%
  }

  Future<void> setTargetSavingsRate(double rate) async {
    await prefs.setDouble(_targetSavingsRateKey, rate);
  }

  Future<double> getTargetSavingsAmount() async {
    return prefs.getDouble(_targetSavingsAmountKey) ?? 50000.0; // デフォルト50,000円
  }

  Future<void> setTargetSavingsAmount(double amount) async {
    await prefs.setDouble(_targetSavingsAmountKey, amount);
  }

  // --- Analytics ---
  Future<double> getTotalIncomeForMonth(int year, int month) async {
    final incomes = await getIncomesByMonth(year, month);
    // 固定費（isRecurring = true）を除外して、実際の収入だけを計算
    final actualIncomes = incomes.where((income) => !income.isRecurring).toList();
    return actualIncomes.fold<double>(0.0, (sum, income) => sum + income.amount);
  }

  Future<double> getTotalExpenseForMonth(int year, int month) async {
    final transactions = await getTransactionsByMonth(year, month);
    final fixedCosts = await getFixedCostsForMonth(year, month);

    // 通常の支出（固定費以外）
    final regularExpenses = transactions
        .where((t) => !t.isRecurring)
        .fold<double>(0.0, (sum, transaction) => sum + transaction.amount);

    // 固定費を加算
    final fixedExpenses = fixedCosts.fold<double>(0.0, (sum, fc) => sum + fc.amount);

    return regularExpenses + fixedExpenses;
  }

  /// 指定月に適用される固定費を取得（毎月自動反映）
  Future<List<Transaction>> getFixedCostsForMonth(int year, int month) async {
    final allTransactions = await getTransactions();
    final fixedCosts = allTransactions.where((t) => t.isRecurring).toList();

    // 固定費は登録日以降の月に毎月反映
    // 登録月が指定月以前であれば適用
    return fixedCosts.where((fc) {
      // 固定費の登録年月が指定年月以前かチェック
      if (fc.date.year < year) return true;
      if (fc.date.year == year && fc.date.month <= month) return true;
      return false;
    }).toList();
  }

  Future<Map<int, double>> getExpensesByCategoryForMonth(
      int year, int month) async {
    final transactions = await getTransactionsByMonth(year, month);
    final fixedCosts = await getFixedCostsForMonth(year, month);
    final Map<int, double> categoryExpenses = {};

    // 通常の支出（固定費以外）をカテゴリー別に集計
    for (final transaction in transactions.where((t) => !t.isRecurring)) {
      categoryExpenses[transaction.mainCategoryId] =
          (categoryExpenses[transaction.mainCategoryId] ?? 0) + transaction.amount;
    }

    // 固定費をカテゴリー別に集計
    for (final fixedCost in fixedCosts) {
      categoryExpenses[fixedCost.mainCategoryId] =
          (categoryExpenses[fixedCost.mainCategoryId] ?? 0) + fixedCost.amount;
    }

    return categoryExpenses;
  }

  // --- Data Migration ---
  Future<void> _migrateFixedCostsToTransactions() async {
    try {
      // マイグレーションが既に完了しているかチェック
      final migrationCompleted = prefs.getBool(_migrationCompletedKey) ?? false;
      if (migrationCompleted) {
        if (kDebugMode) {
          print('Migration already completed, skipping...');
        }
        return;
      }

      if (kDebugMode) {
        print('Starting migration of fixed costs from Income to Transaction...');
      }

      // すべてのIncomeを取得
      final allIncomes = await getIncomes();

      // 固定費（isRecurring = true）のIncomeを抽出
      final fixedCosts = allIncomes.where((income) => income.isRecurring).toList();

      if (fixedCosts.isEmpty) {
        if (kDebugMode) {
          print('No fixed costs found to migrate.');
        }
      } else {
        if (kDebugMode) {
          print('Found ${fixedCosts.length} fixed costs to migrate.');
        }

        // 固定費をTransactionに変換
        final transactions = await getTransactions();
        for (final fixedCost in fixedCosts) {
          final transaction = Transaction(
            id: fixedCost.id,  // 同じIDを保持
            date: fixedCost.date,
            amount: fixedCost.amount,
            mainCategoryId: 8,  // その他カテゴリー
            note: fixedCost.incomeType,  // 費目名をnoteに保存
            isRecurring: true,
          );
          transactions.add(transaction);
          if (kDebugMode) {
            print('Migrated: ${fixedCost.incomeType} - ¥${fixedCost.amount}');
          }
        }

        // Transactionを保存
        await _saveTransactions(transactions);

        // 固定費をIncomeから削除
        final remainingIncomes = allIncomes.where((income) => !income.isRecurring).toList();
        await _saveIncomes(remainingIncomes);

        if (kDebugMode) {
          print('Migration completed successfully. Migrated ${fixedCosts.length} fixed costs.');
        }
      }

      // マイグレーション完了フラグを保存
      await prefs.setBool(_migrationCompletedKey, true);
    } catch (e) {
      if (kDebugMode) {
        print('Migration error: $e');
      }
      // エラーが発生してもアプリの起動を妨げない
    }
  }

  // --- Custom Themes ---

  /// カスタムテーマを取得
  Future<List<AppTheme>> getCustomThemes() async {
    final String? jsonString = prefs.getString(_customThemesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => AppTheme.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading custom themes: $e');
      }
      return [];
    }
  }

  /// カスタムテーマを保存
  Future<void> saveCustomTheme(AppTheme theme) async {
    final themes = await getCustomThemes();
    themes.add(theme);
    await _saveCustomThemes(themes);
  }

  /// カスタムテーマを上書き保存（指定インデックス）
  Future<void> replaceCustomTheme(int index, AppTheme theme) async {
    final themes = await getCustomThemes();
    if (index >= 0 && index < themes.length) {
      themes[index] = theme;
      await _saveCustomThemes(themes);
    }
  }

  /// カスタムテーマを削除
  Future<void> deleteCustomTheme(String name) async {
    final themes = await getCustomThemes();
    themes.removeWhere((t) => t.name == name);
    await _saveCustomThemes(themes);
  }

  Future<void> _saveCustomThemes(List<AppTheme> themes) async {
    final jsonString = json.encode(
      themes.map((t) => t.toJson()).toList(),
    );
    await prefs.setString(_customThemesKey, jsonString);
  }

  /// カスタムテーマの空き枠があるか
  Future<bool> hasCustomThemeSlot() async {
    final themes = await getCustomThemes();
    return themes.length < maxCustomThemeSlots;
  }

  /// カスタムテーマの枠数を取得
  Future<int> getCustomThemeCount() async {
    final themes = await getCustomThemes();
    return themes.length;
  }
}
