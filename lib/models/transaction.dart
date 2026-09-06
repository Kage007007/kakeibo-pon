import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final DateTime date;
  final double amount;
  final int mainCategoryId;
  final String? subCategoryId;
  final List<String> tags;
  final String? note;
  final bool isRecurring; // 定期支出（固定費）かどうか

  Transaction({
    String? id,
    required this.date,
    required this.amount,
    required this.mainCategoryId,
    this.subCategoryId,
    List<String>? tags,
    this.note,
    this.isRecurring = false,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'mainCategoryId': mainCategoryId,
        'subCategoryId': subCategoryId,
        'tags': tags,
        'note': note,
        'isRecurring': isRecurring,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num).toDouble(),
        mainCategoryId: json['mainCategoryId'] as int,
        subCategoryId: json['subCategoryId'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        note: json['note'] as String?,
        isRecurring: json['isRecurring'] as bool? ?? false,
      );

  Transaction copyWith({
    String? id,
    DateTime? date,
    double? amount,
    int? mainCategoryId,
    String? subCategoryId,
    List<String>? tags,
    String? note,
    bool? isRecurring,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      mainCategoryId: mainCategoryId ?? this.mainCategoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }
}
