import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_theme.dart';

/// SNSシェア機能を管理するサービス
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// RepaintBoundaryからウィジェットを画像としてキャプチャ
  Future<Uint8List?> captureWidgetToImage(GlobalKey repaintBoundaryKey) async {
    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// 画像データを一時ファイルに保存
  Future<String?> saveTempImage(Uint8List bytes, String filename) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving temp image: $e');
      return null;
    }
  }

  /// テーマをシェア
  Future<void> shareTheme(AppTheme theme, GlobalKey previewKey) async {
    final imageBytes = await captureWidgetToImage(previewKey);
    final shareCode = theme.toShareCode();

    final shareText = '''
家計簿ポンで生成したテーマです！

テーマ名: ${theme.displayName}
テーマコード: $shareCode

このコードをアプリに入力すると同じテーマが使えます
#家計簿ポン #テーマガチャ
''';

    if (imageBytes != null) {
      final imagePath =
          await saveTempImage(imageBytes, 'theme_${theme.name}.png');
      if (imagePath != null) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: shareText,
        );
        return;
      }
    }

    // 画像キャプチャ失敗時はテキストのみシェア
    await Share.share(shareText);
  }

  /// 貯蓄状況をシェア
  Future<void> shareSavingsComparison({
    required double savingsRate,
    required double savingsAmount,
    required double targetAmount,
    required bool isTargetAchieved,
    GlobalKey? previewKey,
  }) async {
    String shareText;

    if (isTargetAchieved) {
      shareText = '''
今月の貯蓄目標達成しました！

貯蓄率: ${(savingsRate * 100).toStringAsFixed(1)}%
貯蓄額: ¥${_formatNumber(savingsAmount)}
目標額: ¥${_formatNumber(targetAmount)}

#家計簿ポン #貯蓄目標達成 #家計管理
''';
    } else {
      shareText = '''
家計簿ポンで家計管理中！

貯蓄率: ${(savingsRate * 100).toStringAsFixed(1)}%
現在の貯蓄: ¥${_formatNumber(savingsAmount)}
目標まであと: ¥${_formatNumber(targetAmount - savingsAmount)}

#家計簿ポン #家計管理
''';
    }

    if (previewKey != null) {
      final imageBytes = await captureWidgetToImage(previewKey);
      if (imageBytes != null) {
        final imagePath = await saveTempImage(
            imageBytes, 'savings_${DateTime.now().millisecondsSinceEpoch}.png');
        if (imagePath != null) {
          await Share.shareXFiles([XFile(imagePath)], text: shareText);
          return;
        }
      }
    }

    await Share.share(shareText);
  }

  /// 取引履歴サマリーをシェア
  Future<void> shareTransactionSummary({
    required String dateRange,
    required String categoryFilter,
    required double totalAmount,
    required int transactionCount,
    GlobalKey? previewKey,
  }) async {
    final shareText = '''
家計簿ポン 取引履歴サマリー

期間: $dateRange
カテゴリー: $categoryFilter
取引件数: $transactionCount 件
合計金額: ¥${_formatNumber(totalAmount.abs())}

#家計簿ポン #家計管理 #支出分析
''';

    if (previewKey != null) {
      final imageBytes = await captureWidgetToImage(previewKey);
      if (imageBytes != null) {
        final imagePath = await saveTempImage(imageBytes,
            'history_${DateTime.now().millisecondsSinceEpoch}.png');
        if (imagePath != null) {
          await Share.shareXFiles([XFile(imagePath)], text: shareText);
          return;
        }
      }
    }

    await Share.share(shareText);
  }

  /// 数値を3桁区切りでフォーマット
  String _formatNumber(double number) {
    return number.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
