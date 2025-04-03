import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/PlayerController.dart';

class VolumeSlider extends StatelessWidget {
  const VolumeSlider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AudioPlayerController controller = Get.find();

    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => Slider(
                activeColor: Color.fromRGBO(0, 77, 31, 1),
                value: controller.volume,
                onChanged: controller.setVolume,
                min: 0,
                max: 1,
              )),
          Obx(() => Text(
              'مستوى الصوت: ${(controller.volume * 100).toStringAsFixed(0)}%')),
        ],
      ),
    );
  }
}

void showVolumeDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('ضبط مستوى الصوت'),
        content: const VolumeSlider(),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إغلاق'),
          ),
        ],
      );
    },
  );
}

class VolumeControlScreen extends StatelessWidget {
  const VolumeControlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(
        Icons.volume_up_rounded,
        size: 22,
        color: Colors.white,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const VolumeSlider(),
          enabled: false,
        ),
      ],
    );
  }
}
