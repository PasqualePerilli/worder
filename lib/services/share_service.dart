import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_state.dart';
import '../screens/shareable_results_screen.dart';
import 'config_service.dart';

class ShareService {
  /// Share results - uses native share on modern platforms,
  /// manual screenshot flow on older platforms
  static Future<void> shareResults({
    required BuildContext context,
    required GameState gameState,
    required ScreenshotController screenshotController,
    required List<dynamic> topWords,
  }) async {
    // Check platform capability
    final canUseNativeShare = await _canUseNativeShare();

    if (canUseNativeShare) {
      // Use screenshot + share_plus for modern Android and iOS
      await _shareWithNativeShare(
        context: context,
        screenshotController: screenshotController,
        topWords: topWords,
      );
    } else {
      // Use manual screenshot screen for older Android, Linux, Windows, macOS
      await _shareWithManualScreenshot(
        context: context,
        gameState: gameState,
      );
    }
  }

  /// Check if platform supports native image sharing
  static Future<bool> _canUseNativeShare() async {
    if (Platform.isAndroid) {
      // For Android, we need to check API level
      // Since we can't easily detect without a plugin,
      // we'll use a conservative approach:
      // Default to manual screenshot for compatibility
      // 
      // To enable native share on Android 14+, you would need
      // to add device_info_plus package and check:
      // final androidInfo = await DeviceInfoPlugin().androidInfo;
      // return androidInfo.version.sdkInt >= 34;
      
      return false; // Conservative default - use manual screenshot
    } else if (Platform.isIOS) {
      // iOS has good share support across versions
      return true;
    } else {
      // Linux, Windows, macOS - share_plus has limited/no support
      return false;
    }
  }

  /// Share using native screenshot + share_plus
  static Future<void> _shareWithNativeShare({
    required BuildContext context,
    required ScreenshotController screenshotController,
    required List<dynamic> topWords,
  }) async {
    try {
      // Capture screenshot
      final image = await screenshotController.capture();
      if (image == null) {
        _showError(context, 'Failed to capture screenshot');
        return;
      }

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = '${directory.path}/worder_results_$timestamp.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      // Share the image
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Check out my WORDER results!',
      );
    } catch (e) {
      _showError(context, 'Failed to share: $e');
    }
  }

  /// Share using manual screenshot screen
  static Future<void> _shareWithManualScreenshot({
    required BuildContext context,
    required GameState gameState,
  }) async {
    // Navigate to shareable results screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareableResultsScreen(gameState: gameState),
      ),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
