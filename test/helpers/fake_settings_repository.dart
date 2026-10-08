import 'package:openreads/domain/repositories/settings_repository.dart';

/// In-memory [SettingsRepository] for tests.
class FakeSettingsRepository implements SettingsRepository {
  String theme = 'system';
  String locale = 'de';
  final values = <String, String>{};

  @override
  Future<String> getThemeMode() async => theme;

  @override
  Future<void> setThemeMode(String mode) async => theme = mode;

  @override
  Future<String> getLocaleCode() async => locale;

  @override
  Future<void> setLocaleCode(String code) async => locale = code;

  @override
  Future<String?> getValue(String key) async => values[key];

  @override
  Future<void> clearAll() async {
    theme = 'system';
    locale = 'de';
    values.clear();
  }

  @override
  Future<void> setValue(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}
