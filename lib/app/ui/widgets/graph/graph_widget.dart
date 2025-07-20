import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/graph_controller.dart';
import '../../../controllers/tools_controller.dart';
import 'graph_painter.dart';

class GraphWidget extends StatelessWidget {
  const GraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final GraphController graphCtrl = Get.find();
    final ToolsController toolsCtrl = Get.find();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.35,
        color: const Color(0xFFFFF8EB),
        child: GetBuilder<GraphController>(
          builder:
              (controller) => CustomPaint(
                size: Size.infinite,
                painter: GraphPainter(
                  graphController: graphCtrl,
                  toolsController: toolsCtrl,
                ),
              ),
        ),
      ),
    );
  }
}
