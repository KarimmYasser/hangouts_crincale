import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/preference_controller.dart';

class PreferenceAdjustmentsWidget extends StatelessWidget {
  const PreferenceAdjustmentsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final PreferenceController controller = Get.find();
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Preference Adjustments",
                  style: theme.textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: controller.resetAdjustments,
                  child: const Text("Reset"),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _PreferenceSlider(
              label: "Tilt",
              unit: "dB/oct",
              value: controller.tilt, // Pass the RxDouble directly
              min: -2.0,
              max: 2.0,
              divisions: 40,
              onChanged: (val) => controller.tilt.value = val,
            ),
            const SizedBox(height: 16),
            _PreferenceSlider(
              label: "Bass Shelf",
              unit: "dB",
              value: controller.bassShelf,
              min: -10.0,
              max: 10.0,
              divisions: 40,
              onChanged: (val) => controller.bassShelf.value = val,
            ),
            const SizedBox(height: 16),
            _PreferenceSlider(
              label: "Treble Shelf",
              unit: "dB",
              value: controller.trebleShelf,
              min: -10.0,
              max: 10.0,
              divisions: 40,
              onChanged: (val) => controller.trebleShelf.value = val,
            ),
          ],
        ),
      ),
    );
  }
}

/// A reusable custom slider widget for preference adjustments.
class _PreferenceSlider extends StatelessWidget {
  final String label;
  final String unit;
  final RxDouble value; // Expects an RxDouble for reactive updates
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _PreferenceSlider({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Use Obx to rebuild only this Text widget when the value changes
        Obx(
          () => Text(
            '$label: ${value.value.toStringAsFixed(1)} $unit',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        // Use Obx for the slider as well to reflect external changes
        Obx(
          () => Slider(
            value: value.value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
