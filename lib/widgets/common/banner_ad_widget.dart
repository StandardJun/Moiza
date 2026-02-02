import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// google_mobile_ads는 웹에서 사용할 수 없지만,
// 조건부 컴파일을 통해 웹에서는 호출되지 않음
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:moiza/services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    // AdService 상태 변화 감지
    _adService.addListener(_onAdServiceChanged);
  }

  @override
  void dispose() {
    _adService.removeListener(_onAdServiceChanged);
    super.dispose();
  }

  void _onAdServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 웹에서는 AdSense 플레이스홀더 표시
    if (kIsWeb) {
      return _buildWebAdBanner();
    }

    // 모바일에서는 AdMob 배너 표시
    return _buildMobileAdBanner();
  }

  // 웹용 AdSense 광고 영역 플레이스홀더
  // 실제 AdSense 광고는 index.html에서 JavaScript로 삽입됨
  Widget _buildWebAdBanner() {
    return Container(
      alignment: Alignment.center,
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ad_units, color: Colors.grey[400], size: 20),
          const SizedBox(height: 4),
          Text(
            '광고',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // 모바일용 AdMob 배너
  Widget _buildMobileAdBanner() {
    if (!_adService.isBannerAdLoaded || _adService.bannerAd == null) {
      // 광고 로딩 중 플레이스홀더 표시
      return Container(
        alignment: Alignment.center,
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '광고 로딩 중...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      width: _adService.bannerAd!.size.width.toDouble(),
      height: _adService.bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _adService.bannerAd!),
    );
  }
}
