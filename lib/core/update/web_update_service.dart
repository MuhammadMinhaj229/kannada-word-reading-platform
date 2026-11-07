import 'web_update_stub.dart'
    if (dart.library.html) 'web_update_web.dart' as implementation;

/// Web-only service-worker update adapter. Native Android updates use the
/// separately guarded Android distribution channel.
abstract final class WebUpdateService {
  static Future<bool> checkAndActivate() {
    return implementation.checkAndActivateWebUpdate();
  }
}
