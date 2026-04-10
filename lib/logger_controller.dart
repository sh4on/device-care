import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class LoggerController extends GetxController with WidgetsBindingObserver {
  static const platform = MethodChannel('com.example.app/events');

  var logs = <String>[].obs;
  var isAccessibilityEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initMethodChannel();
    _loadLogsFromFile();
    checkAccessibilityStatus();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadLogsFromFile();
      checkAccessibilityStatus();
    }
  }

  void _initMethodChannel() {
    platform.setMethodCallHandler((call) async {
      if (call.method == "onKeyStroke") {
        final entry = "${DateTime.now()}: ${call.arguments}";
        debugPrint("Received from native: $entry");
        logs.insert(0, entry);
      }
    });
  }

  Future<void> checkAccessibilityStatus() async {
    try {
      final bool result = await platform.invokeMethod('isAccessibilityEnabled');
      isAccessibilityEnabled.value = result;
    } catch (e) {
      debugPrint("Accessibility check error: $e");
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      debugPrint("Open accessibility settings error: $e");
    }
  }

  Future<void> _loadLogsFromFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filesDir = dir.path.replaceFirst('/app_flutter', '');
      final file = File('$filesDir/../files/security_logs.txt');

      if (await file.exists()) {
        final lines = await file.readAsLines();
        logs.assignAll(lines.reversed.toList());
      }
    } catch (e) {
      debugPrint("File load error: $e");
    }
  }
}
