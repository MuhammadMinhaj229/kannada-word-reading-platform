import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

/// Integrates Android Google Play's in-app update mechanism.
///
/// The service is intentionally a no-op for Web, debug and non-Android builds.
/// Play in-app updates require the installed package to come from Google Play;
/// sideloaded APKs and Vercel previews are not update sources.
class PlayUpdateService {
  const PlayUpdateService();

  Future<void> checkAndApplyAvailableUpdate() async {
    if (kIsWeb || kDebugMode || !Platform.isAndroid) return;

    try {
      final update = await InAppUpdate.checkForUpdate();
      if (update.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      // Only force a blocking update for a high-priority release. Normal
      // feature releases use the flexible flow and complete at application
      // startup, before an assessor can begin a session.
      if (update.updatePriority >= 4 && update.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (update.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } on PlatformException catch (error, stackTrace) {
      // A local APK or a device without Play Store integration commonly
      // returns API_NOT_AVAILABLE. Do not crash or block the safe launch UI.
      debugPrint(
        'Padalab Play update check unavailable: ${error.code} '
        '${error.message ?? ''}',
      );
      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      debugPrint('Padalab Play update check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
