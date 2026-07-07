import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_phone_events/core/constants/app_colors.dart';
import 'package:flutter_phone_events/core/constants/app_strings.dart';
import 'package:flutter_phone_events/modules/home/controllers/home_controller.dart';

// accessibility service status indicator card with one-tap enable shortcut
class StatusCard extends StatelessWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(
      () => Card(
        color: controller.isAccessibilityEnabled.value
            ? AppColors.statusActiveBackground
            : AppColors.statusInactiveBackground,
        child: ListTile(
          leading: Icon(
            controller.isAccessibilityEnabled.value
                ? Icons.shield_outlined
                : Icons.warning_amber_rounded,
            color: controller.isAccessibilityEnabled.value
                ? AppColors.primary
                : AppColors.red,
          ),
          title: Text(
            controller.isAccessibilityEnabled.value
                ? AppStrings.statusActive
                : AppStrings.statusInactive,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            controller.isAccessibilityEnabled.value
                ? AppStrings.statusActiveSubtitle
                : AppStrings.statusInactiveSubtitle,
          ),
          onTap: controller.isAccessibilityEnabled.value
              ? null
              : () => controller.openAccessibilitySettings(),
        ),
      ),
    );
  }
}
