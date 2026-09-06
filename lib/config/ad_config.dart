import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 広告設定の一元管理クラス
///
/// このファイルを編集するだけで全広告設定を変更できます。
/// 頻度制御、広告ID、ON/OFFなどすべてここで管理します。
class AdConfig {
  // =========================================
  // 1. AdMob App ID & Ad Unit ID
  // =========================================

  // iOS App ID（本番用）
  static const String _iosAppId = 'ca-app-pub-5520164831450548~8760023855';

  // テスト広告ユニットID
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testNativeAdUnitId = 'ca-app-pub-3940256099942544/3986624511';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

  // 本番広告ユニットID
  static const String _iosBannerAdUnitId = 'ca-app-pub-5520164831450548/2438158086';  // Medium Rectangle
  static const String _iosNativeAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/2222222222';  // 未使用
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-5520164831450548/7219711471';
  static const String _iosRewardedAdUnitId = 'ca-app-pub-5520164831450548/5810381097';  // テーマガチャ用

  // =========================================
  // 2. 開発/本番モード切り替え
  // =========================================

  /// true: テスト広告を使用 / false: 本番広告を使用
  ///
  /// ⚠️ リリース前に必ずfalseに変更すること！
  static const bool useTestAds = false;

  // =========================================
  // 3. 広告有効化フラグ（広告タイプ別ON/OFF）
  // =========================================

  static const bool enableBannerAds = true;
  static const bool enableMediumRectangleAds = true;  // Medium Rectangle (300x250)
  static const bool enableNativeAds = true;
  static const bool enableInterstitialAds = true;
  static const bool enableRewardedAds = true;

  // =========================================
  // 4. インタースティシャル広告 頻度制御
  // =========================================

  /// InputScreen保存時の頻度設定（現在未使用）
  ///
  /// 数値を変更するだけで頻度を調整できます。
  static const AdFrequencyConfig inputScreenInterstitial = AdFrequencyConfig(
    showEveryNTimes: 5,           // 5回保存ごとに1回表示
    minimumIntervalMinutes: 10,   // 最後の表示から10分以上経過必須
    dailyLimit: 10,               // 1日最大10回まで表示
  );

  /// 詳細画面遷移時の頻度設定（本番用）
  static const AdFrequencyConfig detailNavigationInterstitial = AdFrequencyConfig(
    showEveryNTimes: 10,          // 10回遷移ごとに1回表示
    minimumIntervalMinutes: 5,    // 最後の表示から5分以上経過必須
    dailyLimit: 10,               // 1日最大10回まで表示
  );

  // =========================================
  // 5. バナー広告設定
  // =========================================

  static const BannerAdConfig bannerAdConfig = BannerAdConfig(
    positionInAnalysisScreen: BannerPosition.afterMonthComparison,
    topMargin: 16.0,
    bottomMargin: 16.0,
  );

  // =========================================
  // 6. ネイティブ広告設定
  // =========================================

  static const NativeAdConfig nativeAdConfig = NativeAdConfig(
    replaceSecondSummaryCard: true,  // 2番目のサマリーカードを広告に置き換え
    adHeight: 120.0,
    showAdBadge: true,
  );

  // =========================================
  // 7. リワード広告設定
  // =========================================

  static const RewardedAdConfig rewardedAdConfig = RewardedAdConfig(
    rewardAmount: 0,
    buttonLabel: '開発者を応援',
  );

  // =========================================
  // 8. Getter（実行時に適切なIDを返す）
  // =========================================

  static String get appId {
    if (Platform.isIOS) {
      return _iosAppId;
    }
    throw UnsupportedError('Androidは未対応');
  }

  static String get bannerAdUnitId {
    if (!enableBannerAds) return '';
    if (Platform.isIOS) {
      return useTestAds ? _testBannerAdUnitId : _iosBannerAdUnitId;
    }
    throw UnsupportedError('Androidは未対応');
  }

  static String get mediumRectangleAdUnitId {
    if (!enableMediumRectangleAds) return '';
    if (Platform.isIOS) {
      // Medium Rectangleもバナーと同じテストIDを使用
      return useTestAds ? _testBannerAdUnitId : _iosBannerAdUnitId;
    }
    throw UnsupportedError('Androidは未対応');
  }

  static String get nativeAdUnitId {
    if (!enableNativeAds) return '';
    if (Platform.isIOS) {
      return useTestAds ? _testNativeAdUnitId : _iosNativeAdUnitId;
    }
    throw UnsupportedError('Androidは未対応');
  }

  static String get interstitialAdUnitId {
    if (!enableInterstitialAds) return '';
    if (Platform.isIOS) {
      return useTestAds ? _testInterstitialAdUnitId : _iosInterstitialAdUnitId;
    }
    throw UnsupportedError('Androidは未対応');
  }

  static String get rewardedAdUnitId {
    if (!enableRewardedAds) return '';
    if (Platform.isIOS) {
      return useTestAds ? _testRewardedAdUnitId : _iosRewardedAdUnitId;
    }
    throw UnsupportedError('Androidは未対応');
  }

  /// バナー広告のサイズを取得
  static AdSize get bannerAdSize => AdSize.banner;  // 320x50

  /// Medium Rectangle広告のサイズを取得
  static AdSize get mediumRectangleAdSize => AdSize.mediumRectangle;  // 300x250
}

// =========================================
// 設定用データクラス
// =========================================

/// 広告表示頻度の設定
class AdFrequencyConfig {
  /// N回に1回表示（例: 5 = 5回ごとに1回）
  final int showEveryNTimes;

  /// 前回表示からの最小間隔（分）
  final int minimumIntervalMinutes;

  /// 1日あたりの表示上限
  final int dailyLimit;

  const AdFrequencyConfig({
    required this.showEveryNTimes,
    required this.minimumIntervalMinutes,
    required this.dailyLimit,
  });
}

/// バナー広告の設定
class BannerAdConfig {
  final BannerPosition positionInAnalysisScreen;
  final double topMargin;
  final double bottomMargin;

  const BannerAdConfig({
    required this.positionInAnalysisScreen,
    required this.topMargin,
    required this.bottomMargin,
  });
}

/// バナー広告の配置位置
enum BannerPosition {
  afterMonthComparison,  // 対前月比較グラフの下
  beforeHistoryCard,     // 取引履歴カードの上
  bottomOfScreen,        // 画面最下部
}

/// ネイティブ広告の設定
class NativeAdConfig {
  final bool replaceSecondSummaryCard;
  final double adHeight;
  final bool showAdBadge;

  const NativeAdConfig({
    required this.replaceSecondSummaryCard,
    required this.adHeight,
    required this.showAdBadge,
  });
}

/// リワード広告の設定
class RewardedAdConfig {
  final int rewardAmount;
  final String buttonLabel;

  const RewardedAdConfig({
    required this.rewardAmount,
    required this.buttonLabel,
  });
}
