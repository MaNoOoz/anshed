import 'package:anshed/widgets/text_styles.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../controllers/PlayerController.dart';
import '../models/song.dart';

class MusicTile extends StatelessWidget {
  final Song song;
  final int index;

  MusicTile({
    Key? key,
    required this.song,
    required this.index,
  }) : super(key: key);

  final PlayerController c = Get.find<PlayerController>();

  Widget imagePlaceHolder() {
    return CachedNetworkImage(
      imageUrl: song.artworkUrl!,
      placeholder: (context, url) => Image.asset('assets/s.png'),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isCurrentSong = c.currentSong.value?.url == song.url;
      final isPlaying = isCurrentSong && c.player.playing;
      final isDownloaded = c.downloadedSongs
          .any((s) => s.url == song.url && s.name == song.name);

      return Container(
        color: isPlaying ? Color.fromRGBO(1, 72, 31, 1) : Colors.black,
        child: ListTile(
          leading: Container(
            height: 50,
            width: 50,
            // decoration: BoxDecoration(
            //   borderRadius: BorderRadius.circular(8),
            //   image: DecorationImage(
            //     image: song.artworkUrl != null && song.artworkUrl!.isNotEmpty
            //         ? NetworkImage(song.artworkUrl.toString()??"")
            //         : const AssetImage('assets/s.png') as ImageProvider,
            //     fit: BoxFit.contain,
            //   ),
            // ),

            child: song.artworkUrl != null && song.artworkUrl!.isNotEmpty
                ? imagePlaceHolder()
                : Image.asset('assets/s.png'),
          ),
          title: Text(
            song.name,
            overflow: TextOverflow.ellipsis,
            style: mediumTextStyle(context, bold: isPlaying ? true : false),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDownloaded)
                const Icon(
                  Icons.download_done,
                  color: Colors.green,
                ),
              if (!isDownloaded)
                IconButton(
                  icon: const Icon(
                    Icons.download_for_offline,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Logger()
                        .i('downloadSong song at index $index $isDownloaded');
                    c.downloadSong(index);
                  },
                ),
            ],
          ),
          onTap: () {
            // c.deleteSong(index);

            if (isCurrentSong) {
              c.togglePlayPause();
            } else {
              c.playSong(index);
            }
          },
        ),
      );
    });
  }
}
