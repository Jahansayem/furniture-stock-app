// lib/constants/onesignal_config.dart

class OneSignalConfig {
  // App ID should be provided via --dart-define ONESIGNAL_APP_ID=...
  static const String appId = String.fromEnvironment('ONESIGNAL_APP_ID');

  // Deprecated: Do NOT store or use REST API keys in client apps.
  // Kept only to satisfy references; leave empty.
  static const String restApiKey = '';
}
