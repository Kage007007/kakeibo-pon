import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/ad_config.dart';

/// 広告管理サービス（Singleton）
///
/// すべての広告の読み込み、表示、頻度制御を管理します。
class AdService {
  // ========== Singletonパターン ==========
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // ========== 初期化状態 ==========
  bool _isInitialized = false;
  SharedPreferences? _prefs;

  // ========== 広告インスタンス ==========
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isLoadingInterstitial = false;
  bool _isLoadingRewarded = false;

  // ========== 頻度制御用カウンター ==========
  int _transactionSaveCount = 0;
  int _detailNavigationCount = 0;
  DateTime? _lastInterstitialShownTime;
  DateTime? _lastDailyReset;
  int _dailyInterstitialCount = 0;

  // ========== SharedPreferencesキー ==========
  static const String _inputSaveCountKey = 'ad_input_save_count';
  static const String _detailNavigationCountKey = 'ad_detail_navigation_count';
  static const String _lastInterstitialTimeKey = 'ad_last_interstitial_time';
  static const String _dailyInterstitialCountKey = 'ad_daily_interstitial_count';
  static const String _lastDailyResetKey = 'ad_last_daily_reset';

  /// SharedPreferencesへのアクセス（初期化後のみ）
  SharedPreferences get prefs {
    if (_prefs == null || !_isInitialized) {
      throw Exception('AdService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ========================================
  // 初期化
  // ========================================

  /// AdServiceの初期化
  ///
  /// main.dartのサービス初期化時に呼び出されます。
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // SharedPreferencesの初期化
      _prefs = await SharedPreferences.getInstance();
      await _loadFrequencyData();

      // インタースティシャル広告をプリロード
      if (AdConfig.enableInterstitialAds) {
        _loadInterstitialAd();
      }

      // リワード広告をプリロード
      if (AdConfig.enableRewardedAds) {
        _loadRewardedAd();
      }

      _isInitialized = true;
      debugPrint('✅ AdService initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ AdService initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 頻度制御データの読み込み
  Future<void> _loadFrequencyData() async {
    _transactionSaveCount = _prefs!.getInt(_inputSaveCountKey) ?? 0;
    _detailNavigationCount = _prefs!.getInt(_detailNavigationCountKey) ?? 0;
    _dailyInterstitialCount = _prefs!.getInt(_dailyInterstitialCountKey) ?? 0;

    final lastTimeMillis = _prefs!.getInt(_lastInterstitialTimeKey);
    _lastInterstitialShownTime = lastTimeMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(lastTimeMillis)
        : null;

    final lastResetMillis = _prefs!.getInt(_lastDailyResetKey);
    _lastDailyReset = lastResetMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(lastResetMillis)
        : null;

    // 日付が変わっていればカウンターリセット
    await _checkAndResetDailyCounter();
  }

  /// 日次カウンターのリセット確認
  Future<void> _checkAndResetDailyCounter() async {
    final now = DateTime.now();
    if (_lastDailyReset == null || !_isSameDay(_lastDailyReset!, now)) {
      _dailyInterstitialCount = 0;
      await _prefs!.setInt(_dailyInterstitialCountKey, 0);
      await _prefs!.setInt(_lastDailyResetKey, now.millisecondsSinceEpoch);
      _lastDailyReset = now;
      debugPrint('🔄 Daily ad counter reset');
    }
  }

  /// 同じ日かチェック
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ========================================
  // インタースティシャル広告
  // ========================================

  /// インタースティシャル広告のロード
  Future<void> _loadInterstitialAd() async {
    if (_isLoadingInterstitial || !AdConfig.enableInterstitialAds) return;

    _isLoadingInterstitial = true;

    try {
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isLoadingInterstitial = false;
            debugPrint('✅ Interstitial ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            _isLoadingInterstitial = false;
            _interstitialAd = null;
            debugPrint('❌ Interstitial ad failed to load: ${error.message}');

            // 10秒後に再試行
            Future.delayed(const Duration(seconds: 10), () {
              _loadInterstitialAd();
            });
          },
        ),
      );
    } catch (e, stackTrace) {
      _isLoadingInterstitial = false;
      debugPrint('❌ Exception loading interstitial ad: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// InputScreen保存後にインタースティシャル広告を表示すべきか判定
  Future<bool> shouldShowInterstitialAfterSave() async {
    if (!AdConfig.enableInterstitialAds) return false;

    final config = AdConfig.inputScreenInterstitial;

    // 条件1: N回に1回チェック
    _transactionSaveCount++;
    await prefs.setInt(_inputSaveCountKey, _transactionSaveCount);

    if (_transactionSaveCount % config.showEveryNTimes != 0) {
      return false;
    }

    // 条件2: 時間間隔チェック
    if (_lastInterstitialShownTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShownTime!);
      if (elapsed.inMinutes < config.minimumIntervalMinutes) {
        debugPrint(
            '⏱️ Too soon since last ad (${elapsed.inMinutes}min < ${config.minimumIntervalMinutes}min)');
        return false;
      }
    }

    // 条件3: 日次上限チェック
    await _checkAndResetDailyCounter();
    if (_dailyInterstitialCount >= config.dailyLimit) {
      debugPrint(
          '🚫 Daily limit reached ($_dailyInterstitialCount/${config.dailyLimit})');
      return false;
    }

    return true;
  }

  /// 詳細画面遷移時にインタースティシャル広告を表示すべきか判定
  Future<bool> shouldShowInterstitialOnNavigation() async {
    if (!AdConfig.enableInterstitialAds) return false;

    final config = AdConfig.detailNavigationInterstitial;

    // 条件1: N回に1回チェック
    _detailNavigationCount++;
    await prefs.setInt(_detailNavigationCountKey, _detailNavigationCount);

    if (_detailNavigationCount % config.showEveryNTimes != 0) {
      return false;
    }

    // 条件2: 時間間隔チェック
    if (_lastInterstitialShownTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShownTime!);
      if (elapsed.inMinutes < config.minimumIntervalMinutes) {
        return false;
      }
    }

    // 条件3: 日次上限チェック
    await _checkAndResetDailyCounter();
    if (_dailyInterstitialCount >= config.dailyLimit) {
      return false;
    }

    return true;
  }

  /// インタースティシャル広告を表示
  Future<void> showInterstitialAd({VoidCallback? onAdDismissed}) async {
    if (_interstitialAd == null) {
      debugPrint('⚠️ Interstitial ad not ready, skipping...');
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // 次の広告をプリロード
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Failed to show interstitial ad: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onAdDismissed?.call(); // 失敗してもコールバック実行
      },
    );

    await _interstitialAd!.show();
  }

  /// インタースティシャル広告表示済みマーク
  Future<void> markInterstitialShown() async {
    final now = DateTime.now();
    _lastInterstitialShownTime = now;
    _dailyInterstitialCount++;

    await prefs.setInt(_lastInterstitialTimeKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_dailyInterstitialCountKey, _dailyInterstitialCount);

    debugPrint(
        '📊 Interstitial shown (daily: $_dailyInterstitialCount/${AdConfig.inputScreenInterstitial.dailyLimit})');
  }

  // ========================================
  // リワード広告
  // ========================================

  /// リワード広告のロード
  Future<void> _loadRewardedAd() async {
    if (_isLoadingRewarded || !AdConfig.enableRewardedAds) return;

    _isLoadingRewarded = true;

    try {
      await RewardedAd.load(
        adUnitId: AdConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoadingRewarded = false;
            debugPrint('✅ Rewarded ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            _isLoadingRewarded = false;
            _rewardedAd = null;
            debugPrint('❌ Rewarded ad failed to load: ${error.message}');

            // 10秒後に再試行
            Future.delayed(const Duration(seconds: 10), () {
              _loadRewardedAd();
            });
          },
        ),
      );
    } catch (e, stackTrace) {
      _isLoadingRewarded = false;
      debugPrint('❌ Exception loading rewarded ad: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// リワード広告を表示
  Future<void> showRewardedAd({
    required Function(int amount, String type) onUserEarnedReward,
    VoidCallback? onAdDismissed,
  }) async {
    if (_rewardedAd == null) {
      debugPrint('⚠️ Rewarded ad not ready');
      onAdDismissed?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // 次の広告をプリロード
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Failed to show rewarded ad: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        onAdDismissed?.call();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('🎁 User earned reward: ${reward.amount} ${reward.type}');
        onUserEarnedReward(reward.amount.toInt(), reward.type);
      },
    );
  }

  // ========================================
  // ユーティリティ
  // ========================================

  /// すべてのカウンターをリセット（デバッグ用）
  Future<void> resetAllCounters() async {
    await prefs.remove(_inputSaveCountKey);
    await prefs.remove(_detailNavigationCountKey);
    await prefs.remove(_lastInterstitialTimeKey);
    await prefs.remove(_dailyInterstitialCountKey);
    await prefs.remove(_lastDailyResetKey);

    _transactionSaveCount = 0;
    _detailNavigationCount = 0;
    _lastInterstitialShownTime = null;
    _dailyInterstitialCount = 0;
    _lastDailyReset = null;

    debugPrint('🔄 All ad counters reset');
  }

  /// 現在の統計を取得（デバッグ用）
  Map<String, dynamic> getStats() {
    return {
      'isInitialized': _isInitialized,
      'transactionSaveCount': _transactionSaveCount,
      'detailNavigationCount': _detailNavigationCount,
      'dailyInterstitialCount': _dailyInterstitialCount,
      'lastInterstitialShownTime': _lastInterstitialShownTime?.toIso8601String(),
      'interstitialAdReady': _interstitialAd != null,
      'rewardedAdReady': _rewardedAd != null,
    };
  }
}
