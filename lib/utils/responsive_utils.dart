import 'package:flutter/material.dart';

class ResponsiveUtils {
  final BuildContext context;
  late final Size screenSize;
  late final double width;
  late final double height;
  late final double diagonal;

  ResponsiveUtils(this.context) {
    screenSize = MediaQuery.of(context).size;
    width = screenSize.width;
    height = screenSize.height;
    diagonal = _calculateDiagonal(width, height);
  }

  double _calculateDiagonal(double width, double height) {
    return (width * width + height * height) / (width + height);
  }

  // 画面サイズカテゴリ
  bool get isSmallPhone => width < 360;
  bool get isMediumPhone => width >= 360 && width < 400;
  bool get isLargePhone => width >= 400 && width < 600;
  bool get isTablet => width >= 600;

  bool get isShortScreen => height < 700;
  bool get isMediumScreen => height >= 700 && height < 800;
  bool get isTallScreen => height >= 800;

  // スケーリングファクター（基準: iPhone 13 mini = 375x812）
  double get widthScale => width / 375.0;
  double get heightScale => height / 812.0;
  double get diagonalScale => diagonal / _calculateDiagonal(375, 812);

  // フォントサイズ（画面サイズに応じて）
  double fontSize(double baseSize) {
    return baseSize * widthScale.clamp(0.85, 1.2);
  }

  // パディング/マージン（画面サイズに応じて）
  double spacing(double baseSpacing) {
    return baseSpacing * widthScale.clamp(0.8, 1.15);
  }

  // アイコンサイズ
  double iconSize(double baseSize) {
    return baseSize * diagonalScale.clamp(0.85, 1.2);
  }

  // ボタンやカードの高さ
  double heightSize(double baseHeight) {
    return baseHeight * heightScale.clamp(0.85, 1.15);
  }

  // ボーダー半径
  double borderRadius(double baseRadius) {
    return baseRadius * diagonalScale.clamp(0.9, 1.1);
  }

  // グリッドカラム数（画面幅に応じて）
  int gridColumns(int defaultColumns) {
    if (width < 340) return defaultColumns - 1;
    if (width < 360) return defaultColumns;
    if (width < 500) return defaultColumns;
    if (width < 700) return defaultColumns + 1;
    return defaultColumns + 2;
  }

  // EdgeInsets（すべての方向）
  EdgeInsets paddingAll(double base) {
    return EdgeInsets.all(spacing(base));
  }

  // EdgeInsets（水平方向）
  EdgeInsets paddingHorizontal(double base) {
    return EdgeInsets.symmetric(horizontal: spacing(base));
  }

  // EdgeInsets（垂直方向）
  EdgeInsets paddingVertical(double base) {
    return EdgeInsets.symmetric(vertical: spacing(base));
  }

  // EdgeInsets（カスタム）
  EdgeInsets paddingSymmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: spacing(horizontal),
      vertical: spacing(vertical),
    );
  }

  // SizedBox（高さ）
  SizedBox verticalSpace(double base) {
    return SizedBox(height: spacing(base));
  }

  // SizedBox（幅）
  SizedBox horizontalSpace(double base) {
    return SizedBox(width: spacing(base));
  }
}

// Extension for easy access
extension ResponsiveExtension on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);
}
