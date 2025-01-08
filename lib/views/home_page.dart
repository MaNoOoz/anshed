import 'package:anshed/widgets/VolDialoag.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../controllers/PlayerController.dart';
import '../widgets/SeekBar.dart';
import '../widgets/music_tile.dart';

class HomePage extends StatelessWidget {
  final PlayerController c = Get.put(PlayerController());

  Widget _buildMiniPlayer(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: ListTile(
        leading: const Icon(Icons.music_note),
        title: Obx(() {
          final currentSongName = c.currentIndex.value != -1
              ? c.songList[c.currentIndex.value].name
              : 'No song playing';
          return Text(
            currentSongName,
            overflow: TextOverflow.ellipsis,
          );
        }),
        trailing: Obx(() {
          final isPlaying = c.isPlaying.value;
          return IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              isPlaying ? c.pause() : c.player.play();
            },
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = c.isPlaying.value;
    final currentIndex = c.currentIndex.value;
    final currentSongName =
    currentIndex != -1 ? c.songList[currentIndex].name : 'No song playing';

    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.black12,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            title: Text("أناشيد الثورة السورية"),
            actions: [
              Text("${c.songList.length}"),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  Logger().e("${c.songList.length}");

                  c.update();
                  await c.fetchMusicUrls();
                },
                tooltip: 'Refresh Songs',
              ),
              IconButton(
                onPressed: () {
                  c.showDownloadDialog();
                },
                icon: Icon(Icons.download_for_offline),
              ),
            ],
          ),
          body: Obx(() {
            if (c.songList.isEmpty) {
              return Center(child: Text('No songs available'));
            }
            if (c.initialized) {
              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: c.songList.length,
                          itemBuilder: (context, index) {
                            return MusicTile(
                              song: c.songList[index],
                              index: index,
                            );
                          },
                        ),
                      ),
                      // Sliding panel
                      Obx(() {
                        return SlidingUpPanel(
                          controller: PanelController(),
                          // color: Colors.black26,
                          color: Colors.transparent,
                          minHeight: 300,
                          maxHeight: 300,
                          panel: playerWidget(
                              isPlaying: isPlaying,
                              currentIndex: currentIndex,
                              currentSongName: currentSongName),
                          // collapsed: _buildMiniPlayer(context),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              );
            }
            return Center(child: Text('No songs available'));
          })),
    );
  }

  Widget playerWidget({required bool isPlaying,
    required int currentIndex,
    required String currentSongName}) {
    return Obx(() {
      return Container(
        height: 100,
        color: Colors.green.withAlpha(22),
        child: Column(
          children: [
            SizedBox(
              height: 12,
            ),
// Title
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    c.currentSongName.value,
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
              color: Colors.green.shade700,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VolumeControlScreen(),

                  IconButton(
                    onPressed: () async {
                      print("${c.player.processingState}");
                      c.nextSong();
                      await c.player.seek(Duration.zero, index: 0);
                    },
                    tooltip: "Next",
                    icon: const Icon(
                      Icons.navigate_before_rounded,
                      color: Colors.black,
                      size: 40,
                      // color: Colors.black87
                    ),
                  ),

                  // play==============================

                  StreamBuilder<PlayerState>(
                    stream: c.player.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final processingState = playerState?.processingState;
                      final playing = playerState?.playing;
                      final loading = ProcessingState.loading;
                      final buffering = ProcessingState.buffering;

                      if (processingState == loading ||
                          processingState == buffering) {
                        return SizedBox(
                          // color: Colors.red,
                          width: 80.0,
                          height: 80.0,
                          child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              )),
                        );
                      } else if (playing != true) {
                        return IconButton(
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.black,
                          ),
                          iconSize: 64.0,
                          onPressed: c.player.play,
                        );
                      } else if (processingState != ProcessingState.completed) {
                        return IconButton(
                          icon: const Icon(Icons.pause_circle_filled_outlined),
                          color: isPlaying ? Colors.black : Colors.black,
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
                      print("${c.player.processingState}");

                      await c.player.stop();
                      await c.player.seek(Duration.zero, index: 0);
                    },
                    icon: const Icon(
                      Icons.stop_circle_rounded,
                      color: Colors.black,
                      size: 40,
                      // color: Colors.black87
                    ),
                  ),

                  IconButton(
                    onPressed: () async {
                      print("${c.player.processingState}");

                      c.previousSong();
                      await c.player.seek(Duration.zero, index: 0);
                    },
                    icon: const Icon(
                      Icons.navigate_next_outlined,
                      color: Colors.black,
                      size: 40,
                      // color: Colors.black87
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
