import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_phone_events/core/constants/app_colors.dart';
import 'package:flutter_phone_events/core/constants/app_strings.dart';
import 'package:flutter_phone_events/routes/app_routes.dart';
import 'package:flutter_phone_events/routes/app_pages.dart';

// root application widget with theme and routing configuration
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
    );
  }
}
