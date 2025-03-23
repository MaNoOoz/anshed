import 'package:anshed/controllers/AdController.dart';
import 'package:anshed/views/settings_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

import '../adaptive_widgets/appbar.dart';
import '../controllers/PlayerController.dart';
import '../widgets/ControlButtons.dart';
import '../widgets/SeekBar.dart';
import '../widgets/music_tile.dart';
import '../widgets/text_styles.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final PlayerController c = Get.find<PlayerController>();
  final adController = Get.find<AdController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: Obx(() {
        if (c.isLoading && c.songs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (c.songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('تحديث'),
                IconButton(
                  // onPressed: () => c.fetchMusicUrls(),
                  icon: const Icon(
                    Icons.refresh,
                    size: 55,
                  ),
                  onPressed: () async {
                    Logger().e("Pressed ${c.currentSong?.name}");
                    Get.delete<
                        PlayerController>(); // Delete the existing instance
                    Get.put(PlayerController());
                    // Recreate the instance (calls onInit())
                  },
                ),
              ],
            ),
          );
        }

        // Update UI when current song changes
        final currentSong = c.currentSong;
        final currentIndex = c.currentIndex;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: c.songs.length,
                itemBuilder: (context, index) {
                  final song = c.songs[index];
                  final isCurrent = index == currentIndex;

                  return MusicTile(
                    song: song,
                    index: index,
                    onTap: () {
                      c.playSong(index);
                      adController.showInterstitialAd();
                    },
                  );
                },
              ),
            ),
            Obx(() => adController.isBannerAdLoaded.value
                ? SizedBox(
                    height: adController.bannerAd.size.height.toDouble(),
                    width: adController.bannerAd.size.width.toDouble(),
                    child: AdWidget(ad: adController.bannerAd),
                  )
                : SizedBox()),
            _buildPlayerWidget(context),
          ],
        );
      }),
    );
  }

  Widget _buildPlayerWidget(BuildContext context) {
    return Obx(() {
      if (c.currentSong == null) return const SizedBox.shrink();
      // Logger().d("${c.currentSong?.name}");

      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            opacity: 0.5,
            image: _getArtworkImageProvider(),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(height: 20),
            _buildSongInfo(context),
            const Spacer(),
            const ModernSeekBar(),
            ControlButtons(c.player),
            const SizedBox(height: 10),
          ],
        ),
      );
    });
  }

  ImageProvider _getArtworkImageProvider() {
    return c.currentSong?.artworkUrl != null &&
            c.currentSong!.artworkUrl!.isNotEmpty
        ? CachedNetworkImageProvider(c.currentSong!.artworkUrl!)
        : const AssetImage('assets/s.png');
  }

  Widget _buildSongInfo(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            c.currentSong?.name ?? '',
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: mediumTextStyle(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            c.currentSong?.artist ?? '',
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: smallTextStyle(context),
          ),
        ),
      ],
    );
  }
}
