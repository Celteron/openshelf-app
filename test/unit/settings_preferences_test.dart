import 'dart:math';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/core/constants/app_fonts.dart';
import 'package:openreads/core/themes/app_theme.dart';
import 'package:openreads/domain/models/app_preferences.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/features/settings/settings_cubit.dart';

import '../helpers/fake_settings_repository.dart';

String pubspecText() => File('pubspec.yaml').readAsStringSync();

void main() {
  late FakeSettingsRepository repo;
  late SettingsCubit cubit;

  setUp(() {
    repo = FakeSettingsRepository();
    cubit = SettingsCubit(repo);
  });
  tearDown(() => cubit.close());

  group('defaults', () {
    test('a fresh install uses sensible defaults', () async {
      await cubit.load();

      final s = cubit.state;
      expect(s.themeMode, ThemeMode.system);
      expect(s.localeCode, 'de');
      expect(s.displayType, LibraryDisplayType.list);
      expect(s.accentColor, isNull);
      expect(s.materialYou, isFalse);
      expect(s.amoled, isFalse);
      expect(s.fontFamily, isNull);
      expect(s.ratingDisplay, RatingDisplay.bar);
      expect(s.defaultFormat, BookFormat.paperback);
      expect(s.defaultStatus, BookStatus.unread);
      expect(s.defaultTagIds, isEmpty);
    });
  });

  group('persistence', () {
    test('every setting is stored and restored by a fresh cubit', () async {
      await cubit.setDisplayType(LibraryDisplayType.detailedGrid);
      await cubit.setAccentColor(0xFF112233);
      await cubit.setMaterialYou(true);
      await cubit.setAmoled(true);
      await cubit.setFontFamily('Lora');
      await cubit.setRatingDisplay(RatingDisplay.number);
      await cubit.setDefaultFormat(BookFormat.ebook);
      await cubit.setDefaultStatus(BookStatus.wishlist);
      await cubit.setDefaultTagIds({3, 7});
      await cubit.setThemeMode(ThemeMode.dark);
      await cubit.setLocaleCode('en');

      final restored = SettingsCubit(repo);
      addTearDown(restored.close);
      await restored.load();

      final s = restored.state;
      expect(s.displayType, LibraryDisplayType.detailedGrid);
      expect(s.accentColor, 0xFF112233);
      expect(s.materialYou, isTrue);
      expect(s.amoled, isTrue);
      expect(s.fontFamily, 'Lora');
      expect(s.ratingDisplay, RatingDisplay.number);
      expect(s.defaultFormat, BookFormat.ebook);
      expect(s.defaultStatus, BookStatus.wishlist);
      expect(s.defaultTagIds, {3, 7});
      expect(s.themeMode, ThemeMode.dark);
      expect(s.localeCode, 'en');
    });

    test(
      'resetting the accent colour and font removes the stored value',
      () async {
        await cubit.setAccentColor(0xFF112233);
        await cubit.setFontFamily('Lora');
        expect(repo.values, containsPair('accentColor', '${0xFF112233}'));

        await cubit.setAccentColor(null);
        await cubit.setFontFamily(null);

        expect(cubit.state.accentColor, isNull);
        expect(cubit.state.fontFamily, isNull);
        expect(repo.values.containsKey('accentColor'), isFalse);
        expect(repo.values.containsKey('fontFamily'), isFalse);
      },
    );

    test('clearing the default tags removes the stored value', () async {
      await cubit.setDefaultTagIds({1});
      await cubit.setDefaultTagIds({});
      expect(repo.values.containsKey('defaultTags'), isFalse);
      expect(cubit.state.defaultTagIds, isEmpty);
    });

    test('corrupt stored values fall back to the defaults', () async {
      repo.values
        ..['displayType'] = 'hologram'
        ..['ratingDisplay'] = '???'
        ..['defaultFormat'] = 'scroll'
        ..['defaultStatus'] = 'maybe'
        ..['accentColor'] = 'red'
        ..['defaultTags'] = '1,x,,3';

      await cubit.load();

      final s = cubit.state;
      expect(s.displayType, LibraryDisplayType.list);
      expect(s.ratingDisplay, RatingDisplay.bar);
      expect(s.defaultFormat, BookFormat.paperback);
      expect(s.defaultStatus, BookStatus.unread);
      expect(s.accentColor, isNull);
      expect(s.defaultTagIds, {1, 3});
    });

    test('changing one setting keeps the others', () async {
      await cubit.setAmoled(true);
      await cubit.setFontFamily('Jost');
      await cubit.setDisplayType(LibraryDisplayType.grid);

      expect(cubit.state.amoled, isTrue);
      expect(cubit.state.fontFamily, 'Jost');
      expect(cubit.state.displayType, LibraryDisplayType.grid);
    });
  });

  group('enums', () {
    test('LibraryDisplayType.isGrid', () {
      expect(LibraryDisplayType.list.isGrid, isFalse);
      expect(LibraryDisplayType.compactList.isGrid, isFalse);
      expect(LibraryDisplayType.grid.isGrid, isTrue);
      expect(LibraryDisplayType.detailedGrid.isGrid, isTrue);
    });

    test('parse falls back to the first value', () {
      expect(LibraryDisplayType.parse('grid'), LibraryDisplayType.grid);
      expect(LibraryDisplayType.parse(null), LibraryDisplayType.list);
      expect(RatingDisplay.parse('number'), RatingDisplay.number);
      expect(RatingDisplay.parse('x'), RatingDisplay.bar);
    });
  });

  group('fonts', () {
    test('offers the platform default plus the fifteen Openreads fonts', () {
      expect(appFonts.first.family, isNull);
      expect(appFonts, hasLength(16));
      expect(
        appFonts.map((f) => f.family).whereType<String>().toSet(),
        containsAll([
          'AtkinsonHyperlegible',
          'OpenDyslexic',
          'Nunito',
          'Jost',
          'Barlow',
          'Inter',
          'Kanit',
          'Lato',
          'Lora',
          'Montserrat',
          'PlayfairDisplay',
          'Poppins',
          'Raleway',
          'SofiaSans',
          'Quicksand',
        ]),
      );
    });

    test('every family is declared in pubspec.yaml', () {
      final pubspec = pubspecText();
      for (final font in appFonts.where((f) => f.family != null)) {
        expect(pubspec, contains('family: ${font.family}'), reason: font.label);
      }
    });
  });

  group('buildAppTheme', () {
    test('seeds the colour scheme from the accent colour', () {
      final red = buildAppTheme(
        brightness: Brightness.light,
        accentColor: 0xFFD32F2F,
      );
      final blue = buildAppTheme(
        brightness: Brightness.light,
        accentColor: 0xFF1976D2,
      );

      expect(red.colorScheme.primary, isNot(blue.colorScheme.primary));
      expect(red.colorScheme.brightness, Brightness.light);
      expect(red.useMaterial3, isTrue);
    });

    test('without an accent the logo colours apply: petrol and amber', () {
      for (final brightness in Brightness.values) {
        final scheme = buildAppTheme(brightness: brightness).colorScheme;
        final hue = HSLColor.fromColor(scheme.primary).hue;

        expect(hue, inInclusiveRange(160, 195), reason: 'petrol/teal');
        expect(
          scheme.tertiary,
          brightness == Brightness.light
              ? const Color(0xFFB45309)
              : const Color(0xFFFBBF24),
          reason: 'amber like the ribbon',
        );
      }
    });

    test('the dark brand theme is tinted petrol, not grey', () {
      final scheme = buildAppTheme(brightness: Brightness.dark).colorScheme;

      expect(scheme.surface, const Color(0xFF0A171B));
      expect(scheme.surfaceContainer, const Color(0xFF12282E));
    });

    test('a custom accent replaces the brand colours', () {
      final scheme = buildAppTheme(
        brightness: Brightness.light,
        accentColor: 0xFFD32F2F,
      ).colorScheme;

      expect(scheme.tertiary, isNot(const Color(0xFFB45309)));
    });

    test('the selected navigation icon stands out from its indicator', () {
      double contrast(Color a, Color b) {
        final la = a.computeLuminance(), lb = b.computeLuminance();
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
      }

      for (final accent in [null, 0xFFD32F2F, 0xFF1976D2, 0xFFFFEB3B]) {
        for (final brightness in Brightness.values) {
          final theme = buildAppTheme(
            brightness: brightness,
            accentColor: accent,
          );
          final nav = theme.navigationBarTheme;
          final icon = nav.iconTheme!.resolve({WidgetState.selected})!.color!;

          expect(
            contrast(icon, nav.indicatorColor!),
            greaterThanOrEqualTo(3),
            reason: 'WCAG 1.4.11 for $accent / $brightness',
          );
        }
      }
    });

    test('Material You takes the system colours when there are any', () {
      final dynamicScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF5722),
        brightness: Brightness.light,
      );

      final themed = buildAppTheme(
        brightness: Brightness.light,
        accentColor: 0xFF1976D2,
        materialYou: true,
        dynamicScheme: dynamicScheme,
      );
      final seeded = buildAppTheme(
        brightness: Brightness.light,
        accentColor: 0xFF1976D2,
      );

      expect(themed.colorScheme.primary, isNot(seeded.colorScheme.primary));
    });

    test('Material You without system colours falls back to the accent', () {
      final theme = buildAppTheme(
        brightness: Brightness.light,
        accentColor: 0xFF1976D2,
        materialYou: true,
      );
      final seeded = buildAppTheme(
        brightness: Brightness.light,
        accentColor: 0xFF1976D2,
      );
      expect(theme.colorScheme.primary, seeded.colorScheme.primary);
    });

    test('AMOLED makes the dark theme pure black', () {
      final theme = buildAppTheme(brightness: Brightness.dark, amoled: true);

      expect(theme.colorScheme.surface, Colors.black);
      expect(theme.scaffoldBackgroundColor, Colors.black);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('AMOLED leaves the light theme alone', () {
      final amoled = buildAppTheme(brightness: Brightness.light, amoled: true);
      final plain = buildAppTheme(brightness: Brightness.light);

      expect(amoled.colorScheme.surface, plain.colorScheme.surface);
      expect(amoled.colorScheme.surface, isNot(Colors.black));
    });

    test('a plain dark theme is not black', () {
      final theme = buildAppTheme(brightness: Brightness.dark);
      expect(theme.colorScheme.surface, isNot(Colors.black));
    });

    test('applies the chosen font family', () {
      expect(
        buildAppTheme(
          brightness: Brightness.light,
          fontFamily: 'Lora',
        ).textTheme.bodyMedium?.fontFamily,
        'Lora',
      );
    });
  });

  group('Google Books API key', () {
    test('defaults to the key baked in at build time', () async {
      final baked = SettingsCubit(repo, defaultGoogleBooksApiKey: 'baked');
      addTearDown(baked.close);
      await baked.load();

      expect(baked.state.googleBooksApiKey, 'baked');
    });

    test('no key at all when none was baked in', () async {
      await cubit.load();

      expect(cubit.state.googleBooksApiKey, isNull);
    });

    test('a key set in the settings wins and survives a restart', () async {
      final baked = SettingsCubit(repo, defaultGoogleBooksApiKey: 'baked');
      addTearDown(baked.close);
      await baked.load();
      await baked.setGoogleBooksApiKey('  mine  ');
      expect(baked.state.googleBooksApiKey, 'mine');

      final restarted = SettingsCubit(repo, defaultGoogleBooksApiKey: 'baked');
      addTearDown(restarted.close);
      await restarted.load();
      expect(restarted.state.googleBooksApiKey, 'mine');
    });

    test('clearing the key means none, not the baked-in one', () async {
      final baked = SettingsCubit(repo, defaultGoogleBooksApiKey: 'baked');
      addTearDown(baked.close);
      await baked.load();
      await baked.setGoogleBooksApiKey('');
      expect(baked.state.googleBooksApiKey, isNull);

      final restarted = SettingsCubit(repo, defaultGoogleBooksApiKey: 'baked');
      addTearDown(restarted.close);
      await restarted.load();
      expect(restarted.state.googleBooksApiKey, isNull);
    });

    test('resetting brings the baked-in key back', () async {
      final baked = SettingsCubit(repo, defaultGoogleBooksApiKey: 'baked');
      addTearDown(baked.close);
      await baked.load();
      await baked.setGoogleBooksApiKey('');
      await baked.resetGoogleBooksApiKey();

      expect(baked.state.googleBooksApiKey, 'baked');
    });

    test('other settings keep the key', () async {
      await cubit.setGoogleBooksApiKey('mine');
      await cubit.setAmoled(true);

      expect(cubit.state.googleBooksApiKey, 'mine');
    });
  });
}
