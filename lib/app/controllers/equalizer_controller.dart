import 'package:get/get.dart';

import '../data/models/eq_filter.dart';
import '../data/models/frequency_response.dart';
import '../services/equalizer_service.dart';

class EqualizerController extends GetxController {
  final EqualizerService _equalizerService = EqualizerService();

  // The model currently selected for EQ.
  final Rx<FrequencyResponse?> eqTargetModel = Rx<FrequencyResponse?>(null);

  // The list of parametric EQ filters.
  final RxList<EqFilter> filters = <EqFilter>[].obs;

  // The overall pre-amp gain to prevent clipping.
  final RxDouble preAmp = 0.0.obs;

  // AutoEQ settings
  final RxDouble autoEqFromHz = 20.0.obs;
  final RxDouble autoEqToHz = 20000.0.obs;
  final RxDouble autoEqGainFrom = (-20.0).obs;
  final RxDouble autoEqGainTo = 20.0.obs;
  final RxDouble autoEqQFrom = 0.1.obs;
  final RxDouble autoEqQTo = 3.0.obs;
  final RxBool isAutoEqRunning = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Start with one default, disabled filter.
    addFilter();
  }

  /// Adds a new filter to the list.
  void addFilter() {
    filters.add(
      EqFilter(
        type: FilterType.PK,
        freq: 1000,
        gain: 0,
        q: 1.41,
        isEnabled: false,
      ),
    );
  }

  /// Removes the last filter from the list.
  void removeFilter() {
    if (filters.isNotEmpty) {
      filters.removeLast();
    }
  }

  /// Updates a specific property of a filter.
  void updateFilter(
    int index, {
    FilterType? type,
    double? freq,
    double? gain,
    double? q,
    bool? isEnabled,
  }) {
    if (index < 0 || index >= filters.length) return;

    final currentFilter = filters[index];
    filters[index] = currentFilter.copyWith(
      type: type,
      freq: freq,
      gain: gain,
      q: q,
      isEnabled: isEnabled,
    );
  }

  /// Sorts filters by frequency.
  void sortFilters() {
    filters.sort((a, b) => a.freq.compareTo(b.freq));
    filters.refresh();
  }

  /// Enables or disables all filters at once.
  void toggleAllFilters(bool enable) {
    for (int i = 0; i < filters.length; i++) {
      updateFilter(i, isEnabled: enable);
    }
  }

  /// Starts the AutoEQ process.
  Future<void> runAutoEq() async {
    if (eqTargetModel.value == null) {
      Get.snackbar('Error', 'Please select a model to EQ first.');
      return;
    }
    isAutoEqRunning.value = true;

    try {
      // Create a current frequency response as a List<DataPoint>
      final List<DataPoint> currentFrData =
          EqualizerService.graphicEqRawFrequencies
              .map(
                (freq) => DataPoint(frequency: freq, db: 0.0),
              ) // Use 'db' for the value
              .toList(); // A flat response for simulation

      final List<DataPoint> targetFrData = eqTargetModel.value!.data;

      // Interpolate the target frequency response to match the raw frequencies
      final List<DataPoint> interpolatedTargetFrData = _equalizerService.interp(
        EqualizerService.graphicEqRawFrequencies,
        targetFrData,
      );

      // Run the AutoEQ algorithm
      List<EqFilter> newFilters = _equalizerService.autoEq(
        currentFrData,
        interpolatedTargetFrData,
        // You can make maxFilters configurable, e.g., from a UI setting
        10, // Max filters to generate
      );

      // Update the filters in the controller
      filters.clear();
      filters.addAll(
        newFilters.map((f) => f.copyWith(isEnabled: true)),
      ); // Enable new filters by default

      // Calculate and apply preamp
      List<DataPoint> appliedFr = _equalizerService.applyFilters(
        currentFrData,
        filters.toList(),
      );
      preAmp.value = _equalizerService.calcPreamp(currentFrData, appliedFr);
    } catch (e) {
      Get.snackbar('Error', 'AutoEQ failed: $e');
      print('AutoEQ error: $e'); // For debugging
    } finally {
      isAutoEqRunning.value = false;
    }
  }
}
