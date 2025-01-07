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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: HomePage(),
    );
  }

}
