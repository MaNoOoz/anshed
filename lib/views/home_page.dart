import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/PlayerController.dart';
import '../widgets/PlayerWidget.dart';
import '../widgets/music_tile.dart';

class HomePage extends StatelessWidget {
  final PlayerController playerController = Get.put(PlayerController());
  final bool isFirstTime;

  HomePage({required this.isFirstTime});

  void _showWelcomeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Welcome!'),
          content: const Text('This is your first time using the app.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstTime) {
      Future.delayed(Duration.zero, () => _showWelcomeDialog(context));
    }
    if (playerController.songList.length < 0) {
      return CircularProgressIndicator();
    }

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("أناشيد الثورة السورية")),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return ListView.builder(
                itemCount: playerController.songList.length,
                itemBuilder: (context, index) {
                  return MusicTile(
                    song: playerController.songList[index],
                    index: index,
                  );
                },
              );
            }),
          ),
          PlayerWidget(),
        ],
      ),
    );
  }
}
