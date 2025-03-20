import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdController extends GetxController {
  // Banner Ad
  late BannerAd bannerAd;
  var isBannerAdLoaded = false.obs;

  // Interstitial Ad
  InterstitialAd? interstitialAd;

  @override
  void onInit() {
    super.onInit();
    loadBannerAd();
    loadInterstitialAd();
  }

  // Load Banner Ad
  void loadBannerAd() {
    bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Replace with real ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          isBannerAdLoaded.value = true;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          isBannerAdLoaded.value = false;
        },
      ),
    );
    bannerAd.load();
  }

  // Load Interstitial Ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Replace with real ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          interstitialAd = null;
        },
      ),
    );
  }

  // Show Interstitial Ad
  void showInterstitialAd() {
    if (interstitialAd != null) {
      interstitialAd!.show();
      interstitialAd = null;
      loadInterstitialAd();
    }
  }

  @override
  void onClose() {
    bannerAd.dispose();
    interstitialAd?.dispose();
    super.onClose();
  }
}
