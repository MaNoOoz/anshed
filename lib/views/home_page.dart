import 'package:anshed/views/settings_page.dart';
import 'package:anshed/widgets/VolDialoag.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../adaptive_widgets/appbar.dart';
import '../controllers/AdController.dart';
import '../controllers/PlayerController.dart';
import '../widgets/SeekBar.dart';
import '../widgets/music_tile.dart';
import '../widgets/text_styles.dart';

const String BASE_URL_flutter =
    "https://play.google.com/store/apps/details?id=com.manoooz.anshed";
const String other_apps =
    "https://play.google.com/store/apps/dev?id=8389389659889758696";

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final AdController adController = Get.put(AdController());

  final PlayerController c = Get.find<PlayerController>();
  final PanelController panelController = PanelController();
  final TextEditingController searchController =
      TextEditingController(); // Controller for search bar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          adController.showInterstitialAd();
        },
        child: Icon(Icons.ad_units),
      ),
      // backgroundColor: Colors.black87,
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
          onPressed: () => Get.to(SettingsScreen()),
        ),
        // actions: [
        //   Obx(() => Row(
        //         children: [
        //           Padding(
        //             padding: const EdgeInsets.all(8.0),
        //             child: Text("${c.downloadedSongs.length}"),
        //           ),
        //           Padding(
        //             padding: const EdgeInsets.all(8.0),
        //             child: const Icon(
        //               Icons.download_for_offline_outlined,
        //               color: Colors.white,
        //             ),
        //           ),
        //         ],
        //       )),
        // ],
      ),
      body: Obx(() {
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
          // color: Colors.black,
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CupertinoSearchTextField(
                  controller: searchController,
                  placeholder: 'ابحث عن أنشودة...',
                  style: textStyle(context),
                  onChanged: (query) {
                    c.filterSongs(query); // Filter songs based on search query
                  },
                ),
              ),
              Obx(() {
                var allSongs = [
                  ...c.filteredSongs,
                  ...c.songList,
                  ...c.downloadedSongs
                ];
                // Remove duplicates by converting to Set and then back to List
                var uniqueSongs =
                    allSongs.toSet().toList(); // Removing duplicates
                return Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: uniqueSongs.length,
                    // Use filteredSongs instead of songs
                    itemBuilder: (context, index) {
                      // Get the song from the uniqueSongs list
                      var song = uniqueSongs[index];
                      // Find the original index in the combined list
                      var originalIndex = allSongs.indexOf(song);

                      return MusicTile(
                        song: song,
                        index: originalIndex,
                      );
                    },
                  ),
                );
              }),
              Obx(() => adController.isBannerAdLoaded.value
                  ? SizedBox(
                height: adController.bannerAd.size.height.toDouble(),
                width: adController.bannerAd.size.width.toDouble(),
                child: AdWidget(ad: adController.bannerAd),
              )
                  : SizedBox()),
              playerWidget(context),
            ],
          ),
        );
      }),
    );
  }
  Widget imagePlaceHolder() {
    return CachedNetworkImage(
      imageUrl: c.current!.artworkUrl!,
      placeholder: (context, url) => Image.asset('assets/s.png'),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  Widget playerWidget(context) {
    return Obx(() {
      return Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          // color: Colors.black,
          // backgroundBlendMode: BlendMode.darken,
          image: DecorationImage(
            opacity: 0.5,
            image: c.current?.artworkUrl != null &&
                    c.current!.artworkUrl!.isNotEmpty
                ? NetworkImage(c.current!.artworkUrl.toString())
                : const AssetImage('assets/s.png') as ImageProvider,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(height: 20),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(c.current?.name ?? '',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: mediumTextStyle(context)),
            ),
            // SubTitle

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                c.current?.artist ?? '',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: smallTextStyle(context),
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
