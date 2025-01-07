import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/PlayerController.dart';
import '../models/song.dart';

class MusicTile extends StatelessWidget {
  final Song song;
  final int index; // Pass the index of the song in the list
  final PlayerController playerController = Get.put(PlayerController());

  MusicTile({super.key, required this.song, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDownloaded = playerController.downloadedSongs.contains(song.url);
    final primaryColor = Theme.of(context).colorScheme.onSecondary;
    final primaryColor2 = Theme.of(context).colorScheme.primary;

    return GetBuilder<PlayerController>(builder: (logic) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        child: Stack(
          children: [
            Card(
              color: Colors.green.shade400.withAlpha(50),
              elevation: isDownloaded ? 6 : 3,
              child: ListTile(
                leading: Icon(Icons.music_note),
                title: Text(
                  song.name,
                  style: TextStyle(
                    fontWeight:
                        isDownloaded ? FontWeight.bold : FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isDownloaded ? Icons.check : Icons.download,
                    color: isDownloaded ? Colors.white : primaryColor,
                  ),
                  tooltip: isDownloaded ? "Available offline" : "Download song",
                  onPressed: () async {
                    if (!isDownloaded) {
                      await playerController.downloadSong(index);
                      playerController.update();
                      Get.snackbar(
                        "Download Complete",
                        "${song.name} has been downloaded",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(8),
                        duration: const Duration(seconds: 2),
                        icon:
                            const Icon(Icons.check_circle, color: Colors.white),
                      );
                    } else {
                      Get.snackbar(
                        "Already Downloaded",
                        "${song.name} is available offline",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.blueGrey,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(8),
                        duration: const Duration(seconds: 2),
                        icon:
                            const Icon(Icons.info_outline, color: Colors.white),
                      );
                    }
                  },
                ),
                onTap: () {
                  playerController.player.stop();
                  playerController.playSong(index);
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
