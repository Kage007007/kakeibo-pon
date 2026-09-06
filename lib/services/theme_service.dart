import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';
import 'storage_service.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'app_theme';
  static const String _customThemeDataKey = 'custom_theme_data';
  AppTheme _currentTheme = AppTheme.themes[AppThemeType.forestGreen]!;

  AppTheme get currentTheme => _currentTheme;
  ThemeData get themeData => _currentTheme.toThemeData();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);

    if (themeName != null) {
      // カスタムテーマかチェック
      if (themeName.startsWith('custom_')) {
        // カスタムテーマをStorageServiceから読み込む
        final customThemes = await StorageService().getCustomThemes();
        final customTheme = customThemes.where((t) => t.name == themeName).firstOrNull;
        if (customTheme != null) {
          _currentTheme = customTheme;
        } else {
          // カスタムテーマが見つからない場合はデフォルトに
          _currentTheme = AppTheme.themes[AppThemeType.forestGreen]!;
        }
      } else {
        _currentTheme = AppTheme.getThemeByName(themeName);
      }
      notifyListeners();
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
  }

  Future<void> setThemeByType(AppThemeType type) async {
    final theme = AppTheme.getTheme(type);
    await setTheme(theme);
  }
}
