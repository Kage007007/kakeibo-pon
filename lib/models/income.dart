import 'package:uuid/uuid.dart';

class Income {
  final String id;
  final DateTime date;
  final double amount;
  final String incomeType; // 例: 給与、副収入、ボーナス
  final bool isRecurring; // 定期収入かどうか

  Income({
    String? id,
    required this.date,
    required this.amount,
    required this.incomeType,
    this.isRecurring = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'incomeType': incomeType,
        'isRecurring': isRecurring,
      };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num).toDouble(),
        incomeType: json['incomeType'] as String,
        isRecurring: json['isRecurring'] as bool? ?? false,
      );

  Income copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? incomeType,
    bool? isRecurring,
  }) {
    return Income(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      incomeType: incomeType ?? this.incomeType,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }
}
