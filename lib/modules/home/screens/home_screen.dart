import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_phone_events/core/constants/app_colors.dart';
import 'package:flutter_phone_events/core/constants/app_strings.dart';
import 'package:flutter_phone_events/modules/home/controllers/home_controller.dart';
import 'package:flutter_phone_events/modules/home/widgets/status_card.dart';
import 'package:flutter_phone_events/modules/home/widgets/activity_log_card.dart';

// home screen — displays accessibility status and activity logs
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.appTitle),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          actions: [
            // refresh accessibility status and data
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                controller.checkAccessibilityStatus();
                controller.fetchCommData();
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.white,
            tabs: [
              Tab(text: "Keystrokes"),
              Tab(text: "Calls"),
              Tab(text: "SMS"),
            ],
          ),
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: StatusCard(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Keystrokes
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: ActivityLogCard(),
                  ),
                  // Tab 2: Call Logs
                  Obx(() {
                    if (controller.isLoadingComm.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.callLogs.isEmpty) {
                      return const Center(child: Text("No call logs found."));
                    }
                    return ListView.builder(
                      itemCount: controller.callLogs.length,
                      itemBuilder: (context, index) {
                        final call = controller.callLogs[index];
                        return ListTile(
                          leading: Icon(
                            call['type'] == 'Incoming'
                                ? Icons.call_received
                                : call['type'] == 'Outgoing'
                                    ? Icons.call_made
                                    : Icons.call_missed,
                            color: call['type'] == 'Incoming'
                                ? Colors.green
                                : call['type'] == 'Outgoing'
                                    ? Colors.blue
                                    : Colors.red,
                          ),
                          title: Text(call['name'].toString().isNotEmpty
                              ? "${call['name']} (${call['number']})"
                              : call['number'].toString()),
                          subtitle: Text(
                              'Type: ${call['type']} | Duration: ${call['duration']}s\n${call['date']}'),
                          isThreeLine: true,
                        );
                      },
                    );
                  }),
                  // Tab 3: SMS Logs
                  Obx(() {
                    if (controller.isLoadingComm.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.smsLogs.isEmpty) {
                      return const Center(child: Text("No SMS logs found."));
                    }
                    return ListView.builder(
                      itemCount: controller.smsLogs.length,
                      itemBuilder: (context, index) {
                        final sms = controller.smsLogs[index];
                        return ListTile(
                          leading: Icon(
                            sms['type'] == 'Received'
                                ? Icons.mark_chat_unread
                                : Icons.send,
                            color: sms['type'] == 'Received'
                                ? Colors.orange
                                : Colors.purple,
                          ),
                          title: Text(sms['address'].toString()),
                          subtitle: Text('${sms['body']}\n${sms['date']}'),
                          isThreeLine: true,
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
