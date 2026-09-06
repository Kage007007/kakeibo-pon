import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

enum AppThemeType {
  darkModern,
  monochromeClarity,
  catTheme,
  forestGreen,
  simpleDark,
  simpleLight,
}

class AppTheme {
  final String name;
  final String displayName;
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Brightness brightness;
  final int animationDuration; // in milliseconds
  final Curve animationCurve;

  const AppTheme({
    required this.name,
    required this.displayName,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.brightness,
    required this.animationDuration,
    required this.animationCurve,
  });

  Duration get animDuration => Duration(milliseconds: animationDuration);

  ThemeData toThemeData() {
    final isForestGreen = name == 'forest_green';

    return ThemeData(
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: ColorScheme(
        primary: primaryColor,
        secondary: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        error: Colors.redAccent,
        onPrimary: brightness == Brightness.dark ? Colors.white : Colors.black,
        onSecondary: brightness == Brightness.dark ? Colors.white : Colors.black,
        onBackground: textColor,
        onSurface: textColor,
        onError: Colors.white,
        brightness: brightness,
      ),
      useMaterial3: true,
      fontFamily: isForestGreen ? 'Noto Sans JP' : 'Inter',
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isForestGreen ? 4.0 : 12.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isForestGreen ? 4.0 : 12.0),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isForestGreen ? 4.0 : 12.0),
        ),
      ),
    );
  }

  static const Map<AppThemeType, AppTheme> themes = {
    AppThemeType.darkModern: AppTheme(
      name: 'dark_modern',
      displayName: 'ダークモダン',
      primaryColor: Colors.lightBlueAccent,
      backgroundColor: Color(0xFF050505),
      surfaceColor: Color(0xFF1A1A1A),
      textColor: Colors.white,
      brightness: Brightness.dark,
      animationDuration: 250,
      animationCurve: Curves.easeOutCirc,
    ),
    AppThemeType.monochromeClarity: AppTheme(
      name: 'monochrome_clarity',
      displayName: 'モノクロクラリティ',
      primaryColor: Color(0xFF5E64FF),
      backgroundColor: Color(0xFFF8F8F8),
      surfaceColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF333333),
      brightness: Brightness.light,
      animationDuration: 250,
      animationCurve: Curves.easeOutCirc,
    ),
    AppThemeType.catTheme: AppTheme(
      name: 'cat_theme',
      displayName: 'にゃんこテーマ',
      primaryColor: Color(0xFFE8B4A1),
      backgroundColor: Color(0xFFF9F6F2),
      surfaceColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF333333),
      brightness: Brightness.light,
      animationDuration: 600,
      animationCurve: Curves.slowMiddle,
    ),
    AppThemeType.forestGreen: AppTheme(
      name: 'forest_green',
      displayName: 'フォレストグリーン',
      primaryColor: Color(0xFF228B22),
      backgroundColor: Color(0xFFFFFFFF),
      surfaceColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF333333),
      brightness: Brightness.light,
      animationDuration: 250,
      animationCurve: Curves.easeOutCirc,
    ),
    AppThemeType.simpleDark: AppTheme(
      name: 'simple_dark',
      displayName: 'ダークモード',
      primaryColor: Color(0xFF007AFF),
      backgroundColor: Color(0xFF000000),
      surfaceColor: Color(0xFF1C1C1E),
      textColor: Colors.white,
      brightness: Brightness.dark,
      animationDuration: 200,
      animationCurve: Curves.easeOut,
    ),
    AppThemeType.simpleLight: AppTheme(
      name: 'simple_light',
      displayName: 'ライトモード',
      primaryColor: Color(0xFF007AFF),
      backgroundColor: Color(0xFFFFFFFF),
      surfaceColor: Color(0xFFF2F2F7),
      textColor: Color(0xFF000000),
      brightness: Brightness.light,
      animationDuration: 200,
      animationCurve: Curves.easeOut,
    ),
  };

  static AppTheme getTheme(AppThemeType type) {
    return themes[type] ?? themes[AppThemeType.darkModern]!;
  }

  static AppTheme getThemeByName(String name) {
    return themes.values.firstWhere(
      (theme) => theme.name == name,
      orElse: () => themes[AppThemeType.darkModern]!,
    );
  }

  bool get isCatTheme => name == 'cat_theme';
  bool get isCustomTheme => name.startsWith('custom_');

  /// JSONシリアライズ（カスタムテーマ保存用）
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'primaryColor': primaryColor.value,
      'backgroundColor': backgroundColor.value,
      'surfaceColor': surfaceColor.value,
      'textColor': textColor.value,
      'brightness': brightness == Brightness.dark ? 'dark' : 'light',
      'animationDuration': animationDuration,
    };
  }

  /// JSONデシリアライズ
  factory AppTheme.fromJson(Map<String, dynamic> json) {
    return AppTheme(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      primaryColor: Color(json['primaryColor'] as int),
      backgroundColor: Color(json['backgroundColor'] as int),
      surfaceColor: Color(json['surfaceColor'] as int),
      textColor: Color(json['textColor'] as int),
      brightness: json['brightness'] == 'dark' ? Brightness.dark : Brightness.light,
      animationDuration: json['animationDuration'] as int,
      animationCurve: Curves.easeOutCirc,
    );
  }

  /// テーマをシェア用コードに変換（Base64エンコード）
  String toShareCode() {
    final json = toJson();
    final jsonString = jsonEncode(json);
    final bytes = utf8.encode(jsonString);
    return base64Url.encode(bytes);
  }

  /// シェアコードからテーマを復元
  static AppTheme? fromShareCode(String code) {
    try {
      final bytes = base64Url.decode(code);
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppTheme.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}

/// ランダムカラーテーマ生成クラス
class RandomThemeGenerator {
  static final Random _random = Random();

  /// ランダムなカラーテーマを生成
  static AppTheme generate() {
    // ランダムな色相（0-360）
    final hue = _random.nextDouble() * 360;

    // ランダムでダーク/ライトを決定
    final isDark = _random.nextBool();

    // プライマリカラー（彩度60-90%、明度50-70%）
    final primaryColor = HSLColor.fromAHSL(
      1.0,
      hue,
      0.6 + _random.nextDouble() * 0.3,  // 60-90%
      0.5 + _random.nextDouble() * 0.2,  // 50-70%
    ).toColor();

    Color backgroundColor;
    Color surfaceColor;
    Color textColor;

    if (isDark) {
      // ダークテーマ
      // 背景は暗め（明度5-15%）、色相を少し入れる
      backgroundColor = HSLColor.fromAHSL(
        1.0,
        hue,
        0.1 + _random.nextDouble() * 0.1,  // 10-20%
        0.05 + _random.nextDouble() * 0.1,  // 5-15%
      ).toColor();

      // サーフェスは少し明るめ（明度10-20%）
      surfaceColor = HSLColor.fromAHSL(
        1.0,
        hue,
        0.1 + _random.nextDouble() * 0.1,
        0.1 + _random.nextDouble() * 0.1,
      ).toColor();

      textColor = Colors.white;
    } else {
      // ライトテーマ
      // 背景は明るめ（明度95-100%）
      backgroundColor = HSLColor.fromAHSL(
        1.0,
        hue,
        0.05 + _random.nextDouble() * 0.1,  // 5-15%
        0.95 + _random.nextDouble() * 0.05,  // 95-100%
      ).toColor();

      // サーフェスは白に近い
      surfaceColor = HSLColor.fromAHSL(
        1.0,
        hue,
        0.05 + _random.nextDouble() * 0.05,
        0.98 + _random.nextDouble() * 0.02,
      ).toColor();

      textColor = const Color(0xFF1A1A1A);
    }

    // ユニークな名前を生成
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = 'custom_$timestamp';

    // 表示名（色相に基づく名前 + ランダム番号）
    final colorName = _getColorName(hue);
    final randomNum = _random.nextInt(1000).toString().padLeft(3, '0');
    final displayName = '$colorName #$randomNum';

    return AppTheme(
      name: name,
      displayName: displayName,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      surfaceColor: surfaceColor,
      textColor: textColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
      animationDuration: 250,
      animationCurve: Curves.easeOutCirc,
    );
  }

  /// 色相から日本語の色名を取得
  static String _getColorName(double hue) {
    if (hue < 15) return 'レッド';
    if (hue < 45) return 'オレンジ';
    if (hue < 75) return 'イエロー';
    if (hue < 150) return 'グリーン';
    if (hue < 210) return 'シアン';
    if (hue < 270) return 'ブルー';
    if (hue < 330) return 'パープル';
    return 'レッド';
  }
}
