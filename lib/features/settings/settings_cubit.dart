import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/repositories/settings_repository.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String localeCode;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.localeCode = 'de',
  });

  SettingsState copyWith({ThemeMode? themeMode, String? localeCode}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
    );
  }
}

/// Loads and applies user preferences (theme + language) and drives the
/// settings screen (spec §6.6).
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit(this._repository) : super(const SettingsState());

  Future<void> load() async {
    final theme = await _repository.getThemeMode();
    final locale = await _repository.getLocaleCode();
    emit(SettingsState(themeMode: _toThemeMode(theme), localeCode: locale));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(_toName(mode));
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setLocaleCode(String code) async {
    await _repository.setLocaleCode(code);
    emit(state.copyWith(localeCode: code));
  }

  static ThemeMode _toThemeMode(String name) => switch (name) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _toName(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}
