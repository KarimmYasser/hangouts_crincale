import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/graph_controller.dart';

class SmoothingWidget extends StatelessWidget {
  const SmoothingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final GraphController controller = Get.find();
    final smoothingLevels = [1, 3, 5, 8, 12, 24]; // e.g., 1/N smoothing

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Smoothing", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Obx(
          () => DropdownButton<int>(
            value: controller.smoothLevel.value,
            items:
                smoothingLevels.map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('1/$value octave'),
                    ),
                  );
                }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                controller.setSmoothing(newValue);
              }
            },
          ),
        ),
      ],
    );
  }
}
