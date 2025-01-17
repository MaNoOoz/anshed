import 'package:anshed/widgets/VolDialoag.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
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
  static const String BASE_URL_flutter =
      "https://play.google.com/store/apps/details?id=com.manoooz.anshed";

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
            Obx(() => Text("${c.songs.length}")),
            PopupMenuButton<String>(
              onSelected: (String result) {
                switch (result) {
                  case 'Refresh':
                    c.fetchSongs();
                    break;
                  case 'Download':
                    c.downloadAllSongs();
                    break;
                  case 'Share':
                    Share.share('Check out this app: $BASE_URL_flutter');
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
                  child: Text('تحميل جميع الأغاني'),
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
                      onPressed: () => c.fetchSongs(),
                      icon: const Icon(
                        Icons.refresh,
                        size: 55,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
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
            );
          },
        ),
      ),
    );
  }

  Widget playerWidget() {
    return Obx(() {
      final currentSong = c.currentSong;

      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          backgroundBlendMode: BlendMode.darken,
          image: DecorationImage(
            opacity: 0.6,
            image: currentSong?.artworkUrl != null &&
                    currentSong!.artworkUrl!.isNotEmpty
                ? NetworkImage(currentSong.artworkUrl!)
                : const AssetImage('assets/s.png') as ImageProvider,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),
            // Title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  currentSong?.name ?? '',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
                final bufferedPosition = c.player.bufferedPosition;

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

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.skip_previous,
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
                      onPressed: () => c.togglePlayPause(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.skip_next,
                    size: 44,
                    color: Colors.white,
                  ),
                  onPressed: () => c.nextSong(),
                ),
                const VolumeControlScreen(),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }
}
