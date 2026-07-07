import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

// handles all method channel communication with native android layer
class MethodChannelService {
  // channel name must match the CHANNEL constant in MainActivity.kt
  static const _channel = MethodChannel('com.shaonx.device_care/events');

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
  // throws PlatformException if READ_CALL_LOG permission is denied — callers
  // should catch PlatformException to distinguish denial from an empty log
  Future<List<Map<String, dynamic>>> getCallLogs() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getCallLogs');
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException {
      // let PlatformException bubble so HomeController can set the permission flag
      rethrow;
    } catch (e) {
      debugPrint('Get call logs error: $e');
      return [];
    }
  }

  // fetch last 50 SMS entries from native layer
  // throws PlatformException if READ_SMS permission is denied
  Future<List<Map<String, dynamic>>> getSmsLogs() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getSmsLogs');
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException {
      rethrow;
    } catch (e) {
      debugPrint('Get SMS logs error: $e');
      return [];
    }
  }
}
