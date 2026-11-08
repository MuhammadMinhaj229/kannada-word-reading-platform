import 'dart:html' as html;

const String _apkReleaseUrl =
    'https://github.com/MuhammadMinhaj229/kannada-word-reading-platform/releases/download/'
    'padalab-preview/padalab-android-arm64-debug.apk';

void openLatestAndroidPreview() {
  html.window.open(_apkReleaseUrl, '_blank', 'noopener,noreferrer');
}
