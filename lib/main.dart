import 'dart:async';

import 'package:anshed/views/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'controllers/PlayerController.dart';
import 'controllers/SessionManager.dart';
import 'controllers/SettingsController.dart';
import 'views/home_page.dart';


const appId = 'sXNSN01jZLzR5m5';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize()); // Add your test device ID here
  // Create a new RequestConfiguration with the desired settings
  RequestConfiguration requestConfiguration = RequestConfiguration(
    testDeviceIds: ["387845A5FCBC0B2B29189CEAC8B80EC7"],
    // Replace with your test device IDs if needed
    tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
    // Set as needed
    maxAdContentRating: MaxAdContentRating.g, // Set as needed
  );
  // Update the request configuration
  MobileAds.instance.updateRequestConfiguration(requestConfiguration);

  // Initialize background playback
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.manoooz.anshed.audio',
    androidNotificationChannelName: 'أناشيد الثورة السورية',
    androidNotificationOngoing: false,
    androidShowNotificationBadge: true,
    androidStopForegroundOnPause: true,
    notificationColor: Colors.green[900],
    androidNotificationClickStartsActivity: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
    fastForwardInterval: const Duration(seconds: 10),
    rewindInterval: const Duration(seconds: 10),
  );

  const appId = 'sXNSN01jZLzR5m5dRZjhvbptGqrve2yOz780MmIc';
  const clientKey = 'FGm2QzvoLtskcnLJFoDlOIQGMlXRN1q3l2KPirBJ';
  const parseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(appId, parseServerUrl, clientKey: clientKey);
  Get.put(PlayerController()); // Or Get.lazyPut(() => PlayerController());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final SettingsController settingsController = Get.put(SettingsController());

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize SessionManager
    final sessionManager = Get.put(SessionManager());
    sessionManager.loadInterstitialAd();

    return GetMaterialApp(
        getPages: [
          GetPage(name: '/Settings', page: () => SettingsScreen()),

        ],
        debugShowCheckedModeBanner: false,
        darkTheme: ThemeData.dark(),
        theme: ThemeData(
          useMaterial3: true,

          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textDirection: TextDirection.rtl,
        home: HomePage());
  }
}
