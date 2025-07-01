import 'package:flutter/material.dart';
import 'normalization_widget.dart';
import 'smoothing_widget.dart';
import 'y_scale_widget.dart';
import 'zoom_widget.dart';

class ToolsSectionWidget extends StatelessWidget {
  const ToolsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Wrap allows widgets to flow to the next line on smaller screens
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  YScaleWidget(),
                  SizedBox(width: 30.0),
                  ZoomWidget(),
                  SizedBox(width: 30.0),
                  NormalizationWidget(),
                  SizedBox(width: 30.0),
                  SmoothingWidget(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // const Divider(),
            // const SizedBox(height: 8),
            // Wrap(
            //   spacing: 8.0,
            //   children: [
            //     ElevatedButton.icon(
            //       onPressed: () {}, // TODO: Implement
            //       icon: const Icon(Icons.screenshot, size: 18),
            //       label: const Text("Screenshot"),
            //     ),
            //     ElevatedButton.icon(
            //       onPressed: () {}, // TODO: Implement
            //       icon: const Icon(Icons.color_lens_outlined, size: 18),
            //       label: const Text("Recolor"),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}
