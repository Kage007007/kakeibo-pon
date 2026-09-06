import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

/// バナー広告ウィジェット
///
/// 指定されたサイズのバナー広告を表示します。
/// エラー発生時は空のスペースを表示し、30秒後に自動再試行します。
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final String adUnitId;
  final bool isEnabled;
  final String debugLabel;

  const BannerAdWidget({
    super.key,
    this.adSize = const AdSize(width: 320, height: 50),  // デフォルト: Banner (320x50)
    required this.adUnitId,
    this.isEnabled = true,
    this.debugLabel = 'Banner',
  });

  /// 標準バナー (320x50) を作成
  factory BannerAdWidget.banner() {
    return BannerAdWidget(
      adSize: AdConfig.bannerAdSize,
      adUnitId: AdConfig.bannerAdUnitId,
      isEnabled: AdConfig.enableBannerAds,
      debugLabel: 'Banner',
    );
  }

  /// Medium Rectangle (300x250) を作成
  factory BannerAdWidget.mediumRectangle() {
    return BannerAdWidget(
      adSize: AdConfig.mediumRectangleAdSize,
      adUnitId: AdConfig.mediumRectangleAdUnitId,
      isEnabled: AdConfig.enableMediumRectangleAds,
      debugLabel: 'MediumRectangle',
    );
  }

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEnabled) {
      _loadBannerAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  /// バナー広告のロード
  void _loadBannerAd() {
    if (_isLoading || !widget.isEnabled) return;

    _isLoading = true;

    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isLoading = false;
            });
            debugPrint('✅ ${widget.debugLabel} ad loaded successfully');
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ ${widget.debugLabel} ad failed to load: ${error.message}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isAdLoaded = false;
              _isLoading = false;
            });

            // 30秒後に自動再試行
            Future.delayed(const Duration(seconds: 30), () {
              if (mounted) {
                _loadBannerAd();
              }
            });
          }
        },
        onAdOpened: (ad) {
          debugPrint('📱 ${widget.debugLabel} ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('🔙 ${widget.debugLabel} ad closed');
        },
        onAdImpression: (ad) {
          debugPrint('👁️ ${widget.debugLabel} ad impression recorded');
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    // 広告が無効の場合は何も表示しない
    if (!widget.isEnabled) {
      return const SizedBox.shrink();
    }

    // 広告のスペースを事前に確保（レイアウトシフト防止）
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      child: _isAdLoaded && _bannerAd != null
          ? AdWidget(ad: _bannerAd!)
          : Container(
              // ロード中・失敗時は空のスペースを表示（高さは維持）
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : null,
            ),
    );
  }
}
