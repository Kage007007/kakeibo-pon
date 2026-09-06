import 'package:flutter/material.dart';
import '../models/app_theme.dart';

/// テーマシェア用プレビューウィジェット
class ThemeSharePreview extends StatelessWidget {
  final AppTheme theme;
  final String shareCode;

  const ThemeSharePreview({
    super.key,
    required this.theme,
    required this.shareCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // アプリ名
          Text(
            '家計簿ポン',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),

          // テーマカラーサークル
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // テーマ名
          Text(
            theme.displayName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),

          // モード表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.textColor.withOpacity(0.2)),
            ),
            child: Text(
              theme.brightness == Brightness.dark ? 'Dark Mode' : 'Light Mode',
              style: TextStyle(
                fontSize: 12,
                color: theme.textColor.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // テーマコード
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'テーマコード',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shareCode.length > 40
                      ? '${shareCode.substring(0, 40)}...'
                      : shareCode,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: theme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 貯蓄状況シェア用プレビューウィジェット
class SavingsSharePreview extends StatelessWidget {
  final double savingsRate;
  final double savingsAmount;
  final double targetAmount;
  final bool isAchieved;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;

  const SavingsSharePreview({
    super.key,
    required this.savingsRate,
    required this.savingsAmount,
    required this.targetAmount,
    required this.isAchieved,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAchieved ? primaryColor : Colors.orange,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 達成バッジ
          if (isAchieved) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.celebration, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '目標達成！',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 貯蓄率サークル
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 4),
            ),
            child: Center(
              child: Text(
                '${(savingsRate * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 金額情報
          Text(
            '貯蓄額',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.6),
            ),
          ),
          Text(
            '¥ ${_formatNumber(savingsAmount)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            '目標: ¥ ${_formatNumber(targetAmount)}',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),

          // アプリ名
          Text(
            '家計簿ポン',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    return number.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

/// 取引履歴サマリーシェア用プレビューウィジェット
class TransactionSummarySharePreview extends StatelessWidget {
  final String dateRange;
  final String categoryFilter;
  final double totalAmount;
  final int transactionCount;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;

  const TransactionSummarySharePreview({
    super.key,
    required this.dateRange,
    required this.categoryFilter,
    required this.totalAmount,
    required this.transactionCount,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                '取引履歴サマリー',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildInfoRow('期間', dateRange),
          const SizedBox(height: 12),
          _buildInfoRow('カテゴリー', categoryFilter),
          const SizedBox(height: 12),
          _buildInfoRow('取引件数', '$transactionCount 件'),

          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '合計金額',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
                Text(
                  '¥ ${_formatNumber(totalAmount.abs())}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              '家計簿ポン',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textColor.withOpacity(0.6),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    return number.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
