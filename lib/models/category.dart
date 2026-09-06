import 'package:uuid/uuid.dart';

// 第1階層（固定8費目）
class MainCategory {
  final int id;
  final String name;
  final String icon; // Emoji or icon name

  const MainCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
      };

  factory MainCategory.fromJson(Map<String, dynamic> json) => MainCategory(
        id: json['id'] as int,
        name: json['name'] as String,
        icon: json['icon'] as String,
      );
}

// デフォルトの8つの主要費目
class DefaultMainCategories {
  static const List<MainCategory> categories = [
    MainCategory(id: 1, name: '食費', icon: '🍽️'),
    MainCategory(id: 2, name: '交際費', icon: '🍻'),
    MainCategory(id: 3, name: '交通', icon: '🚗'),
    MainCategory(id: 4, name: '娯楽', icon: '🎮'),
    MainCategory(id: 5, name: '衣服', icon: '👔'),
    MainCategory(id: 6, name: '光熱費', icon: '💡'),
    MainCategory(id: 7, name: '通信', icon: '📱'),
    MainCategory(id: 8, name: 'その他', icon: '📦'),
  ];

  static MainCategory getById(int id) {
    return categories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => categories.last, // その他
    );
  }
}

// 第2階層（カスタマイズ可能なサブカテゴリー）
class SubCategory {
  final String id;
  final int mainCategoryId;
  final String name;

  SubCategory({
    String? id,
    required this.mainCategoryId,
    required this.name,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'mainCategoryId': mainCategoryId,
        'name': name,
      };

  factory SubCategory.fromJson(Map<String, dynamic> json) => SubCategory(
        id: json['id'] as String,
        mainCategoryId: json['mainCategoryId'] as int,
        name: json['name'] as String,
      );

  SubCategory copyWith({
    String? id,
    int? mainCategoryId,
    String? name,
  }) {
    return SubCategory(
      id: id ?? this.id,
      mainCategoryId: mainCategoryId ?? this.mainCategoryId,
      name: name ?? this.name,
    );
  }
}

// 収入カテゴリー
class IncomeCategory {
  final int id;
  final String name;
  final String icon;

  const IncomeCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
      };

  factory IncomeCategory.fromJson(Map<String, dynamic> json) => IncomeCategory(
        id: json['id'] as int,
        name: json['name'] as String,
        icon: json['icon'] as String,
      );
}

// デフォルトの収入カテゴリー
class DefaultIncomeCategories {
  static const List<IncomeCategory> categories = [
    IncomeCategory(id: 101, name: '給与', icon: '💼'),
    IncomeCategory(id: 102, name: 'ボーナス', icon: '🎁'),
    IncomeCategory(id: 103, name: '副収入', icon: '💰'),
    IncomeCategory(id: 104, name: 'その他', icon: '💵'),
  ];

  static IncomeCategory getById(int id) {
    return categories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => categories.last,
    );
  }
}
