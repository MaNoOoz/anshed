import 'package:anshed/widgets/text_styles.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:logger/logger.dart';

import '../controllers/PlayerController.dart';

final logger = Logger(); // Initialize logger

class SongTile extends StatelessWidget {
  final MediaItem mediaItem;
  final int index;
  final VoidCallback? onAddToPlaylist;

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
        final bool isPlaying = mediaItem.id == controller.currentMediaItem?.id;

        return Container(
          color: isPlaying ? Colors.green.shade500 : Colors.transparent,
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/s.png',
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
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return const Icon(Icons.memory, color: Colors.white);
                    } else if (snapshot.hasError) {
                      return const Icon(Icons.error_outline);
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ],
            ),
            onTap: () async {
              int clickedIndex = index;
              logger.i('Clicked index: $clickedIndex');
              await controller.playPlaylist(controller.mediaPlaylist,
                  startIndex: clickedIndex);

              // No need for controller.update(); here
            },
          ),
        );
      },
    );
  }
}