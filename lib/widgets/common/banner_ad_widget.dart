import 'package:flutter/material.dart';
import 'package:moiza/config/theme.dart';

/// 광고 영역 플레이스홀더
/// 추후 AdMob/AdSense 연동 시 실제 광고로 교체 예정
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ad_units_outlined, color: AppTheme.textTertiary, size: 18),
          const SizedBox(width: 8),
          Text(
            '광고 영역',
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
