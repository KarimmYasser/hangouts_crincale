import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/frequency_response.dart';

class GraphController extends GetxController {
  // A list of all frequency response curves currently loaded into the app.
  final RxList<FrequencyResponse> curves = <FrequencyResponse>[].obs;

  // The curve designated as the baseline for comparison.
  final Rx<FrequencyResponse?> baselineCurve = Rx<FrequencyResponse?>(null);

  // Normalization parameters.
  final RxDouble normDb = 0.0.obs;
  final RxDouble normHz = 500.0.obs;

  // Smoothing level (e.g., 1/N octave smoothing).
  final RxInt smoothLevel = 5.obs;

  // The visible range of the Y-axis in decibels.
  final RxDouble yAxisRange = 40.0.obs;

  // The maximum visible value of the X-axis in Hz.
  final RxDouble xAxisMaxRange = 20000.0.obs;

  // The minimum visible value of the X-axis in Hz.
  final RxDouble xAxisMinRange = 20.0.obs;

  // The color used for the grid lines on the graph.
  final Rx<Color> gridPaintColor = Rx<Color>(
    Colors.white.withAlpha(38),
  ); // Added grid paint color

  // The color used for the labels (e.g., axis labels) on the graph.
  final Rx<Color> labelTextColor = Rx<Color>(Colors.white.withAlpha(127));

  /// Sets a specific curve as the baseline.
  /// If the provided curve is already the baseline, it clears the baseline.
  void setBaseline(FrequencyResponse curve) {
    if (baselineCurve.value == curve) {
      baselineCurve.value = null;
    } else {
      baselineCurve.value = curve;
    }
    // A full redraw/recalculation would be triggered here.
    update(); // Notifies UI to rebuild.
  }

  /// Toggles the visibility of a specific curve on the graph.
  void toggleCurveVisibility(String curveId) {
    final curve = curves.firstWhereOrNull((c) => c.id == curveId);
    if (curve != null) {
      curve.isVisible.toggle();
      // Using update() is a simple way to trigger a repaint of the graph painter.
      update(['graph']); // Update only widgets with this ID.
    }
  }

  /// Updates the normalization values.
  void setNormalization(double db, double hz) {
    normDb.value = db;
    normHz.value = hz;
    // Recalculate curve positions based on new normalization.
    update(['graph']);
  }

  /// Updates the smoothing factor.
  void setSmoothing(int level) {
    smoothLevel.value = level;
    // Trigger recalculation of smoothed data.
    update(['graph']);
  }

  /// Adds a new curve to the graph. Typically called from SelectionController.
  void addCurve(FrequencyResponse curve) {
    if (!curves.any((c) => c.id == curve.id)) {
      curves.add(curve);
    }
  }

  /// Removes a curve from the graph.
  void removeCurve(String curveId) {
    curves.removeWhere((c) => c.id == curveId);
    if (baselineCurve.value?.id == curveId) {
      baselineCurve.value = null;
    }
  }
}
