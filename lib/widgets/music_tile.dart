import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/PlayerController.dart';
import '../models/song.dart';

class MusicTile extends StatelessWidget {
  final Song song;
  final int index;

  const MusicTile({Key? key, required this.song, required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    final primaryColor = Theme.of(context).colorScheme.onSecondary;

    return Obx(() {
      final isDownloaded = playerController.downloadedSongs.contains(song.url);
      final isCurrentSong = playerController.currentIndex.value == index;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Card(
          color: isCurrentSong
              ? Colors.green.shade700
              : Colors.green.shade400.withAlpha(50),
          elevation: isDownloaded ? 6 : 3,
          child: ListTile(
            leading: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 40,
            ),
            title: Text(
              song.name,
              style: TextStyle(
                fontWeight: isDownloaded ? FontWeight.bold : FontWeight.normal,
                color: Colors.white,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // trailing: IconButton(
            //   icon: Icon(
            //     isDownloaded ? Icons.check : Icons.download,
            //     color: isDownloaded ? Colors.white : primaryColor,
            //   ),
            //   tooltip: isDownloaded ? "Available offline" : "Download song",
            //   // onPressed: () async {
            //   //   if (!isDownloaded) {
            //   //     await playerController.downloadSong(index);
            //   //     playerController
            //   //         .showSuccessSnackbar("${song.name} has been downloaded");
            //   //   } else {
            //   //     playerController
            //   //         .showSuccessSnackbar("${song.name} is available offline");
            //   //   }
            //   // },
            // ),
            onTap: () {
              playerController.playSong(index);
              // showCustomBottomSheet(context,PlayerWidget());
            },
          ),
        ),
      );
    });
  }
}
