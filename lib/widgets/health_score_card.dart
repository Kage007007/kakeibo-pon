import 'package:flutter/material.dart';

class HealthScoreCard extends StatelessWidget {
  final double income;
  final double expense;
  final double targetSavingsRate;
  final double previousMonthIncome;

  const HealthScoreCard({
    super.key,
    required this.income,
    required this.expense,
    required this.targetSavingsRate,
    required this.previousMonthIncome,
  });

  int get healthScore {
    if (previousMonthIncome <= 0) return 0;

    final savings = income - expense;
    final savingsRate = savings / previousMonthIncome;
    int score = 50; // ベーススコア

    // 貯蓄率による加点（最大40点）
    if (savingsRate >= targetSavingsRate) {
      score += 40;
    } else {
      score += (40 * (savingsRate / targetSavingsRate)).round();
    }

    // 支出が前月収入を超えていないかチェック（最大10点）
    if (expense <= previousMonthIncome) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  String get healthGrade {
    if (healthScore >= 90) return 'A+';
    if (healthScore >= 80) return 'A';
    if (healthScore >= 70) return 'B+';
    if (healthScore >= 60) return 'B';
    if (healthScore >= 50) return 'C';
    return 'D';
  }

  Color get scoreColor {
    if (healthScore >= 80) return Colors.lightBlueAccent;
    if (healthScore >= 60) return Colors.greenAccent;
    if (healthScore >= 40) return Colors.amber;
    return Colors.redAccent;
  }

  String get statusMessage {
    final savings = income - expense;
    final savingsRate = previousMonthIncome > 0 ? savings / previousMonthIncome : 0;
    final difference = (targetSavingsRate - savingsRate) * 100;

    if (savingsRate >= targetSavingsRate) {
      return '素晴らしい！目標を達成しています';
    } else if (difference <= 5) {
      return 'あと少しで目標達成です';
    } else if (difference <= 15) {
      return '目標まであと${difference.toStringAsFixed(1)}%です';
    } else {
      return '支出を見直すことをおすすめします';
    }
  }

  List<_HealthIndicator> get indicators {
    final savings = income - expense;
    final savingsRate = previousMonthIncome > 0 ? savings / previousMonthIncome : 0;

    return [
      _HealthIndicator(
        label: '貯蓄',
        status: savingsRate >= targetSavingsRate ? '良好' : '改善必要',
        color: savingsRate >= targetSavingsRate
            ? Colors.greenAccent
            : Colors.amber,
      ),
      _HealthIndicator(
        label: '支出',
        status: expense <= income * 0.7 ? '安定' : '注意',
        color: expense <= income * 0.7
            ? Colors.lightBlueAccent
            : Colors.amber,
      ),
      _HealthIndicator(
        label: '収支',
        status: expense < income ? '黒字' : '赤字',
        color: expense < income ? Colors.greenAccent : Colors.redAccent,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withOpacity(0.15),
            scoreColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '家計の健康スコア',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          healthScore.toString(),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: scoreColor,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            healthGrade,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: scoreColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '点',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...indicators.map((indicator) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: indicator.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${indicator.label}:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    indicator.status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: indicator.color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HealthIndicator {
  final String label;
  final String status;
  final Color color;

  _HealthIndicator({
    required this.label,
    required this.status,
    required this.color,
  });
}
