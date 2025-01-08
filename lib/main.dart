import 'package:anshed/controllers/PlayerController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

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
        home: _bulidHome());
  }
}

_bulidHome() {
  var controller = Get.put(PlayerController());

  return HomePage();

  if (controller.initialized && controller.songList.isNotEmpty) {
    // Logger().e(controller.initialized);
    // return Container(
    //   color: Colors.green,
    // );
  } else {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 22,),

            // Container(
            //   width: double.infinity,
            //   child: IconButton(
            //     icon: const Icon(Icons.door_back_door_outlined),
            //     onPressed: ()  {
            //        controller.fetchMusicUrls();
            //
            //     },
            //     tooltip: 'Refresh Songs',
            //   ),
            // ),
            // GestureDetector(
            //   child: Center(child: Text("دخول")),
            //   onTap: () {
            //     controller.update();
            //
            //   },
            // )
          ],
        ),
      ),
    );
  }
}
