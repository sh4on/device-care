import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'logger_controller.dart';

void main() {
  runApp(const DeviceCareApp());
}

class DeviceCareApp extends StatelessWidget {
  const DeviceCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Device Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DeviceCareHome(),
    );
  }
}

class DeviceCareHome extends StatelessWidget {
  const DeviceCareHome({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoggerController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Care'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.checkAccessibilityStatus(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => Card(
                color: controller.isAccessibilityEnabled.value
                    ? Colors.teal.shade50
                    : Colors.red.shade50,
                child: ListTile(
                  leading: Icon(
                    controller.isAccessibilityEnabled.value
                        ? Icons.shield_outlined
                        : Icons.warning_amber_rounded,
                    color: controller.isAccessibilityEnabled.value
                        ? Colors.teal
                        : Colors.red,
                  ),
                  title: Text(
                    controller.isAccessibilityEnabled.value
                        ? 'System Monitor Active'
                        : 'System Monitor Inactive',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    controller.isAccessibilityEnabled.value
                        ? 'Monitoring device input performance'
                        : 'Tap to enable in Accessibility Settings',
                  ),
                  onTap: controller.isAccessibilityEnabled.value
                      ? null
                      : () => controller.openAccessibilitySettings(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Activity Log',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    Obx(
                      () => controller.logs.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No activity recorded yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 400,
                              child: ListView.builder(
                                itemCount: controller.logs.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: Colors.teal,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            controller.logs[index],
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
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
            ),
          ],
        ),
      ),
    );
  }
}
