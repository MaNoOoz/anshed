import 'package:anshed/widgets/VolDialoag.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../adaptive_widgets/appbar.dart';
import '../controllers/PlayerController.dart';
import '../widgets/SeekBar.dart';
import '../widgets/music_tile.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/text_styles.dart';

const String BASE_URL_flutter =
    "https://play.google.com/store/apps/details?id=com.manoooz.anshed";
const String other_apps =
    "https://play.google.com/store/apps/dev?id=8389389659889758696";

class HomePage extends StatelessWidget {
   HomePage({Key? key}) : super(key: key);

  final PlayerController c = Get.find<PlayerController>();

  final PanelController panelController = PanelController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: Colors.black87,
        appBar: AdaptiveAppBar(
          centerTitle: true,
          title: Text(
            "أناشيد الثورة السورية",
            style: mediumTextStyle(context),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () => Get.toNamed("/Settings"),
          ),
          actions: [
            Obx(() => Row(
              children: [

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("${c.downloadedSongs.length}"),
                ),
                 Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: const Icon(
                    Icons.download_for_offline_outlined,
                    color: Colors.white,
                                   ),
                 ),


              ],
            )),
          ],
        ),
        body: Obx(
          () {
            if (c.loading && c.songs.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (c.songs.isEmpty && c.downloaded.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('تحديث'),
                    IconButton(
                      onPressed: () => c.fetchMusicUrls(),
                      icon: const Icon(
                        Icons.refresh,
                        size: 55,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              color: Colors.black,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: c.songs.length,
                      itemBuilder: (context, index) {
                        return MusicTile(
                          song: c.songs[index],
                          index: index,
                        );
                      },
                    ),
                  ),
                  playerWidget(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget imagePlaceHolder() {
    return CachedNetworkImage(
      imageUrl: c.current!.artworkUrl!,
      placeholder: (context, url) => Image.asset('assets/s.png'),
      errorWidget: (context, url, error) => Icon(Icons.error),
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
            opacity: 0.4,
            image: c.current?.artworkUrl != null &&
                    c.current!.artworkUrl!.isNotEmpty
                ? NetworkImage(c.current!.artworkUrl.toString())
                : const AssetImage('assets/s.png') as ImageProvider,
            // image: const AssetImage('assets/s.png') as ImageProvider,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(height: 50),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                c.current?.name ?? '',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                c.current?.artist ?? '',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ),

            Spacer(),

            StreamBuilder<Duration>(
              stream: c.player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = c.player.duration ?? Duration.zero;

                return StreamBuilder<Duration>(
                  stream: c.player.bufferedPositionStream,
                  builder: (context, bufferedSnapshot) {
                    final bufferedPosition =
                        bufferedSnapshot.data ?? Duration.zero;

                    return mSeekBar(
                      duration: duration,
                      bufferedPosition: bufferedPosition,
                      position: position,
                    );
                  },
                );
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: 0.5,
                child: Container(
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.navigate_before_outlined,
                          size: 44,
                          color: Colors.white,
                        ),
                        onPressed: () => c.previousSong(),
                      ),
                      StreamBuilder<bool>(
                        stream: c.player.playingStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;
                          return IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 44,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                c.player.pause();
                              } else {
                                c.player.play();
                              }
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.navigate_next_outlined,
                          size: 44,
                          color: Colors.white,
                        ),
                        onPressed: () => c.nextSong(),
                      ),
                      const VolumeControlScreen(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    });
  }
}

