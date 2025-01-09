import 'package:anshed/widgets/VolDialoag.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:logger/logger.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../controllers/PlayerController.dart';
import '../widgets/SeekBar.dart';
import '../widgets/music_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PlayerController c = Get.find<PlayerController>();
  final PanelController panelController = PanelController();

  // Widget bg() {
  //   return BottomSheetScaffold(
  //     draggableBody: true,
  //     dismissOnClick: true,
  //     barrierColor: Colors.black54,
  //     bottomSheet: DraggableBottomSheet(
  //       animationDuration: Duration(milliseconds: 200),
  //       body: BottomSheetBody(),
  //       header: BottomSheetHeader(), //header is not required
  //     ),
  //     appBar: AppBar(
  //       title: Text(widget.title),
  //     ),
  //     body: ScaffoldBody(),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black12,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          title: const Text("أناشيد الثورة السورية"),
          actions: [
            Obx(() => Text("${c.songList.length}")),
            PopupMenuButton<String>(
              onSelected: (String result) {
                switch (result) {
                  case 'Refresh':
                    // c.fetchMusicUrls();
                    break;
                  case 'Download':
                    // c.showDownloadDialog();
                    break;
                  case 'Share':
                    // final appLink = 'https://example.com'; // todo
                    // Share.share('Check out this app: $appLink');
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Refresh',
                  child: Text('تحديث الأغاني'),
                ),
                const PopupMenuItem<String>(
                  value: 'Download',
                  child: Text('تحميل الأغاني'),
                ),
                const PopupMenuItem<String>(
                  value: 'Share',
                  child: Text('مشاركة التطبيق'),
                ),
              ],
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
        body: Obx(
          () {
            var listToShow =
                c.songList.isNotEmpty ? c.songList : c.downloadedSongs.toList();
            Logger().e('listToShow ${listToShow.length}');
            Logger().e('songList ${c.songList.length}');
            if (listToShow.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('تحديث'),
                    IconButton(
                        onPressed: () => c.fetchMusicUrls(),
                        icon: Icon(Icons.refresh,size: 55,)),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: listToShow.length,
                    itemBuilder: (context, index) {
                      return MusicTile(
                        song: listToShow[index],
                        index: index,
                      );
                    },
                  ),
                ),
                playerWidget()
              ],
            );

            // if (c.songList.isNotEmpty) {
            //   return ListView.builder(
            //     itemCount: c.songList.length,
            //     itemBuilder: (context, index) {
            //       return MusicTile(
            //         song: c.songList[index],
            //         index: index,
            //       );
            //     },
            //   );
            // } else {
            //   return ListView.builder(
            //     itemCount: c.downloadedSongs.length,
            //     itemBuilder: (context, index) {
            //       return MusicTile(
            //         song: c.songList[index],
            //         index: index,
            //       );
            //     },
            //   );
            // }
          },
        ),
      ),
    );
  }

  Widget playerWidget() {
    return Obx(() {
      return Container(
        height: 300,
        width: double.infinity,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  c.currentSong.value?.name ?? '',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
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
