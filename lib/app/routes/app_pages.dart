import 'package:get/get.dart';
import '../bindings/main_binding.dart';
import '../ui/screens/main_screen.dart';
part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.MAIN;

  static final routes = [
    GetPage(
      name: Routes.MAIN,
      page: () => MainScreen(),
      binding: MainBinding(),
    ),
  ];
}