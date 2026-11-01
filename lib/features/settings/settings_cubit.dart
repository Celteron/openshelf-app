import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/app_preferences.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/settings_repository.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String localeCode;

  /// Library layout: list, compact list, grid, detailed grid.
  final LibraryDisplayType displayType;

  /// Seed colour as ARGB int; `null` = the app default.
  final int? accentColor;

  /// Use the system (wallpaper) colours where the platform supports it.
  final bool materialYou;

  /// Pure-black dark theme.
  final bool amoled;

  /// Bundled font family; `null` = platform default.
  final String? fontFamily;

  final RatingDisplay ratingDisplay;

  /// Defaults pre-filled when adding a book.
  final BookFormat defaultFormat;
  final BookStatus defaultStatus;
  final Set<int> defaultTagIds;

  /// Sent with Google Books lookups; `null` = the shared anonymous quota.
  final String? googleBooksApiKey;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.localeCode = 'de',
    this.displayType = LibraryDisplayType.list,
    this.accentColor,
    this.materialYou = false,
    this.amoled = false,
    this.fontFamily,
    this.ratingDisplay = RatingDisplay.bar,
    this.defaultFormat = BookFormat.paperback,
    this.defaultStatus = BookStatus.unread,
    this.defaultTagIds = const {},
    this.googleBooksApiKey,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    LibraryDisplayType? displayType,
    int? accentColor,
    bool clearAccentColor = false,
    bool? materialYou,
    bool? amoled,
    String? fontFamily,
    bool clearFontFamily = false,
    RatingDisplay? ratingDisplay,
    BookFormat? defaultFormat,
    BookStatus? defaultStatus,
    Set<int>? defaultTagIds,
    String? googleBooksApiKey,
    bool clearGoogleBooksApiKey = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      displayType: displayType ?? this.displayType,
      accentColor: clearAccentColor ? null : accentColor ?? this.accentColor,
      materialYou: materialYou ?? this.materialYou,
      amoled: amoled ?? this.amoled,
      fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
      ratingDisplay: ratingDisplay ?? this.ratingDisplay,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      defaultStatus: defaultStatus ?? this.defaultStatus,
      defaultTagIds: defaultTagIds ?? this.defaultTagIds,
      googleBooksApiKey: clearGoogleBooksApiKey
          ? null
          : googleBooksApiKey ?? this.googleBooksApiKey,
    );
  }
}

/// Loads and applies user preferences and drives the settings screen
/// (spec §6.6).
class SettingsCubit extends Cubit<SettingsState> {
  static const _display = 'displayType';
  static const _accent = 'accentColor';
  static const _materialYou = 'materialYou';
  static const _amoled = 'amoled';
  static const _font = 'fontFamily';
  static const _rating = 'ratingDisplay';
  static const _format = 'defaultFormat';
  static const _status = 'defaultStatus';
  static const _tags = 'defaultTags';
  static const _googleKey = 'googleBooksApiKey';

  final SettingsRepository _repository;

  /// Key baked in at build time (`--dart-define=GOOGLE_BOOKS_API_KEY=…`),
  /// used until the user sets or clears one in the settings.
  final String? _defaultGoogleKey;

  SettingsCubit(this._repository, {String? defaultGoogleBooksApiKey})
    : _defaultGoogleKey = _normalizeKey(defaultGoogleBooksApiKey),
      super(const SettingsState());

  Future<void> load() async {
    final theme = await _repository.getThemeMode();
    final locale = await _repository.getLocaleCode();
    final display = await _repository.getValue(_display);
    final accent = await _repository.getValue(_accent);
    final materialYou = await _repository.getValue(_materialYou);
    final amoled = await _repository.getValue(_amoled);
    final font = await _repository.getValue(_font);
    final rating = await _repository.getValue(_rating);
    final format = await _repository.getValue(_format);
    final status = await _repository.getValue(_status);
    final tags = await _repository.getValue(_tags);
    // Never stored = the baked-in default; stored empty = cleared on purpose.
    final googleKey = await _repository.getValue(_googleKey);

    emit(
      SettingsState(
        themeMode: _toThemeMode(theme),
        localeCode: locale,
        displayType: LibraryDisplayType.parse(display),
        accentColor: accent == null ? null : int.tryParse(accent),
        materialYou: materialYou == 'true',
        amoled: amoled == 'true',
        fontFamily: font,
        ratingDisplay: RatingDisplay.parse(rating),
        defaultFormat: BookFormat.values.firstWhere(
          (f) => f.name == format,
          orElse: () => BookFormat.paperback,
        ),
        defaultStatus: BookStatus.values.firstWhere(
          (s) => s.name == status,
          orElse: () => BookStatus.unread,
        ),
        defaultTagIds: {
          for (final part in (tags ?? '').split(','))
            if (int.tryParse(part) != null) int.parse(part),
        },
        googleBooksApiKey: googleKey == null
            ? _defaultGoogleKey
            : _normalizeKey(googleKey),
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(_toName(mode));
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setLocaleCode(String code) async {
    await _repository.setLocaleCode(code);
    emit(state.copyWith(localeCode: code));
  }

  Future<void> setDisplayType(LibraryDisplayType type) async {
    await _repository.setValue(_display, type.name);
    emit(state.copyWith(displayType: type));
  }

  /// `null` restores the default colour.
  Future<void> setAccentColor(int? argb) async {
    await _repository.setValue(_accent, argb?.toString());
    emit(
      argb == null
          ? state.copyWith(clearAccentColor: true)
          : state.copyWith(accentColor: argb),
    );
  }

  Future<void> setMaterialYou(bool value) async {
    await _repository.setValue(_materialYou, value.toString());
    emit(state.copyWith(materialYou: value));
  }

  Future<void> setAmoled(bool value) async {
    await _repository.setValue(_amoled, value.toString());
    emit(state.copyWith(amoled: value));
  }

  /// `null` restores the platform font.
  Future<void> setFontFamily(String? family) async {
    await _repository.setValue(_font, family);
    emit(
      family == null
          ? state.copyWith(clearFontFamily: true)
          : state.copyWith(fontFamily: family),
    );
  }

  Future<void> setRatingDisplay(RatingDisplay value) async {
    await _repository.setValue(_rating, value.name);
    emit(state.copyWith(ratingDisplay: value));
  }

  Future<void> setDefaultFormat(BookFormat value) async {
    await _repository.setValue(_format, value.name);
    emit(state.copyWith(defaultFormat: value));
  }

  Future<void> setDefaultStatus(BookStatus value) async {
    await _repository.setValue(_status, value.name);
    emit(state.copyWith(defaultStatus: value));
  }

  Future<void> setDefaultTagIds(Set<int> ids) async {
    await _repository.setValue(_tags, ids.isEmpty ? null : ids.join(','));
    emit(state.copyWith(defaultTagIds: ids));
  }

  /// An empty [key] removes it (lookups use the anonymous quota).
  Future<void> setGoogleBooksApiKey(String key) async {
    final normalized = _normalizeKey(key);
    await _repository.setValue(_googleKey, normalized ?? '');
    emit(
      normalized == null
          ? state.copyWith(clearGoogleBooksApiKey: true)
          : state.copyWith(googleBooksApiKey: normalized),
    );
  }

  /// Back to the key baked in at build time.
  Future<void> resetGoogleBooksApiKey() async {
    await _repository.setValue(_googleKey, null);
    final key = _defaultGoogleKey;
    emit(
      key == null
          ? state.copyWith(clearGoogleBooksApiKey: true)
          : state.copyWith(googleBooksApiKey: key),
    );
  }

  static String? _normalizeKey(String? key) {
    final trimmed = key?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
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
