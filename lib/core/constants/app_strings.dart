// app-wide string constants
class AppStrings {
  AppStrings._();

  // app identity
  static const String appTitle = 'Device Care';

  // status card strings
  static const String statusActive = 'System Monitor Active';
  static const String statusInactive = 'System Monitor Inactive';
  static const String statusActiveSubtitle =
      'Monitoring device input performance';
  static const String statusInactiveSubtitle =
      'Tap to enable in Accessibility Settings';

  // activity log strings
  static const String activityLogTitle = 'System Activity Log';
  static const String noActivityMessage = 'No activity recorded yet.';

  // Added for the device health screen
  static const String healthGoodTitle = 'DEVICE HEALTH: 100%';
  static const String healthGoodSubtitle =
      'Your device health is completely secure and running at peak performance.';
}
