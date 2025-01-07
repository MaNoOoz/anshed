import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/PlayerController.dart';
import '../widgets/PlayerWidget.dart';
import '../widgets/music_tile.dart';

class HomePage extends StatelessWidget {
  final PlayerController playerController = Get.put(PlayerController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black12,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          title: Text("أناشيد الثورة السورية"),
          actions: [
            IconButton(
                onPressed: () async {

                  await playerController.hasNewSongs();
                  await playerController.checkDownloadedSongs();
                   playerController.showDownloadDialog();

                },
                icon: Icon(Icons.download_for_offline))
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playerController.songList.length,
                itemBuilder: (context, index) {
                  return MusicTile(
                    song: playerController.songList[index],
                    index: index,
                  );
                },
              ),
            ),

            // PlayerWidget at the bottom
            PlayerWidget(),
          ],
        ),
      ),
    );
  }
}
