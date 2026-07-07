import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_phone_events/core/constants/app_colors.dart';
import 'package:flutter_phone_events/core/constants/app_strings.dart';
import 'package:flutter_phone_events/modules/home/controllers/home_controller.dart';

// card displaying the system activity log list
class ActivityLogCard extends StatelessWidget {
  const ActivityLogCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // section title
            const Text(
              AppStrings.activityLogTitle,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),

            // log list or empty state — Expanded fills the remaining tab height
            Expanded(
              child: Obx(
                () => controller.logs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            AppStrings.noActivityMessage,
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: controller.logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                // log entry bullet
                                const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                // log entry text
                                Expanded(
                                  child: Text(
                                    controller.logs[index],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
