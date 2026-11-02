import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/data_reset_repository_impl.dart';
import 'package:openreads/data/repositories/settings_repository_impl.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/services/data_wipe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_settings_repository.dart';
import '../helpers/test_images.dart';

/// "Bibliothek leeren" and "Alle Daten löschen" (spec 003 FR-F1-11/12).
void main() {
  late AppDatabase db;
  late BookRepositoryImpl books;
  late Directory dir;
  late CoverCacheService covers;
  late FakeSettingsRepository settings;
  late DataWipeService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    books = BookRepositoryImpl(BooksDao(db));
    dir = Directory.systemTemp.createTempSync('wipe_test');
    covers = CoverCacheService(baseDirectory: dir);
    settings = FakeSettingsRepository()..values['ratingDisplay'] = 'number';
    service = DataWipeService(
      books: books,
      reset: DataResetRepositoryImpl(db),
      settings: settings,
      covers: covers,
    );
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<int> addBook(String title, {DateTime? deletedAt}) => db
      .into(db.books)
      .insert(
        BooksCompanion.insert(
          title: title,
          authors: const ['A'],
          editedFields: const [],
          deletedAt: Value(deletedAt),
        ),
      );

  Future<void> seedEverything() async {
    final bookId = await addBook('Buch');
    await db
        .into(db.locations)
        .insert(
          LocationsCompanion.insert(name: 'Regal', type: LocationType.shelf),
        );
    await db
        .into(db.seriesTable)
        .insert(SeriesTableCompanion.insert(name: 'S'));
    await db
        .into(db.lending)
        .insert(
          LendingCompanion.insert(
            bookId: bookId,
            borrowerName: 'Anna',
            lentAt: DateTime(2026),
          ),
        );
    await db
        .into(db.readingSessions)
        .insert(
          ReadingSessionsCompanion.insert(
            bookId: bookId,
            startedAt: DateTime(2026),
          ),
        );
    await db
        .into(db.bookNotes)
        .insert(
          BookNotesCompanion.insert(
            bookId: bookId,
            kind: NoteKind.note,
            content: 'n',
          ),
        );
    final tagId = await db
        .into(db.tags)
        .insert(TagsCompanion.insert(name: 't'));
    await db
        .into(db.bookTags)
        .insert(BookTagsCompanion.insert(bookId: bookId, tagId: tagId));
    await db
        .into(db.readingGoals)
        .insert(
          ReadingGoalsCompanion.insert(
            year: const Value(2026),
            targetBooks: 12,
          ),
        );
    await covers.saveCover('9783442719255', testPng());
  }

  group('trashLibrary', () {
    test('moves every active book to the trash and counts them', () async {
      await addBook('A');
      await addBook('B');
      final already = DateTime(2025, 5, 5);
      await addBook('C', deletedAt: already);

      expect(await service.trashLibrary(), 2);

      final all = await db.select(db.books).get();
      expect(all.every((b) => b.deletedAt != null), isTrue);
      expect(
        all.singleWhere((b) => b.title == 'C').deletedAt,
        already,
        reason: 'books already in the trash keep their date',
      );
    });
  });

  group('deleteLibrary', () {
    test('removes all books incl. the trash, with their satellites', () async {
      await seedEverything();
      await addBook('Im Papierkorb', deletedAt: DateTime(2025));

      expect(await service.deleteLibrary(), 2);

      expect(await db.select(db.books).get(), isEmpty);
      expect(await db.select(db.lending).get(), isEmpty);
      expect(await db.select(db.readingSessions).get(), isEmpty);
      expect(await db.select(db.bookNotes).get(), isEmpty);
      expect(await db.select(db.bookTags).get(), isEmpty);
      expect(covers.cachedPath('9783442719255'), isNull);
    });

    test('keeps locations, tags, goals and the settings', () async {
      await seedEverything();

      await service.deleteLibrary();

      expect(await db.select(db.locations).get(), hasLength(1));
      expect(await db.select(db.tags).get(), hasLength(1));
      expect(await db.select(db.readingGoals).get(), hasLength(1));
      expect(settings.values['ratingDisplay'], 'number');
    });
  });

  group('deleteAllData', () {
    test('empties every table, the cover cache and the settings', () async {
      await seedEverything();

      await service.deleteAllData();

      for (final table in db.allTables) {
        expect(
          await db.select(table).get(),
          isEmpty,
          reason: '${table.actualTableName} must be empty',
        );
      }
      expect(covers.cachedPath('9783442719255'), isNull);
      expect(settings.values, isEmpty);
      expect(settings.theme, 'system');
      expect(settings.locale, 'de');
    });

    test('the database is usable afterwards and ids start over', () async {
      await seedEverything();
      await service.deleteAllData();

      expect(await addBook('Neu'), 1);
    });
  });

  group('SettingsRepositoryImpl.clearAll', () {
    test('forgets every stored preference', () async {
      SharedPreferences.setMockInitialValues({
        'settings.themeMode': 'dark',
        'settings.locale': 'en',
        'settings.ratingDisplay': 'number',
      });
      final repository = SettingsRepositoryImpl();

      await repository.clearAll();

      expect(await repository.getThemeMode(), 'system');
      expect(await repository.getLocaleCode(), 'de');
      expect(await repository.getValue('ratingDisplay'), isNull);
    });
  });
}
