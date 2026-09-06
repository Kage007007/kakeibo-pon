import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/app_theme.dart';
import '../models/notification_settings.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../services/share_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/share_preview_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  List<Transaction> _fixedCosts = [];
  double _targetSavingsAmount = 50000.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions = await _storage.getTransactions();
    final fixedCosts = transactions.where((t) => t.isRecurring).toList();
    fixedCosts.sort((a, b) => b.date.compareTo(a.date));
    final targetAmount = await _storage.getTargetSavingsAmount();

    setState(() {
      _fixedCosts = fixedCosts;
      _targetSavingsAmount = targetAmount;
    });
  }

  Future<void> _showEditFixedCostDialog(Transaction fixedCost) async {
    final TextEditingController amountController = TextEditingController(
      text: fixedCost.amount.round().toString(),
    );
    final TextEditingController typeController = TextEditingController(
      text: fixedCost.note ?? '',
    );
    bool isRecurring = fixedCost.isRecurring;
    DateTime selectedDate = fixedCost.date;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                '固定費を編集',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: '金額',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        prefixText: '¥ ',
                        prefixStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 18,
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: typeController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: '費目名',
                        hintText: '例: 家賃、光熱費、通信費',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 12,
                        ),
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            final theme = Theme.of(context);
                            final isDark = theme.brightness == Brightness.dark;
                            return Theme(
                              data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
                                colorScheme: ColorScheme(
                                  primary: theme.colorScheme.primary,
                                  onPrimary: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
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
                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('yyyy年MM月dd日').format(selectedDate),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isRecurring,
                          onChanged: (value) {
                            setDialogState(() {
                              isRecurring = value ?? false;
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                        Text(
                          '毎月の固定費として設定',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'キャンセル',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      return;
                    }
                    final incomeType = typeController.text.trim();
                    if (incomeType.isEmpty) {
                      return;
                    }

                    final updatedTransaction = fixedCost.copyWith(
                      date: selectedDate,
                      amount: amount,
                      note: incomeType,
                      isRecurring: isRecurring,
                    );

                    await _storage.updateTransaction(updatedTransaction);
                    await _loadData();

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('固定費を更新しました'),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                        ),
                      );
                    }
                  },
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
      },
    );
  }

  Future<void> _showAddIncomeDialog() async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController typeController = TextEditingController(text: '家賃');
    bool isRecurring = true;
    DateTime selectedDate = DateTime.now();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                '固定費を追加',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: '金額',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        prefixText: '¥ ',
                        prefixStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 18,
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: typeController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: '費目名',
                        hintText: '例: 家賃、光熱費、通信費',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 12,
                        ),
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            final theme = Theme.of(context);
                            final isDark = theme.brightness == Brightness.dark;
                            return Theme(
                              data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
                                colorScheme: ColorScheme(
                                  primary: theme.colorScheme.primary,
                                  onPrimary: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
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
                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('yyyy年MM月dd日').format(selectedDate),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isRecurring,
                          onChanged: (value) {
                            setDialogState(() {
                              isRecurring = value ?? false;
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                        Text(
                          '毎月の固定費として設定',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'キャンセル',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      return;
                    }
                    final incomeType = typeController.text.trim();
                    if (incomeType.isEmpty) {
                      return;
                    }

                    final transaction = Transaction(
                      date: selectedDate,
                      amount: amount,
                      mainCategoryId: 8, // その他カテゴリー
                      note: incomeType, // 費目名をnoteフィールドに保存
                      isRecurring: isRecurring,
                    );

                    await _storage.saveTransaction(transaction);
                    await _loadData();

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
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
      },
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
            // カスタムヘッダー
            Padding(
              padding: r.paddingSymmetric(horizontal: 24, vertical: 12),
              child: Text(
                '設定',
                style: TextStyle(
                  fontSize: r.fontSize(24),
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            // コンテンツ
            Expanded(
              child: ListView(
                padding: r.paddingAll(24),
                children: [
                  // 財務管理セクション
                  _buildSectionHeader('財務管理'),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.calendar_month,
                    title: '毎月の固定費設定',
                    subtitle: '${_fixedCosts.length}件の固定費が登録されています',
                    onTap: _showFixedExpenseManagement,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.track_changes,
                    title: '貯蓄目標設定',
                    subtitle: '現在の目標: ¥ ${NumberFormat('#,###').format(_targetSavingsAmount.round())}',
                    onTap: _showTargetSettings,
                  ),
                  // 分類とタグのカスタマイズは後々実装するため非表示

                  const SizedBox(height: 32),

                  // アプリ設定セクション
                  _buildSectionHeader('アプリ設定'),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.save,
                    title: 'データバックアップと引継ぎ',
                    subtitle: 'データはローカルに自動保存されます',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'データの保存について',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          content: Text(
                            'すべてのデータは自動的にデバイス内に保存されます。\n\nアプリを削除すると、保存されたデータも削除されますのでご注意ください。\n\nクラウドバックアップ機能は今後追加予定です。',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                '了解',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.palette,
                    title: 'デザインテーマ選択',
                    subtitle: ThemeService().currentTheme.displayName,
                    onTap: _showThemeSelector,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.notifications,
                    title: '通知設定',
                    subtitle: '毎日の記録リマインダー',
                    onTap: _showNotificationSettings,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return _AnimatedSettingCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showFixedExpenseManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
      )..forward(),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        '毎月の固定費',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddIncomeDialog();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _fixedCosts.isEmpty
                      ? Center(
                          child: Text(
                            '固定費がありません\n家賃・光熱費などを登録しましょう',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _fixedCosts.length,
                          itemBuilder: (context, index) {
                            final fixedCost = _fixedCosts[index];
                            return Dismissible(
                              key: Key(fixedCost.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  borderRadius: BorderRadius.circular(12),
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
                                      '固定費を削除',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    content: Text(
                                      '「${fixedCost.note ?? 'その他'}」を削除しますか?',
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
                                await _storage.deleteTransaction(fixedCost.id);
                                await _loadData();
                              },
                              child: Material(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () => _showEditFixedCostDialog(fixedCost),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.receipt,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    fixedCost.note ?? 'その他',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                  if (fixedCost.isRecurring) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '毎月',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w700,
                                                          color: Theme.of(context).colorScheme.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('yyyy年MM月dd日').format(fixedCost.date),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '¥ ${fixedCost.amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => _loadData());
  }

  void _showTargetSettings() {
    final TextEditingController amountController = TextEditingController(
      text: _targetSavingsAmount.round().toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '貯蓄目標設定',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '月の目標貯蓄額を設定',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  prefixText: '¥ ',
                  prefixStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
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
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'キャンセル',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 50000.0;
                await _storage.setTargetSavingsAmount(amount);
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
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
    ).then((_) => _loadData());
  }

  void _showThemeSelector() async {
    final customThemes = await _storage.getCustomThemes();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.palette,
                              color: Theme.of(context).colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'デザインテーマ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Default themes section
                          Text(
                            'プリセットテーマ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: AppTheme.themes.length,
                            itemBuilder: (context, index) {
                              final entry = AppTheme.themes.entries.toList()[index];
                              final theme = entry.value;
                              final isSelected = ThemeService().currentTheme.name == theme.name;

                              return _ThemePreviewCard(
                                theme: theme,
                                isSelected: isSelected,
                                onTap: () async {
                                  await ThemeService().setTheme(theme);
                                  if (mounted) {
                                    Navigator.pop(context);
                                    setState(() {});
                                  }
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Custom themes section (テーマガチャ)
                          Row(
                            children: [
                              Text(
                                'テーマガチャ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${customThemes.length}/${StorageService.maxCustomThemeSlots}',
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

                          // Custom theme cards + Generate button
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: customThemes.length + 1, // +1 for generate button
                            itemBuilder: (context, index) {
                              // Generate button
                              if (index == customThemes.length) {
                                return _GenerateThemeButton(
                                  onGenerate: () async {
                                    await _generateRandomTheme(
                                      dialogContext,
                                      customThemes,
                                      setDialogState,
                                    );
                                  },
                                );
                              }

                              final theme = customThemes[index];
                              final isSelected = ThemeService().currentTheme.name == theme.name;

                              return _ThemePreviewCard(
                                theme: theme,
                                isSelected: isSelected,
                                isCustom: true,
                                onTap: () async {
                                  await ThemeService().setTheme(theme);
                                  if (mounted) {
                                    Navigator.pop(context);
                                    setState(() {});
                                  }
                                },
                                onDelete: () async {
                                  final confirm = await _showDeleteThemeDialog(theme);
                                  if (confirm == true) {
                                    await _storage.deleteCustomTheme(theme.name);
                                    // 現在選択中のテーマを削除した場合、デフォルトに戻す
                                    if (ThemeService().currentTheme.name == theme.name) {
                                      await ThemeService().setThemeByType(AppThemeType.forestGreen);
                                    }
                                    // ダイアログを更新
                                    final updatedThemes = await _storage.getCustomThemes();
                                    setDialogState(() {
                                      customThemes.clear();
                                      customThemes.addAll(updatedThemes);
                                    });
                                    setState(() {});
                                  }
                                },
                                onShare: () => _showShareThemeDialog(theme),
                              );
                            },
                          ),

                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '動画広告を視聴してランダムテーマを生成',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generateRandomTheme(
    BuildContext dialogContext,
    List<AppTheme> customThemes,
    StateSetter setDialogState,
  ) async {
    final hasSlot = customThemes.length < StorageService.maxCustomThemeSlots;

    if (!hasSlot) {
      // 枠がいっぱい → 上書き確認
      final replaceIndex = await _showReplaceThemeDialog(customThemes);
      if (replaceIndex == null) return; // キャンセル

      // リワード広告を表示
      _showRewardedAdAndGenerateTheme(
        dialogContext,
        replaceIndex: replaceIndex,
        setDialogState: setDialogState,
      );
    } else {
      // 枠がある → そのまま生成
      _showRewardedAdAndGenerateTheme(
        dialogContext,
        setDialogState: setDialogState,
      );
    }
  }

  Future<bool?> _showDeleteThemeDialog(AppTheme theme) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'テーマを削除',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '「${theme.displayName}」を削除しますか？',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
        );
      },
    );
  }

  Future<void> _showShareThemeDialog(AppTheme theme) async {
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
            'テーマをシェア',
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
                  child: ThemeSharePreview(
                    theme: theme,
                    shareCode: theme.toShareCode(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'プレビュー画像とテーマコードがシェアされます',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
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
                await ShareService().shareTheme(theme, previewKey);
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

  Future<int?> _showReplaceThemeDialog(List<AppTheme> customThemes) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'テーマ枠がいっぱいです',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'どのテーマを上書きしますか？',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              ...customThemes.asMap().entries.map((entry) {
                final index = entry.key;
                final theme = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, index),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                theme.displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
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
          ],
        );
      },
    );
  }

  void _showRewardedAdAndGenerateTheme(
    BuildContext dialogContext, {
    int? replaceIndex,
    required StateSetter setDialogState,
  }) {
    // 広告の準備状況を確認
    final adStats = AdService().getStats();
    final isAdReady = adStats['rewardedAdReady'] == true;

    if (!isAdReady) {
      // 広告が準備できていない場合
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('広告を読み込み中です。少々お待ちください...'),
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 報酬を受け取ったかどうかのフラグ
    bool rewardEarned = false;

    AdService().showRewardedAd(
      onUserEarnedReward: (amount, type) async {
        rewardEarned = true;

        // ランダムテーマを生成
        final newTheme = RandomThemeGenerator.generate();

        if (replaceIndex != null) {
          // 上書き
          await _storage.replaceCustomTheme(replaceIndex, newTheme);
        } else {
          // 新規追加
          await _storage.saveCustomTheme(newTheme);
        }

        // テーマを適用
        await ThemeService().setTheme(newTheme);

        if (mounted) {
          // ダイアログを閉じて設定画面を更新
          Navigator.pop(dialogContext);
          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「${newTheme.displayName}」を生成しました！'),
              backgroundColor: newTheme.primaryColor,
            ),
          );
        }
      },
      onAdDismissed: () {
        // 報酬を受け取っていない場合のみエラー表示
        if (!rewardEarned && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('広告の視聴が完了しませんでした'),
              backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
            ),
          );
        }
      },
    );
  }

  Future<void> _showNotificationSettings() async {
    final notificationService = NotificationService();

    // 現在の設定を読み込み
    final currentSettings = await notificationService.getSettings();

    bool notificationEnabled = currentSettings.notificationEnabled;
    bool habitNotificationEnabled = currentSettings.habitNotificationEnabled;
    TimeOfDay selectedTime = currentSettings.notificationTime;
    NotificationCondition selectedCondition = currentSettings.condition;
    bool churnNotificationEnabled = currentSettings.churnNotificationEnabled;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                '通知設定',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '記録習慣の形成をサポートする通知機能です',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // マスタースイッチ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '通知を有効にする',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Switch(
                          value: notificationEnabled,
                          onChanged: (value) {
                            setDialogState(() {
                              notificationEnabled = value;
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 以下の設定（グレーアウト可能）
                    Opacity(
                      opacity: notificationEnabled ? 1.0 : 0.4,
                      child: AbsorbPointer(
                        absorbing: !notificationEnabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 習慣化通知セクション
                    Text(
                      '習慣化通知',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '通知を有効にする',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Switch(
                          value: habitNotificationEnabled,
                          onChanged: (value) {
                            setDialogState(() {
                              habitNotificationEnabled = value;
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),

                    if (habitNotificationEnabled) ...[
                      const SizedBox(height: 20),
                      Text(
                        '通知時刻',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Hour input
                                  SizedBox(
                                    width: 50,
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: selectedTime.hour.toString().padLeft(2, '0'),
                                      ),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        hintText: '21',
                                        hintStyle: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        final hour = int.tryParse(value);
                                        if (hour != null && hour >= 0 && hour <= 23) {
                                          setDialogState(() {
                                            selectedTime = TimeOfDay(
                                              hour: hour,
                                              minute: selectedTime.minute,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      ':',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  // Minute input
                                  SizedBox(
                                    width: 50,
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: selectedTime.minute.toString().padLeft(2, '0'),
                                      ),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        hintText: '00',
                                        hintStyle: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        final minute = int.tryParse(value);
                                        if (minute != null && minute >= 0 && minute <= 59) {
                                          setDialogState(() {
                                            selectedTime = TimeOfDay(
                                              hour: selectedTime.hour,
                                              minute: minute,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '通知条件',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<NotificationCondition>(
                              title: Text(
                                '入力がない日のみ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                'その日まだ記録していない場合のみ通知',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              value: NotificationCondition.onlyWhenNoInput,
                              groupValue: selectedCondition,
                              activeColor: Theme.of(context).colorScheme.primary,
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedCondition = value;
                                  });
                                }
                              },
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                            ),
                            RadioListTile<NotificationCondition>(
                              title: Text(
                                '毎日通知',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                '記録の有無に関わらず毎日通知',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              value: NotificationCondition.daily,
                              groupValue: selectedCondition,
                              activeColor: Theme.of(context).colorScheme.primary,
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedCondition = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Divider(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(height: 24),

                    // 離脱防止通知セクション
                    Text(
                      '離脱防止通知',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '30日間記録がない場合に通知',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Switch(
                          value: churnNotificationEnabled,
                          onChanged: (value) {
                            setDialogState(() {
                              churnNotificationEnabled = value;
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '長期間記録がない場合、再開を促す通知を送信します',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'キャンセル',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setDialogState(() {
                      isLoading = true;
                    });

                    try {
                      // 初回有効化時に権限をリクエスト
                      if (habitNotificationEnabled && !currentSettings.habitNotificationEnabled) {
                        final permissionGranted = await notificationService.requestPermissions();
                        if (!permissionGranted) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('通知権限が許可されていません。設定から通知を有効にしてください。'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                            Navigator.pop(context);
                          }
                          return;
                        }
                      }

                      // 設定を保存
                      final newSettings = NotificationSettings(
                        notificationEnabled: notificationEnabled,
                        habitNotificationEnabled: habitNotificationEnabled,
                        notificationTime: selectedTime,
                        condition: selectedCondition,
                        churnNotificationEnabled: churnNotificationEnabled,
                      );

                      await notificationService.saveSettings(newSettings);

                      if (context.mounted) {
                        String message;
                        if (habitNotificationEnabled && churnNotificationEnabled) {
                          message = '通知設定を保存しました。毎日${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}に習慣化通知、離脱防止通知も有効です。';
                        } else if (habitNotificationEnabled) {
                          message = '通知設定を保存しました。毎日${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}に通知します。';
                        } else if (churnNotificationEnabled) {
                          message = '離脱防止通知を有効にしました';
                        } else {
                          message = '通知を無効にしました';
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('エラーが発生しました: $e'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    } finally {
                      if (context.mounted) {
                        setDialogState(() {
                          isLoading = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
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
      },
    );
  }
}

// Animated setting card with tap feedback
class _AnimatedSettingCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _AnimatedSettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  State<_AnimatedSettingCard> createState() => _AnimatedSettingCardState();
}

class _AnimatedSettingCardState extends State<_AnimatedSettingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _highlightAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _highlightController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Trigger highlight animation
    _highlightController.forward(from: 0.0).then((_) {
      _highlightController.animateTo(0.0, duration: const Duration(milliseconds: 300));
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _highlightController,
      builder: (context, child) {
        return Material(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
                // Highlight overlay that fades out
                color: Theme.of(context).colorScheme.primary.withOpacity(
                  _highlightController.value * 0.15,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  widget.trailing ??
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Generate theme button
class _GenerateThemeButton extends StatelessWidget {
  final VoidCallback onGenerate;

  const _GenerateThemeButton({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onGenerate,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '生成',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Theme preview card with visual color representation
class _ThemePreviewCard extends StatefulWidget {
  final AppTheme theme;
  final bool isSelected;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const _ThemePreviewCard({
    required this.theme,
    required this.isSelected,
    this.isCustom = false,
    required this.onTap,
    this.onDelete,
    this.onShare,
  });

  @override
  State<_ThemePreviewCard> createState() => _ThemePreviewCardState();
}

class _ThemePreviewCardState extends State<_ThemePreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            children: [
              GestureDetector(
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.theme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isSelected
                          ? widget.theme.primaryColor
                          : widget.theme.textColor.withOpacity(0.1),
                      width: widget.isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: widget.theme.primaryColor.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Color indicator circle with check icon overlay
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: widget.theme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.theme.textColor.withOpacity(0.15),
                                width: 2,
                              ),
                            ),
                          ),
                          if (widget.isSelected)
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Theme name
                      Flexible(
                        child: Text(
                          widget.theme.displayName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.theme.textColor,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Delete button for custom themes
              if (widget.isCustom && widget.onDelete != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              // Share button for custom themes
              if (widget.isCustom && widget.onShare != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: widget.onShare,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.theme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 14,
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
