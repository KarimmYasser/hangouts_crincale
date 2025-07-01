import 'package:get/get.dart';

import 'graph_controller.dart';

// Enum to represent different zoom states for the graph's X-axis.
enum ZoomLevel { none, bass, mids, treble }

class ToolsController extends GetxController {
  final GraphController _graphController = Get.find();

  // The current zoom level of the graph.
  final Rx<ZoomLevel> currentZoom = ZoomLevel.none.obs;

  // State for whether the tools panel is expanded or collapsed.
  final RxBool isToolsPanelCollapsed = false.obs;

  // The available scales for the Y-axis.
  final List<double> availableYScales = [50, 40, 30, 20];
  final RxDouble selectedYScale = 40.0.obs;

  /// Sets the zoom level of the graph.
  void setZoom(ZoomLevel level) {
    if (level == currentZoom.value) {
      currentZoom.value = ZoomLevel.none;
      _graphController.xAxisMinRange.value = 20;
      _graphController.xAxisMaxRange.value = 20000;
      return;
    }
    currentZoom.value = level;
    switch (level) {
      case ZoomLevel.bass:
        _graphController.xAxisMinRange.value = 20;
        _graphController.xAxisMaxRange.value = 400;
        break;
      case ZoomLevel.mids:
        _graphController.xAxisMinRange.value = 100;
        _graphController.xAxisMaxRange.value = 4000;
        break;
      case ZoomLevel.treble:
        _graphController.xAxisMinRange.value = 1000;
        _graphController.xAxisMaxRange.value = 20000;
        break;
      default:
        _graphController.xAxisMinRange.value = 20;
        _graphController.xAxisMaxRange.value = 20000;
    }
  }

  /// Toggles the expanded/collapsed state of the tools panel.
  void toggleToolsPanel() {
    isToolsPanelCollapsed.toggle();
  }

  /// Cycles through the available Y-axis scales.
  void changeYScale() {
    final currentIndex = availableYScales.indexOf(selectedYScale.value);
    final nextIndex = (currentIndex + 1) % availableYScales.length;
    selectedYScale.value = availableYScales[nextIndex];

    // Update the graph controller with the new scale
    _graphController.yAxisRange.value = selectedYScale.value;
  }
}
