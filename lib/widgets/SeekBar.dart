import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/PlayerController.dart';

class ModernSeekBar extends StatelessWidget {
  const ModernSeekBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AudioPlayerController c = Get.find();
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white70,
      fontSize: 12,
      fontFeatures: [const FontFeature.tabularFigures()],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          StreamBuilder<Duration>(
            stream: c.audioPlayer.positionStream,
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration?>(
                stream: c.audioPlayer.durationStream,
                builder: (context, durationSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = durationSnapshot.data ?? Duration.zero;
                  final max = duration.inMilliseconds.toDouble();
                  final value = position.inMilliseconds.toDouble();

                  // Handle zero duration case
                  if (max <= 0) {
                    return const SizedBox.shrink();
                  }

                  return StreamBuilder<Duration>(
                    stream: c.audioPlayer.bufferedPositionStream,
                    builder: (context, bufferedSnapshot) {
                      final bufferedPosition =
                          bufferedSnapshot.data ?? Duration.zero;
                      final bufferedValue =
                          bufferedPosition.inMilliseconds.toDouble();

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                                pressedElevation: 8,
                              ),
                              activeTrackColor: Colors.orange,
                              inactiveTrackColor: Colors.white30,
                              thumbColor: Colors.white,
                              overlayColor: Colors.white24,
                              activeTickMarkColor: Colors.transparent,
                              inactiveTickMarkColor: Colors.transparent,
                              trackShape: const RoundedRectSliderTrackShape(),
                            ),
                            child: Stack(
                              children: [
                                LinearProgressIndicator(
                                  value: (bufferedValue / max).clamp(0.0, 1.0),
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.transparent,
                                  ),
                                  minHeight: 4,
                                ),
                                Slider(
                                  min: 0,
                                  max: max,
                                  value: value.clamp(0, max),
                                  onChanged: (value) {
                                    c.seek(
                                      Duration(milliseconds: value.toInt()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: textStyle,
                                ),
                                Text(
                                  '-${_formatDuration(duration - position)}',
                                  style: textStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  return "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
}
