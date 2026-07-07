import 'package:get/get.dart';
import 'package:flutter_phone_events/modules/home/controllers/home_controller.dart';

// binding for the home module — lazily injects HomeController
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
