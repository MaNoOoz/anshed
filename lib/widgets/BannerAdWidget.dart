import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../controllers/AdController.dart';

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final adController = Get.find<AdController>();

    return Obx(() {
      if (!adController.isBannerAdLoaded.value) {
        return const SizedBox.shrink(); // or a loading indicator
      }
      return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: adController.bannerAd.size.width.toDouble(),
          height: adController.bannerAd.size.height.toDouble(),
          child: AdWidget(ad: adController.bannerAd),
        ),
      );
    });
  }
}
