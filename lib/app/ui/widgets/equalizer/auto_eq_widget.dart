import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/equalizer_controller.dart';

class AutoEqWidget extends StatelessWidget {
  const AutoEqWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final EqualizerController controller = Get.find();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("AutoEQ", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          // TODO: Add input fields for frequency, gain, and Q ranges if needed.
          Obx(() {
            if (controller.isAutoEqRunning.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text("Calculating EQ..."),
                    ],
                  ),
                ),
              );
            }
            return ElevatedButton.icon(
              onPressed:
                  controller.eqTargetModel.value == null
                      ? null // Disable if no model is selected
                      : controller.runAutoEq,
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Generate EQ for Selected Model"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            );
          }),
          Obx(
            () =>
                controller.eqTargetModel.value == null
                    ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Select a model from the dropdown above to enable AutoEQ.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
