import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:study_penalty/config/constants.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;

  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;

  BannerAd? get bannerAd => _bannerAd;

  // 초기화
  Future<void> initialize() async {
    // 웹에서는 google_mobile_ads가 지원되지 않음
    if (kIsWeb) {
      debugPrint('웹 플랫폼: 광고 비활성화');
      return;
    }

    await MobileAds.instance.initialize();

    // 배너 광고 미리 로드
    loadBannerAd();
    // 전면 광고 미리 로드
    loadInterstitialAd();
    // 리워드 광고 미리 로드
    loadRewardedAd();
  }

  // 배너 광고 로드
  void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          debugPrint('배너 광고 로드됨');
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdLoaded = false;
          ad.dispose();
          debugPrint('배너 광고 로드 실패: ${error.message}');
          // 5초 후 재시도
          Future.delayed(const Duration(seconds: 5), loadBannerAd);
        },
      ),
    );
    _bannerAd!.load();
  }

  // 전면 광고 로드
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          debugPrint('전면 광고 로드됨');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdLoaded = false;
              loadInterstitialAd(); // 다음 광고 미리 로드
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdLoaded = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
          debugPrint('전면 광고 로드 실패: ${error.message}');
          Future.delayed(const Duration(seconds: 5), loadInterstitialAd);
        },
      ),
    );
  }

  // 리워드 광고 로드
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          debugPrint('리워드 광고 로드됨');
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          debugPrint('리워드 광고 로드 실패: ${error.message}');
          Future.delayed(const Duration(seconds: 5), loadRewardedAd);
        },
      ),
    );
  }

  // 전면 광고 표시 (출석 체크 후)
  Future<void> showInterstitialAd({VoidCallback? onAdClosed}) async {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialAdLoaded = false;
          loadInterstitialAd();
          onAdClosed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isInterstitialAdLoaded = false;
          loadInterstitialAd();
          onAdClosed?.call();
        },
      );
      await _interstitialAd!.show();
    } else {
      onAdClosed?.call();
    }
  }

  // 리워드 광고 표시 (선택적 - 벌금 감면 등)
  Future<void> showRewardedAd({
    required Function(int amount) onRewarded,
    VoidCallback? onAdClosed,
  }) async {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          loadRewardedAd();
          onAdClosed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          loadRewardedAd();
          onAdClosed?.call();
        },
      );
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onRewarded(reward.amount.toInt());
        },
      );
    } else {
      onAdClosed?.call();
    }
  }

  // 정리
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
