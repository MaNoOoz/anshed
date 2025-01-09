import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

import '../controllers/PlayerController.dart';
import '../widgets/SeekBar.dart';
import '../widgets/VolDialoag.dart';

class PlayerWidget extends StatelessWidget {
  const PlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final PlayerController c = Get.find<PlayerController>();

    return Obx(() {
      return Container(
        // height: 300,
        // width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          backgroundBlendMode: BlendMode.darken,
          image: DecorationImage(
              opacity: 0.6,
              image: AssetImage('assets/s.png'),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high),
        ),
        child: Column(
          children: [
            const SizedBox(
              height: 50,
            ),
            // Title
            Text(
              c.currentSong.value?.name ?? '',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),

            // Progress Bar
            StreamBuilder<Duration>(
              stream: c.player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = c.player.duration ?? Duration.zero;
                final bufferedPosition =
                    c.player.bufferedPosition ?? Duration.zero;

                return SeekBar(
                  duration: duration,
                  position: position,
                  bufferedPosition: bufferedPosition,
                  onChanged: (newPosition) {
                    c.player.seek(newPosition);
                  },
                );
              },
            ),

            Container(
              color: Colors.black,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VolumeControlScreen(),
                  IconButton(
                    onPressed: () {
                      c.nextSong();
                    },
                    tooltip: "Next",
                    icon: const Icon(
                      Icons.navigate_before_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),

                  // play==============================

                  StreamBuilder<just_audio.PlayerState>(
                    stream: c.player.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final processingState = playerState?.processingState;
                      final playing = playerState?.playing;

                      if (processingState ==
                              just_audio.ProcessingState.loading ||
                          processingState ==
                              just_audio.ProcessingState.buffering) {
                        return const SizedBox(
                          width: 80.0,
                          height: 80.0,
                          child: Center(
                              child: CircularProgressIndicator(
                            color: Colors.white,
                          )),
                        );
                      } else if (playing != true) {
                        return IconButton(
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          iconSize: 64.0,
                          onPressed: c.player.play,
                        );
                      } else if (processingState !=
                          just_audio.ProcessingState.completed) {
                        return IconButton(
                          icon: const Icon(Icons.pause_circle_filled_outlined),
                          color: Colors.white,
                          iconSize: 64.0,
                          onPressed: c.player.pause,
                        );
                      } else {
                        return IconButton(
                          icon: const Icon(Icons.replay),
                          iconSize: 64.0,
                          onPressed: () => c.player.seek(Duration.zero),
                        );
                      }
                    },
                  ),

                  /// ========================= stop
                  IconButton(
                    onPressed: () async {
                      await c.player.stop();
                    },
                    icon: const Icon(
                      Icons.stop_circle_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      c.previousSong();
                    },
                    icon: const Icon(
                      Icons.navigate_next_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
