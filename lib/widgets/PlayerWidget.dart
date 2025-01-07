import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/PlayerController.dart';
import 'SeekBar.dart';
import 'VolDialoag.dart';

class PlayerWidget extends StatelessWidget {
  final PlayerController controller = Get.put(PlayerController());

  PlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPlaying = controller.isPlaying.value;
      final currentIndex = controller.currentIndex.value;
      final currentSongName = currentIndex != -1
          ? controller.songList[currentIndex].name
          : 'No song playing';

      return Container(
        height: 300,
        color: Colors.green.withAlpha(22),
        child: Column(
          children: [
            SizedBox(
              height: 22,
            ),
            // Slider(
            //   value: controller.volume.value,
            //   onChanged: (newVolume) {
            //     controller.setVolume(newVolume);
            //   },
            //   min: 0,
            //   max: 1,
            // ),
            // Text(
            // 'Volume: ${(controller.volume.value * 100).toStringAsFixed(0)}%'),
            // Title
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    currentSongName,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      // color: Colors.black,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Progress Bar
            StreamBuilder<Duration>(
              stream: controller.player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = controller.player.duration ?? Duration.zero;
                final bufferedPosition =
                    controller.player.bufferedPosition ?? Duration.zero;

                return SeekBar(
                  duration: duration,
                  position: position,
                  bufferedPosition: bufferedPosition,
                  onChanged: (newPosition) {
                    controller.player.seek(newPosition);
                  },
                );
              },
            ),

            // Controls
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: controller.previousSong,
                    icon: const Icon(Icons.navigate_before),
                    iconSize: 36,
                  ),
                  IconButton(
                    icon: Icon(isPlaying
                        ? Icons.pause_circle_filled_outlined
                        : Icons.play_arrow_rounded),
                    iconSize: 64.0,
                    color: isPlaying ? Colors.green : Colors.white,
                    // Highlight when playing
                    onPressed: () async {
                      if (isPlaying) {
                        controller.pause();
                      } else {
                        controller.player.play();
                      }
                      // if (currentIndex != -1) {
                      //   controller.playSong(currentIndex);
                      // }
                    },
                  ),
                  IconButton(
                    onPressed: controller.nextSong,
                    icon: const Icon(Icons.navigate_next_outlined),
                    iconSize: 36,
                  ),
                  VolumeControlScreen(),
                  // IconButton(
                  //   onPressed: controller.player.stop,
                  //   icon: const Icon(Icons.stop_circle_rounded),
                  //   iconSize: 36,
                  // ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
