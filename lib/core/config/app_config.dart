/// Build-time mode selection.
///
/// CI/Vercel review builds explicitly set PADALAB_DEMO_MODE=true. The default
/// is false so a normal/release build fails closed and cannot launch synthetic
/// items as a participant assessment.
abstract final class AppConfig {
  static const bool demoMode = bool.fromEnvironment(
    'PADALAB_DEMO_MODE',
    defaultValue: false,
  );
}
