/// Persists user preferences (theme mode and locale) across app restarts.
///
/// Values are stored as plain strings so this abstraction stays free of
/// Flutter widget types (Constitution Article II).
abstract class SettingsRepository {
  /// One of `'system'`, `'light'`, `'dark'`.
  Future<String> getThemeMode();

  Future<void> setThemeMode(String mode);

  /// A two-letter language code (e.g. `'de'`, `'en'`).
  Future<String> getLocaleCode();

  Future<void> setLocaleCode(String code);
}
