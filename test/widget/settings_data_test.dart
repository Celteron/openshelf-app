import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/tag_with_count.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/data_reset_repository.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/domain/services/cover_sync_service.dart';
import 'package:openreads/domain/services/data_wipe_service.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/features/settings/settings_screen.dart';
import 'package:openreads/features/tags/tags_cubit.dart';
import 'package:openreads/features/trash/trash_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

import '../helpers/fake_settings_repository.dart';

class _Books implements BookRepository {
  final calls = <String>[];

  @override
  Future<int> trashAllBooks() async {
    calls.add('trashAll');
    return 4;
  }

  @override
  Future<int> deleteAllBooksPermanently() async {
    calls.add('deleteAll');
    return 4;
  }

  @override
  Stream<List<Book>> watchTrashedBooks() => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Tags implements TagRepository {
  @override
  Stream<List<TagWithCount>> watchTags() => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Reset implements DataResetRepository {
  var wiped = 0;

  @override
  Future<void> deleteAllData() async => wiped++;
}

/// The "Daten" section of the settings screen: empty the library (trash or for
/// good) and delete all local data (spec 003 FR-F1-11/12).
void main() {
  late Directory dir;
  late _Books books;
  late _Reset reset;
  late FakeSettingsRepository settings;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('settings_data_test');
    books = _Books();
    reset = _Reset();
    settings = FakeSettingsRepository()..values['ratingDisplay'] = 'number';
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final cubit = SettingsCubit(settings);
    await cubit.load();
    addTearDown(cubit.close);
    final cache = CoverCacheService(baseDirectory: dir);
    final service = DataWipeService(
      books: books,
      reset: reset,
      settings: settings,
      covers: cache,
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<BookRepository>.value(value: books),
          RepositoryProvider.value(value: CoverSyncService(books, cache)),
          RepositoryProvider.value(value: service),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider(create: (_) => TagsCubit(_Tags())..load()),
            BlocProvider(create: (_) => TrashCubit(books)),
          ],
          child: const MaterialApp(
            locale: Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapTile(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(finder, 300);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('Bibliothek leeren', () {
    testWidgets('offers the trash or deleting for good', (tester) async {
      await pump(tester);
      await tapTile(tester, 'clear-library');

      expect(find.text('Bibliothek leeren?'), findsOneWidget);
      expect(find.text('In den Papierkorb'), findsOneWidget);
      expect(find.text('Endgültig löschen'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(books.calls, isEmpty);
    });

    testWidgets('the trash option moves all books and says so', (tester) async {
      await pump(tester);
      await tapTile(tester, 'clear-library');
      await tester.tap(find.text('In den Papierkorb'));
      await tester.pumpAndSettle();

      expect(books.calls, ['trashAll']);
      expect(
        find.text('4 Bücher in den Papierkorb verschoben'),
        findsOneWidget,
      );
    });

    testWidgets('deleting for good asks a second time', (tester) async {
      await pump(tester);
      await tapTile(tester, 'clear-library');
      await tester.tap(find.text('Endgültig löschen'));
      await tester.pumpAndSettle();

      expect(find.text('Wirklich endgültig löschen?'), findsOneWidget);
      expect(books.calls, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Endgültig löschen'));
      await tester.pumpAndSettle();

      expect(books.calls, ['deleteAll']);
    });

    testWidgets('cancelling changes nothing', (tester) async {
      await pump(tester);
      await tapTile(tester, 'clear-library');
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(books.calls, isEmpty);
    });
  });

  group('Alle Daten löschen', () {
    testWidgets('needs the confirmation word', (tester) async {
      await pump(tester);
      await tapTile(tester, 'delete-all-data');

      final confirm = find.widgetWithText(FilledButton, 'Alles löschen');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('confirm-word')),
        'falsch',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('confirm-word')),
        'LÖSCHEN',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    });

    testWidgets('wipes the database, the covers and the settings', (
      tester,
    ) async {
      await pump(tester);
      await tapTile(tester, 'delete-all-data');
      await tester.enterText(
        find.byKey(const ValueKey('confirm-word')),
        'LÖSCHEN',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Alles löschen'));
      // Deleting the cover folder is real file I/O, which FakeAsync can't run.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();

      expect(reset.wiped, 1);
      expect(settings.values, isEmpty);
      expect(find.text('Alle Daten wurden gelöscht'), findsOneWidget);
    });
  });
}
