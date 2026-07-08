// GetX Controller to handle business logic and state
import 'package:flutter/material.dart';
import 'package:flutter_phone_events/routes/app_pages.dart';
import 'package:flutter_phone_events/routes/app_routes.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';

class LockScreenController extends GetxController {
  // Reactive variable for the slider position
  final RxDouble sliderValue = 0.0.obs;

  // Controller for the textless input field
  final TextEditingController emailController = TextEditingController();

  void updateSliderValue(double value) {
    sliderValue.value = value;
  }

  void resetSlider() {
    sliderValue.value = 0.0;
  }

  // Opens the hidden, textless dialog box
  void showSecretDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.white),
                  cursorColor: AppColors.neonCyan,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.glassSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.glassBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.neonCyan),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Get.back();
                    emailController.clear();
                    Get.toNamed(AppRoutes.home); // Navigate to the home screen
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.neonCyan],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.darkBackground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void onClose() {
    emailController.dispose(); // Clean up text controller resource
    super.onClose();
  }
}
