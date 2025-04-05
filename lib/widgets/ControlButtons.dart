import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

import '../controllers/PlayerController.dart';
import 'VolDialoag.dart';

class ControlButtons extends StatelessWidget {
  final AudioPlayerController c = Get.find<AudioPlayerController>();

  ControlButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final player = c.audioPlayer; // <- access the player from controller
    return Container(
      color: Colors.black,
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        textDirection: TextDirection.rtl,
        children: [
          StreamBuilder<LoopMode>(
            stream: player.loopModeStream,
            builder: (context, snapshot) {
              final loopMode = snapshot.data ?? LoopMode.off;
              const icons = [
                Icon(Icons.repeat, color: Colors.grey),
                Icon(Icons.repeat, color: Colors.orange),
                Icon(Icons.repeat_one, color: Colors.orange),
              ];
              const cycleModes = [
                LoopMode.off,
                LoopMode.all,
                LoopMode.one,
              ];
              final index = cycleModes.indexOf(loopMode);
              return IconButton(
                icon: icons[index],
                onPressed: () {
                  player.setLoopMode(cycleModes[
                      (cycleModes.indexOf(loopMode) + 1) % cycleModes.length]);
                },
              );
            },
          ),
          StreamBuilder<bool>(
            stream: player.shuffleModeEnabledStream,
            builder: (context, snapshot) {
              final shuffleModeEnabled = snapshot.data ?? false;
              return IconButton(
                icon: shuffleModeEnabled
                    ? const Icon(
                        Icons.shuffle,
                        color: Colors.orange,
                      )
                    : const Icon(
                        Icons.shuffle,
                        color: Colors.grey,
                      ),
                onPressed: () {
                  player.setShuffleModeEnabled(!shuffleModeEnabled);
                },
              );
            },
          ),
          StreamBuilder<SequenceState?>(
            stream: player.sequenceStateStream,
            builder: (context, snapshot) => IconButton(
                splashColor: Colors.white,
                iconSize: 44.0,
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                ),
              onPressed: () async {
                Logger().d(
                    "player.hasPrevious: ${player.hasPrevious}, controller.hasPrevious: ${c.hasPrevious}");
                player.hasPrevious
                    ? await player.seekToPrevious()
                    : player.seek(Duration.zero, index: 0);
                c.update();
              },
            ),
          ),
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;
              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering) {
                return Container(
                  margin: const EdgeInsets.all(8.0),
                  width: 64.0,
                  height: 64.0,
                  child: const CircularProgressIndicator(),
                );
              } else if (playing != true) {
                return IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  iconSize: 64.0,
                  onPressed: player.play,
                );
              } else if (processingState != ProcessingState.completed) {
                return IconButton(
                  icon: const Icon(Icons.pause_circle_filled_rounded),
                  iconSize: 64.0,
                  onPressed: player.pause,
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.replay),
                  iconSize: 64.0,
                  onPressed: () => player.seek(Duration.zero,
                      index: player.effectiveIndices!.first),
                );
              }
            },
          ),
          StreamBuilder<SequenceState?>(
            stream: player.sequenceStateStream,
            builder: (context, snapshot) => IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 44.0,
                splashColor: Colors.white,
                color: Colors.white,
                onPressed: () async {
                  Logger().d("player.hasNext : ${player.hasNext}");
                  player.hasNext
                      ? await player.seekToNext()
                      : player.seek(Duration.zero, index: 0);
                  c.update();
                }),
          ),
          VolumeControlScreen()

          // const VolumeControlScreen(),
        ],
      ),
    );
  }
}
