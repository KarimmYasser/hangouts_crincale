import 'package:get/get.dart';
import 'package:hangouts_crincale/app/controllers/selection_controller.dart';
import 'graph_controller.dart';
import '../data/models/frequency_response.dart';

class ManageController extends GetxController {
  final GraphController _graphController = Get.find();

  // A direct reference to the list of curves from the GraphController.
  // The UI will observe this list to build the management table.
  RxList<FrequencyResponse> get activeCurves => _graphController.curves;

  /// Removes a curve from the graph and the management table.
  void removeCurve(String curveId) {
    _graphController.removeCurve(curveId);
    Get.find<SelectionController>().filteredModels.refresh();
  }

  /// Sets a curve as the baseline for comparison.
  void setBaseline(FrequencyResponse curve) {
    _graphController.setBaseline(curve);
  }

  /// Toggles the visibility of a curve on the graph.
  void hideCurve(String curveId) {
    _graphController.toggleCurveVisibility(curveId);
  }
}
