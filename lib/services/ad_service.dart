import 'package:flutter/foundation.dart';

/// 광고 서비스 플레이스홀더
/// 추후 AdMob 연동 시 실제 광고 로직으로 교체 예정
class AdService extends ChangeNotifier {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // 광고 비활성화 상태
  bool get isBannerAdLoaded => false;
  bool get isInterstitialAdLoaded => false;
  bool get isRewardedAdLoaded => false;

  // 초기화 (no-op)
  Future<void> initialize() async {
    debugPrint('AdService: 광고 기능 비활성화 상태');
  }

  // 전면 광고 표시 (no-op - 바로 콜백 호출)
  Future<void> showInterstitialAd({VoidCallback? onAdClosed}) async {
    // 광고 없이 바로 콜백 실행
    onAdClosed?.call();
  }

  // 리워드 광고 표시 (no-op)
  Future<void> showRewardedAd({
    required Function(int amount) onRewarded,
    VoidCallback? onAdClosed,
  }) async {
    // 광고 없이 바로 콜백 실행
    onAdClosed?.call();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
