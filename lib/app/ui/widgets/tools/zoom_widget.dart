import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/tools_controller.dart';

class ZoomWidget extends StatelessWidget {
  const ZoomWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ToolsController controller = Get.find();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Zoom", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Obx(
          () => Wrap(
            spacing: 8.0,
            children: [
              FilterChip(
                label: const Text("Bass"),
                selected: controller.currentZoom.value == ZoomLevel.bass,
                onSelected: (selected) => controller.setZoom(ZoomLevel.bass),
                selectedColor: theme.colorScheme.primaryContainer,
              ),
              FilterChip(
                label: const Text("Mids"),
                selected: controller.currentZoom.value == ZoomLevel.mids,
                onSelected: (selected) => controller.setZoom(ZoomLevel.mids),
                selectedColor: theme.colorScheme.primaryContainer,
              ),
              FilterChip(
                label: const Text("Treble"),
                selected: controller.currentZoom.value == ZoomLevel.treble,
                onSelected: (selected) => controller.setZoom(ZoomLevel.treble),
                selectedColor: theme.colorScheme.primaryContainer,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
