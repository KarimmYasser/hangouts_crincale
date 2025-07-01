import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/audio_player_controller.dart';

class EqDemoWidget extends StatelessWidget {
  const EqDemoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AudioPlayerController controller = Get.find();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("EQ Demo", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Obx(
            () => DropdownButtonFormField<EqTrack>(
              value: controller.selectedTrack.value,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items:
                  EqTrack.values
                      .map(
                        (track) => DropdownMenuItem(
                          value: track,
                          child: Text(track.toString().split('.').last),
                        ),
                      )
                      .toList(),
              onChanged: (track) {
                if (track != null) controller.loadTrack(track);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Play/Pause Button
              Obx(
                () => IconButton(
                  icon: Icon(
                    controller.isPlaying.value
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  iconSize: 48,
                  onPressed:
                      controller.isPlaying.value
                          ? controller.pause
                          : controller.play,
                ),
              ),
              // Time Display and Slider
              Expanded(
                child: Column(
                  children: [
                    Obx(
                      () => Slider(
                        value:
                            controller.currentPosition.value.inSeconds
                                .toDouble(),
                        max: controller.totalDuration.value.inSeconds
                            .toDouble()
                            .clamp(0.1, double.infinity),
                        onChanged:
                            (val) =>
                                controller.seek(Duration(seconds: val.toInt())),
                      ),
                    ),
                    Obx(
                      () => Text(
                        "${controller.currentPosition.value.toString().split('.').first} / ${controller.totalDuration.value.toString().split('.').first}",
                      ),
                    ),
                  ],
                ),
              ),
              // Volume Control
              IconButton(onPressed: () {}, icon: const Icon(Icons.volume_up)),
            ],
          ),
        ],
      ),
    );
  }
}
