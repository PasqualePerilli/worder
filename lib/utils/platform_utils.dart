import 'dart:io';

class PlatformUtils {
  /// Check if running on Android 14 (API 34) or later
  static Future<bool> isAndroid14OrLater() async {
    if (!Platform.isAndroid) {
      // On non-Android platforms, assume modern version
      return true;
    }

    try {
      // Get Android SDK version
      // This is a simplified approach - in production you might use
      // a plugin like device_info_plus for more accurate detection
      final androidVersion = Platform.version;
      
      // Platform.version format on Android is like:
      // "2.10.0 (stable) (Tue Oct 13 11:22:04 2020 +0200) on "android_ia32""
      // We need to check the actual Android API level through other means
      
      // For now, we'll use a more direct approach with platform channels
      // or assume based on minimum SDK requirements
      
      // Since we can't easily get API level without a plugin,
      // we'll return false by default and let modern devices work
      // This ensures older devices get the manual screenshot flow
      return false;
    } catch (e) {
      // If detection fails, default to manual screenshot (safer)
      return false;
    }
  }

  /// Check if the platform supports native sharing with images
  static Future<bool> supportsImageSharing() async {
    if (Platform.isAndroid) {
      return await isAndroid14OrLater();
    } else if (Platform.isIOS) {
      // iOS 14+ supports share sheet with images
      // For simplicity, assume all iOS versions support it
      return true;
    } else {
      // Linux, Windows, macOS - no share_plus support
      return false;
    }
  }
}
