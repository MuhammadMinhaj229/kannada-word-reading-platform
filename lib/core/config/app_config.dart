/// Build-time platform configuration. The field application has no
/// synthetic/demo mode. Review builds use the same application entry point as
/// Android; the browser target is read-only for participant information.
abstract final class AppConfig {
  static const bool playUpdatesEnabled = bool.fromEnvironment(
    'PADALAB_PLAY_UPDATES',
    defaultValue: true,
  );
}
