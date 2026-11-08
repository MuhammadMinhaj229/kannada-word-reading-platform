import 'apk_download_stub.dart'
    if (dart.library.html) 'apk_download_web.dart' as implementation;

/// Opens the stable engineering-preview APK from the browser UI.
abstract final class ApkDownloadService {
  static void openLatestAndroidPreview() {
    implementation.openLatestAndroidPreview();
  }
}
