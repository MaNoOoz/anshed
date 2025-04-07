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
    final currentMediaItem = _controller.currentMediaItem.value;

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
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Header and album art
              const SizedBox(height: 6),

              // Song info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    if (currentMediaItem != null) ...[
                      Obx(() {
                        return Text(
                          _controller.title.value ?? "Unknown Artist",
                          style: bigTextStyle(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        );
                      }),
                      const SizedBox(height: 8),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 6),
              // Progress bar

              ModernSeekBar(),

              const SizedBox(height: 14),

              // Playback controls
              ControlButtons(),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    return "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}
