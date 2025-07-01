import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Represents a single data point in a frequency response graph.
class DataPoint {
  final double frequency;
  final double db;

  DataPoint({required this.frequency, required this.db});
}

/// Represents a full frequency response curve for a specific model.
class FrequencyResponse {
  final String id;
  final String name;
  final String brandID;
  final List<DataPoint> data;

  // UI-specific properties managed by GetX for reactivity.
  final RxBool isVisible = true.obs;

  // A property to hold the color for this curve's line on the graph.
  final Color color;

  FrequencyResponse({
    required this.id,
    required this.name,
    required this.brandID,
    required this.data,
    required this.color,
  });

  // Equality check to prevent adding duplicate curves to the list.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrequencyResponse &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
