import 'package:get/get.dart';
import 'package:flutter_phone_events/routes/app_routes.dart';
import 'package:flutter_phone_events/modules/home/bindings/home_binding.dart';
import 'package:flutter_phone_events/modules/home/screens/home_screen.dart';

import '../modules/lock/bindings/lock_screen_binding.dart';
import '../modules/lock/screens/lock_screen.dart';

// getx page definitions linking routes to screens and bindings
class AppPages {
  AppPages._();

  static final pages = [
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.lock,
      page: () => const LockScreen(),
      binding: LockScreenBinding(),
    ),
  ];
}
