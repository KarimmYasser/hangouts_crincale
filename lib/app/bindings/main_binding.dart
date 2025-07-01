import 'package:get/get.dart';
import '../controllers/graph_controller.dart';
import '../controllers/tools_controller.dart';
import '../controllers/preference_controller.dart';
import '../controllers/manage_controller.dart';
import '../controllers/selection_controller.dart';
import '../controllers/equalizer_controller.dart';
import '../controllers/audio_player_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GraphController>(() => GraphController());
    Get.lazyPut<ToolsController>(() => ToolsController());
    Get.lazyPut<PreferenceController>(() => PreferenceController());
    Get.lazyPut<ManageController>(() => ManageController());
    Get.lazyPut<SelectionController>(() => SelectionController());
    Get.lazyPut<EqualizerController>(() => EqualizerController());
    Get.lazyPut<AudioPlayerController>(() => AudioPlayerController());
  }
}