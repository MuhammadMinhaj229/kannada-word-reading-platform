import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

enum PlayUpdateStatus {
  unsupported,
  upToDate,
  updated,
  unavailable,
  failed,
}

class PlayUpdateResult {
  const PlayUpdateResult({
    required this.status,
    required this.message,
  });

  final PlayUpdateStatus status;
  final String message;
}

/// Checks and installs application updates published through Google Play.
///
/// This is deliberately user-triggered from the idle assessor home screen.
/// It is not a Vercel updater and cannot update locally sideloaded APKs.
class PlayUpdateService {
  const PlayUpdateService();

  Future<PlayUpdateResult> checkAndApplyAvailableUpdate() async {
    if (kIsWeb ||
        kDebugMode ||
        defaultTargetPlatform != TargetPlatform.android) {
      return const PlayUpdateResult(
        status: PlayUpdateStatus.unsupported,
        message:
            'Updates are available only in the Android release from Google Play.',
      );
    }

    try {
      final update = await InAppUpdate.checkForUpdate();
      if (update.updateAvailability != UpdateAvailability.updateAvailable) {
        return const PlayUpdateResult(
          status: PlayUpdateStatus.upToDate,
          message: 'This app is up to date.',
        );
      }

      // High-priority, approved releases may require an immediate update.
      if (update.updatePriority >= 4 && update.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return const PlayUpdateResult(
          status: PlayUpdateStatus.updated,
          message: 'The update was installed successfully.',
        );
      }

      // Normal releases use Play's flexible flow. Complete the install only
      // after Google Play reports that the package has finished downloading.
      if (update.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
        return const PlayUpdateResult(
          status: PlayUpdateStatus.updated,
          message: 'The update was installed successfully.',
        );
      }

      return const PlayUpdateResult(
        status: PlayUpdateStatus.unavailable,
        message:
            'An update exists, but Google Play cannot install it right now.',
      );
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Padalab Play update check unavailable: ${error.code}');
      debugPrintStack(stackTrace: stackTrace);

      final code = error.code.toUpperCase();
      if (code.contains('API_NOT_AVAILABLE') ||
          code.contains('APP_NOT_OWNED')) {
        return const PlayUpdateResult(
          status: PlayUpdateStatus.unsupported,
          message:
              'This APK was not installed from Google Play. Install the Play testing build to use update refresh.',
        );
      }

      return const PlayUpdateResult(
        status: PlayUpdateStatus.failed,
        message:
            'Could not check for updates. Connect to the internet and try again.',
      );
    } catch (error, stackTrace) {
      debugPrint('Padalab Play update check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const PlayUpdateResult(
        status: PlayUpdateStatus.failed,
        message: 'Could not check for updates. Please try again later.',
      );
    }
  }
}
