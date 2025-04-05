import 'package:anshed/widgets/PlayerModal.dart';
import 'package:anshed/widgets/text_styles.dart';
import 'package:audio_service/audio_service.dart';
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
      appBar: AppBar(
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
          mediaItem: mediaItem, // Pass MediaItem for UI
        );
      },
    );
  }
}
