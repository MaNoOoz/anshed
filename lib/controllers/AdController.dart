import 'dart:io';

import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

class AdController extends GetxController {
  // Banner Ad
  late BannerAd bannerAd;
  var isBannerAdLoaded = false.obs;

  // Interstitial Ad
  InterstitialAd? interstitialAd;

  // Rewarded Ad
  RewardedAd? _rewardedAd;
  var isRewardedAdLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadBannerAd();
    loadInterstitialAd();
    _loadRewardedAd(); // Load rewarded ad on initialization
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

  // Load Rewarded Ad
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isRewardedAdLoaded.value = true;

          // Set up full-screen content callback
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _rewardedAd = null;
              isRewardedAdLoaded.value = false;
              _loadRewardedAd(); // Reload a new rewarded ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _rewardedAd = null;
              isRewardedAdLoaded.value = false;
              _loadRewardedAd(); // Reload a new rewarded ad
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          isRewardedAdLoaded.value = false;
          Logger().e('Failed to load rewarded ad: ${error.message}');
        },
      ),
    );
  }

  // Show Rewarded Ad
  void showRewardedAd() {
    if (_rewardedAd == null) {
      Logger().e('No rewarded ad loaded.');
      return;
    }

    // Show the rewarded ad
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        // Handle the reward
        Logger().i('User earned reward: ${reward.amount} ${reward.type}');
        // Grant the reward to the user (e.g., add coins, unlock features, etc.)
      },
    );
  }

  // Show Interstitial Ad
  void showInterstitialAd() {
    if (interstitialAd == null) {
      Logger().e('No interstitial ad loaded.');
      return;
    }
    interstitialAd!.show();
    interstitialAd = null;
    loadInterstitialAd(); // Load a new interstitial ad
  }

  // Get rewarded ad unit ID based on platform
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Replace with real ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Replace with real ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  @override
  void onClose() {
    bannerAd.dispose();
    interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.onClose();
  }
}