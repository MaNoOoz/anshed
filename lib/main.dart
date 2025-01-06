import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const appId = 'sXNSN01jZLzR5m5dRZjhvbptGqrve2yOz780MmIc';
  const clientKey = 'FGm2QzvoLtskcnLJFoDlOIQGMlXRN1q3l2KPirBJ';
  const parseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(appId, parseServerUrl, clientKey: clientKey);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkFirstTimeUser(), // Check if the user is opening the app for the first time
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Show a loading indicator while checking
        }

        final isFirstTime = snapshot.data ?? false;

        return GetMaterialApp(
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
          home: HomePage(isFirstTime: isFirstTime),
        );
      },
    );
  }

  Future<bool> checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false); // Mark as not first time
    }

    return isFirstTime;
  }
}
