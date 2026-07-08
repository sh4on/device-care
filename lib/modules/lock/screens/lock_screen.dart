import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/lock_screen_controller.dart';
import '../widgets/status_card.dart'; // Import path for the extracted widget

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LockScreenController controller = Get.find<LockScreenController>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Background Tech Gradient Glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Render the extracted widget here
                const StatusCard(),

                const Spacer(),

                // Invisible Slider wrapped inside Obx to track value updates
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 20.0,
                  ),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 20,
                      thumbShape: SliderComponentShape.noThumb,
                      overlayShape: SliderComponentShape.noOverlay,
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                    ),
                    child: Obx(
                      () => Slider(
                        value: controller.sliderValue.value,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) =>
                            controller.updateSliderValue(value),
                        onChangeEnd: (value) {
                          if (value >= 0.95) {
                            controller.showSecretDialog(context);
                          }
                          controller.resetSlider();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
