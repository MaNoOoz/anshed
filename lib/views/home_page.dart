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
      bottomSheet: PlayerModal(),
      appBar: AppBar(
          title: Text('أغاني الثورة السورية', style: bigTextStyle(context))),
      body: Obx(() {
        switch (_audioController.loadingState.value) {
          case LoadingState.loading:
            return Center(child: CircularProgressIndicator());
          case LoadingState.error:
            return Center(child: Text('Error loading songs'));
          case LoadingState.success:
            return _buildPlaylist();
          default:
            return SizedBox();
        }
      }),
    );
  }

  Widget _buildPlaylist() {
    return ListView.builder(
      itemCount: _audioController.playlist.length,
      itemBuilder: (context, index) {
        final song = _audioController.playlist[index];
        Logger().i('_audioController ${_audioController.playlist.length}');

        return SongTile(
          index: index,
          mediaItem: MediaItem(
            id: song.fileId,
            title: song.title,
            artist: song.artist,
            artUri: Uri.parse('assets/s.png'),
          ),
        );
      },
    );
  }
}
