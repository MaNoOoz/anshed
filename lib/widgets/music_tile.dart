import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/PlayerController.dart';
import '../models/song.dart';

class MusicTile extends StatelessWidget {
  final Song song;
  final int index; // Pass the index of the song in the list
  MusicTile({required this.song, required this.index});
  final PlayerController playerController = Get.find<PlayerController>();

  @override
  Widget build(BuildContext context) {
    final isDownloaded = playerController.downloadedSongs.contains(song.url);
    final primaryColor = Theme.of(context).colorScheme.onSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        onTap: () => playerController.playSong(
            playerController.songList.indexOf(song)),
        child: Card(
          color: isDownloaded ? Colors.green[500] : null, // Highlight if downloaded
          child: ListTile(
            // leading: Icon(Icons.offline_pin_rounded, color: isDownloaded ? Colors.white : primaryColor),
            leading: Icon(Icons.offline_pin_rounded, color: isDownloaded ? Colors.white : primaryColor),
            title: Text(
              song.name,
              style: TextStyle(fontWeight: isDownloaded ? FontWeight.bold : FontWeight.normal),
            ),
            trailing: isDownloaded
                ? Icon(Icons.check, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}
