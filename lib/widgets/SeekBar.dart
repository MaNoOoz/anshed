import 'dart:math';

import 'package:flutter/material.dart';

import 'dart:math';

import 'package:flutter/material.dart';

class mSeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const mSeekBar({
    super.key,
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _mSeekBarState createState() => _mSeekBarState();
}

class _mSeekBarState extends State<mSeekBar> {
  double? _dragValue;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.0,
            trackShape: const RoundedRectSliderTrackShape(),
            activeTrackColor: Colors.green.shade800,
            inactiveTrackColor: Colors.green.shade100,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10.0,
              pressedElevation: 8.0,
            ),
            thumbColor: Colors.green,
            overlayColor: Colors.green.withOpacity(0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            tickMarkShape: const RoundSliderTickMarkShape(),
            activeTickMarkColor: Colors.green,
            inactiveTickMarkColor: Colors.white,
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
            valueIndicatorColor: Colors.black,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20.0,
            ),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _positionText,
                  style: const TextStyle(color: Colors.white),
                ),
                const Text(
                  "",
                  style: TextStyle(color: Colors.white),
                ),
                Expanded(
                  child: Slider(
                    min: 0.0,
                    max: widget.duration.inMilliseconds.toDouble(),
                    value: min(
                        _dragValue ?? widget.position.inMilliseconds.toDouble(),
                        widget.duration.inMilliseconds.toDouble()),
                    onChanged: (value) {
                      setState(() {
                        _dragValue = value;
                      });
                      if (widget.onChanged != null && _dragging) {
                        widget
                            .onChanged!(Duration(milliseconds: value.round()));
                      }
                    },
                    onChangeStart: (value) {
                      setState(() {
                        _dragging = true;
                      });
                    },
                    onChangeEnd: (value) {
                      setState(() {
                        _dragging = false;
                        _dragValue = null;
                      });
                      if (widget.onChangeEnd != null) {
                        widget.onChangeEnd!(
                            Duration(milliseconds: value.round()));
                      }
                    },
                  ),
                ),
                Text(
                  _durationText,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _durationText =>
      "${widget.duration.inMinutes.remainder(60).toString().padLeft(2, '0')}"
      ":${widget.duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  String get _positionText =>
      "${widget.position.inMinutes.remainder(60).toString().padLeft(2, '0')}"
      ":${widget.position.inSeconds.remainder(60).toString().padLeft(2, '0')}";
}