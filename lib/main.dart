import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'controllers/PlayerController.dart';
import 'views/home_page.dart';

// Check for internet connection

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
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
        home: const HomePage());
  }
}
