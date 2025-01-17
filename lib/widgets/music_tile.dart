import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/PlayerController.dart';
import '../models/song.dart';

class MusicTile extends StatelessWidget {
  final Song song;
  final int index;

  MusicTile({
    Key? key,
    required this.song,
    required this.index,
  }) : super(key: key);

  final PlayerController c = Get.find<PlayerController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isCurrentSong = c.currentSong.value?.url == song.url;
      final isPlaying = isCurrentSong && c.player.playing;
      final isDownloaded = c.downloadedSongs.contains(song.url);

      return ListTile(
        leading: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: song.artworkUrl != null && song.artworkUrl!.isNotEmpty
                  ? NetworkImage(song.artworkUrl!)
                  : const AssetImage('assets/s.png') as ImageProvider,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          song.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDownloaded)
              const Icon(
                Icons.download_done,
                color: Colors.green,
              ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                if (isCurrentSong) {
                  c.togglePlayPause();
                } else {
                  c.playSong(index);
                }
              },
            ),
          ],
        ),
        onTap: () {
          if (isCurrentSong) {
            c.togglePlayPause();
          } else {
            c.playSong(index);
          }
        },
      );
    });
  }
}
