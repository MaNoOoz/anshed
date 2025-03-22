import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SessionManager extends GetxController with WidgetsBindingObserver {
  DateTime? _startTime;
  Timer? _adTimer;
  bool _isAdShown = false;
  final _logger = Logger();

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _adTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _logger.e('App lifecycle state changed to: $state');
    switch (state) {
      case AppLifecycleState.resumed:
        _startSession();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        _endSession();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _startSession() {
    _startTime = DateTime.now();
    _isAdShown = false;
    _startAdTimer();
    _logger.e('Session started at: $_startTime');
  }

  void _endSession() {
    if (_startTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime!);

    _logger.e('Session ended at: $endTime');
    _logger.e('Session duration: ${duration.inSeconds} seconds');

    _adTimer?.cancel();
    _startTime = null;
  }

  void _startAdTimer() {
    _adTimer?.cancel(); // Cancel any existing timer
    _adTimer = Timer(const Duration(seconds: 5), () {
      _showAd();
    });
  }

  void _showAd() {
    if (!_isAdShown) {
      _logger.e('Showing ad now!');
      showInterstitialAd();
      _isAdShown = true; // Prevent showing multiple ads
    }
  }

  // Load and display the interstitial ad
  InterstitialAd? interstitialAd;

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: "ca-app-pub-3940256099942544/1033173712",
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          _logger.e("InterstitialAd Ad loaded");
        },
        onAdFailedToLoad: (error) {
          _logger.e("InterstitialAd Ad failed to load: $error");
        },
      ),
    );
  }

  void showInterstitialAd() {
    _logger.e("showInterstitialAd Called ");

    if (interstitialAd != null) {
      interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {},
        onAdFailedToShowFullScreenContent: (ad, error) {
          interstitialAd!.dispose();
          interstitialAd = null;
          _logger.e("InterstitialAd Ad failed to load: $error");
        },
        onAdDismissedFullScreenContent: (ad) {
          interstitialAd!.dispose();
          interstitialAd = null;
          loadInterstitialAd();
        },
      );
      interstitialAd!.show();
    }
  }
}
