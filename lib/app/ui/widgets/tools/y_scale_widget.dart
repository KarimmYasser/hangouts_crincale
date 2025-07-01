import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/tools_controller.dart';

class YScaleWidget extends StatelessWidget {
  const YScaleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ToolsController controller = Get.find();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Y-axis Scale",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Obx(
          () => OutlinedButton(
            onPressed: controller.changeYScale,
            child: Text("${controller.selectedYScale.value.toInt()} dB"),
          ),
        ),
      ],
    );
  }
}
