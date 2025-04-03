import 'package:anshed/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/PlayerController.dart';
import 'ControlButtons.dart';
import 'SeekBar.dart';

class PlayerModal extends StatelessWidget {
  final AudioPlayerController _controller = Get.find();

  PlayerModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AudioPlayerController>(
      builder: (controller) {
        final currentMediaItem = _controller.currentMediaItem.value;
        if (currentMediaItem == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            SizedBox(
              // height: 100,
              width: double.infinity,
              child: Image.asset(
                'assets/s.png',
                scale: 1,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/s.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.7), BlendMode.darken),
                ),
              ), // Box decoration takes a gradient,
              // color: Colors.black.withOpacity(0.7),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header and album art
                    const SizedBox(height: 6),
                    GetBuilder<AudioPlayerController>(
                      builder: (c) {
                        // Song info
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              // Text(_controller.playlist[_controller.currentIndex.value].title,
                              Text(
                                currentMediaItem.title ?? "Unknown Artist",
                                style: bigTextStyle(context),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentMediaItem.artist ?? "Unknown Artist",
                                style: textStyle(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 6),
                    // Progress bar

                    ModernSeekBar(),

                    const SizedBox(height: 14),

                    // Playback controls
                    ControlButtons(_controller.audioPlayer),

                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    return "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}
