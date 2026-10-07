import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/repositories/settings_repository.dart';
import 'package:openreads/features/settings/settings_cubit.dart';

class _FakeSettingsRepository implements SettingsRepository {
  String theme = 'system';
  String locale = 'de';
  final values = <String, String>{};

  @override
  Future<String?> getValue(String key) async => values[key];

  @override
  Future<void> setValue(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String> getThemeMode() async => theme;

  @override
  Future<void> setThemeMode(String mode) async => theme = mode;

  @override
  Future<String> getLocaleCode() async => locale;

  @override
  Future<void> setLocaleCode(String code) async => locale = code;
}

void main() {
  test('loads persisted theme and locale', () async {
    final repo = _FakeSettingsRepository()
      ..theme = 'dark'
      ..locale = 'en';
    final cubit = SettingsCubit(repo);

    await cubit.load();

    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.localeCode, 'en');
  });

  test('persists theme changes', () async {
    final repo = _FakeSettingsRepository();
    final cubit = SettingsCubit(repo);

    await cubit.setThemeMode(ThemeMode.light);

    expect(repo.theme, 'light');
    expect(cubit.state.themeMode, ThemeMode.light);
  });

  test('persists locale changes', () async {
    final repo = _FakeSettingsRepository();
    final cubit = SettingsCubit(repo);

    await cubit.setLocaleCode('en');

    expect(repo.locale, 'en');
    expect(cubit.state.localeCode, 'en');
  });
}
