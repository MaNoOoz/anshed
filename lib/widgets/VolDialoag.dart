import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/PlayerController.dart';

class VolumeSlider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final PlayerController controller = Get.find();

    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => Slider(
                value: controller.volume.value,
                onChanged: (newVolume) {
                  controller.setVolume(newVolume);
                },
                min: 0,
                max: 1,
              )),
          Obx(() => Text(
              'Volume: ${(controller.volume.value * 100).toStringAsFixed(0)}%')),
        ],
      ),
    );
  }
}

void showVolumeDialog(BuildContext context) {
  final PlayerController controller = Get.find();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Adjust Volume'),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: controller.volume.value,
                  onChanged: (newVolume) {
                    controller.setVolume(newVolume);
                  },
                  min: 0,
                  max: 1,
                ),
                Text(
                    'Volume: ${(controller.volume.value * 100).toStringAsFixed(0)}%'),
              ],
            )),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}

class VolumeControlScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: PopupMenuButton(
        icon: Icon(
          Icons.volume_up_rounded,
          size: 40,
          color: Colors.white,
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            child: VolumeSlider(), // Use the VolumeSlider widget
            enabled: false, // Disable the item to prevent selection
          ),
        ],
      ),
    );
  }
}
