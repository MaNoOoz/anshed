import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

class AdController extends GetxController with WidgetsBindingObserver {
  // Banner Ad
  late BannerAd bannerAd;
  var isBannerAdLoaded = false.obs;

  // Interstitial Ad
  InterstitialAd? interstitialAd;
  AppOpenAd? _appOpenAd;
  var isAppOpenAdLoaded = false.obs;
  DateTime? _appOpenAdLoadTime;
  final String _appOpenAdUnitId =
      "ca-app-pub-7749685655844830/7718562127"; //test id // Replace with your AppOpenAd unit ID

  // Rewarded Ad
  RewardedAd? _rewardedAd;
  var isRewardedAdLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadBannerAd();
    loadInterstitialAd();
    // _loadRewardedAd(); // Load rewarded ad on initialization
    _loadAppOpenAd();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _showAppOpenAdIfAvailable();
    }
  }

  // AppOpenAd
  bool get isAppOpenAdAvailable {
    return _appOpenAd != null && _wasLoadTimeLessThanNHoursAgo(4);
  }

  bool _wasLoadTimeLessThanNHoursAgo(int n) {
    if (_appOpenAdLoadTime == null) {
      return false;
    }
    DateTime date = _appOpenAdLoadTime!;
    DateTime now = DateTime.now();
    return now.difference(date).inHours < n;
  }

  void _loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          isAppOpenAdLoaded.value = true;
          _appOpenAdLoadTime = DateTime.now();
          Logger().i('App open ad loaded.');

          // Assign onPaidEvent callback
          _appOpenAd?.onPaidEvent = (ad, impressionData) {
            Logger().e('Ad Impression: ${impressionData.valueMicros}');
          } as OnPaidEventCallback?;

          _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _appOpenAd = null;
              isAppOpenAdLoaded.value = false;
              _loadAppOpenAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _appOpenAd = null;
              isAppOpenAdLoaded.value = false;
              Logger().e("App open ad failed to show: $error");
              _loadAppOpenAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          isAppOpenAdLoaded.value = false;
          Logger().e("App open ad failed to load: $error");
        },
      ),
    );
  }

  void _showAppOpenAdIfAvailable() {
    if (isAppOpenAdAvailable) {
      Logger().e("Show App Open ad ");
      _appOpenAd!.show();
    } else {
      Logger().e("App Open ad not available yet ");
    }
  }

  @override
  void onClose() {
    bannerAd.dispose();
    interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  // Load Banner Ad
  void loadBannerAd() {
    bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7749685655844830/9439892669',
      // Replace with real ID
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
      adUnitId: 'ca-app-pub-7749685655844830/7228678203',
      // Replace with real ID
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
  // void _loadRewardedAd() {
  //   RewardedAd.load(
  //     adUnitId: rewardedAdUnitId,
  //     request: AdRequest(),
  //     rewardedAdLoadCallback: RewardedAdLoadCallback(
  //       onAdLoaded: (ad) {
  //         _rewardedAd = ad;
  //         isRewardedAdLoaded.value = true;
  //
  //         // Set up full-screen content callback
  //         ad.fullScreenContentCallback = FullScreenContentCallback(
  //           onAdDismissedFullScreenContent: (ad) {
  //             _rewardedAd = null;
  //             isRewardedAdLoaded.value = false;
  //             _loadRewardedAd(); // Reload a new rewarded ad
  //           },
  //           onAdFailedToShowFullScreenContent: (ad, error) {
  //             _rewardedAd = null;
  //             isRewardedAdLoaded.value = false;
  //             _loadRewardedAd(); // Reload a new rewarded ad
  //           },
  //         );
  //       },
  //       onAdFailedToLoad: (error) {
  //         _rewardedAd = null;
  //         isRewardedAdLoaded.value = false;
  //         Logger().e('Failed to load rewarded ad: ${error.message}');
  //       },
  //     ),
  //   );
  // }

  // Show Rewarded Ad
  // void showRewardedAd() {
  //   if (_rewardedAd == null) {
  //     Logger().e('No rewarded ad loaded.');
  //     return;
  //   }
  //
  //   // Show the rewarded ad
  //   _rewardedAd!.show(
  //     onUserEarnedReward: (ad, reward) {
  //       // Handle the reward
  //       Logger().i('User earned reward: ${reward.amount} ${reward.type}');
  //       // Grant the reward to the user (e.g., add coins, unlock features, etc.)
  //     },
  //   );
  // }

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
      return 'ca-app-pub-7749685655844830/7228678203'; // Replace with real ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7749685655844830/7228678203'; // Replace with real ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
