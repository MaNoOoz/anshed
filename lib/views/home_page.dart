import 'package:anshed/views/settings_page.dart';
import 'package:anshed/widgets/PlayerModal.dart';
import 'package:anshed/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../controllers/PlayerController.dart';
import '../widgets/SongTile.dart';

class HomeScreen extends StatelessWidget {
  final AudioPlayerController _audioController =
      Get.find<AudioPlayerController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _audioController.createAudioSourcesFromCacheOrApi();
        },
      ),
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              Get.to(() => SettingsScreen());
            },
            icon: Icon(Icons.settings),
          )
        ],
        centerTitle: true,
        title: Text(
          'أغاني الثورة السورية',
          style: mediumTextStyle(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: Obx(() {
            return _buildPlaylist();
          })),
          PlayerModal()
        ],
      ),
    );
  }

  Widget _buildPlaylist() {
    Logger().i('Playlist length: ${_audioController.mediaPlaylist.length}');

    return ListView.builder(
      itemCount: _audioController.mediaPlaylist.length,
      itemBuilder: (context, index) {
        final mediaItem = _audioController.mediaPlaylist[index];

        return SongTile(
          index: index,
          mediaItem: mediaItem,
          onAddToPlaylist: () async {
            final currentIndex = _audioController.audioPlayer.currentIndex;

            // Only proceed if a different song is tapped
            if (index != currentIndex) {
              await _audioController.audioPlayer
                  .stop(); // optional, ExoPlayer handles this internally
              await _audioController.setCurrentIndex(index);
              await _audioController.audioPlayer.play();

              Logger().i('Now playing index $index: ${mediaItem.title}');
            } else {
              await _audioController.audioPlayer.play();

              Logger().i('Tapped current song again: ${mediaItem.title}');
            }
          },

          // Pass MediaItem for UI
        );
      },
    );
  }
}
