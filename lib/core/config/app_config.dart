/// Build-time application mode.
///
/// CI/Vercel review builds explicitly set PADALAB_DEMO_MODE=true. The default
/// is false so a normal/release build cannot launch synthetic items as a
/// participant assessment.
///
/// Play in-app update checks are opt-out for non-debug Android release builds,
/// but are always skipped by Web and debug builds. They only work for packages
/// distributed through Google Play (including internal testing tracks).
abstract final class AppConfig {
  static const bool demoMode = bool.fromEnvironment(
    'PADALAB_DEMO_MODE',
    defaultValue: false,
  );

  static const bool playUpdatesEnabled = bool.fromEnvironment(
    'PADALAB_PLAY_UPDATES',
    defaultValue: true,
  );
}
