import 'package:get/get.dart';

class PreferenceController extends GetxController {
  // Tilt in dB per octave.
  final RxDouble tilt = 0.0.obs;

  // Bass shelf gain in dB.
  final RxDouble bassShelf = 0.0.obs;

  // Treble adjustment in dB.
  final RxDouble trebleShelf = 0.0.obs;

  // Ear gain adjustment in dB.
  final RxDouble earGain = 0.0.obs;

  /// Resets all preference adjustments back to their default values (0).
  void resetAdjustments() {
    tilt.value = 0.0;
    bassShelf.value = 0.0;
    trebleShelf.value = 0.0;
    earGain.value = 0.0;
    // This should trigger the graph to recalculate and redraw the target curve.
  }

  // Methods to increment/decrement values, which can be linked to spinner buttons.
  void incrementTilt(double step) => tilt.value += step;
  void decrementTilt(double step) => tilt.value -= step;

  void incrementBass(double step) => bassShelf.value += step;
  void decrementBass(double step) => bassShelf.value -= step;

  void incrementTreble(double step) => trebleShelf.value += step;
  void decrementTreble(double step) => trebleShelf.value -= step;

  void incrementEarGain(double step) => earGain.value += step;
  void decrementEarGain(double step) => earGain.value -= step;
}
