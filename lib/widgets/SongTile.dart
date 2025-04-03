import 'package:anshed/widgets/text_styles.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rename/platform_file_editors/abs_platform_file_editor.dart';

import '../controllers/PlayerController.dart';

class SongTile extends StatelessWidget {
  final MediaItem mediaItem;
  final int index;
  final VoidCallback? onAddToPlaylist; // Make optional

  const SongTile({
    Key? key,
    required this.mediaItem,
    required this.index,
    this.onAddToPlaylist,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AudioPlayerController>(
        builder: (AudioPlayerController controller) {
      // final bool isCurrent = controller.currentMediaItem.value?.id == mediaItem.id;
      final bool isPlaying =
          mediaItem.id == controller.currentMediaItem.value?.id;

      return Container(
        color: isPlaying ? Colors.green.shade500 : Colors.transparent,
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              mediaItem.artUri?.toString() ?? 'assets/s.png',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset('assets/s.png'),
            ),
          ),
          title: Text(mediaItem.title, style: textStyle(context)),
          subtitle: Text(
            mediaItem.artist ?? 'Unknown Artist',
            style: smallTextStyle(context),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<bool>(
                  future: controller.isSongCached(mediaItem.id),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      return Icon(Icons.memory, color: Colors.white);
                    } else if (snapshot.hasError) {
                      return Icon(Icons.error_outline);
                    } else {
                      return CircularProgressIndicator();
                    }
                  })
            ],
          ),
            onTap: () async {
              int clickedIndex = index; // Capture index before async calls
              logger.i('Clicked index: $clickedIndex');
              await controller.playPlaylist(controller.playlist,
                  startIndex: clickedIndex);
              controller.update();
            }),
      );
    });
  }
}
