import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/database/daos/locations_dao.dart';
import 'package:openreads/data/database/daos/series_dao.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/data/repositories/location_repository_impl.dart';
import 'package:openreads/data/repositories/series_repository_impl.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/scan_verdict.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';
import 'package:openreads/domain/services/metadata_lookup_queue.dart';
import 'package:openreads/domain/services/ownership_checker.dart';
import 'package:openreads/features/scanner/scanner_cubit.dart';

class _FakeSource implements MetadataSourceStrategy {
  @override
  MetadataSource get id => MetadataSource.dnb;

  @override
  Future<BookMetadata?> lookupByIsbn(String isbn13) async => BookMetadata(
    title: 'Title $isbn13',
    authors: const ['Autorin'],
    isbn13: isbn13,
  );
}

/// Fails on demand, like a full disk or a locked database.
class _FlakyBooks extends BookRepositoryImpl {
  bool failing = false;
  int inserts = 0;
  _FlakyBooks(super.dao);

  @override
  Future<int> insertAll(List<BooksCompanion> books) async {
    inserts++;
    // A slow write: a second tap can arrive before it ends.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (failing) throw StateError('disk full');
    return super.insertAll(books);
  }
}

/// Answers each ISBN when the test says so.
class _GatedChecker extends OwnershipChecker {
  final gates = <String, Completer<ScanVerdict>>{};

  _GatedChecker(super.books, super.locations, super.series);

  @override
  Future<ScanVerdict> check(String isbn13) =>
      (gates[isbn13] ??= Completer<ScanVerdict>()).future;
}

void main() {
  const owned = '9783866801929';
  const fresh = '9780306406157';

  late AppDatabase db;
  late BookRepositoryImpl books;
  late ScannerCubit cubit;
  var added = 0;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    books = BookRepositoryImpl(BooksDao(db));
    added = 0;
    await books.insertBook(
      BooksCompanion.insert(
        title: 'Der Vorleser',
        authors: const ['A'],
        editedFields: const [],
        isbn13: const Value(owned),
      ),
    );
    cubit = ScannerCubit(
      books,
      MetadataLookupQueue(
        MetadataAggregatorService([_FakeSource()]),
        minInterval: Duration.zero,
      ),
      ownership: OwnershipChecker(
        books,
        LocationRepositoryImpl(LocationsDao(db)),
        SeriesRepositoryImpl(SeriesDao(db)),
      ),
      onBooksAdded: () => added++,
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  ScannerActive active() => cubit.state as ScannerActive;

  group('capture mode (default)', () {
    test(
      'an owned book answers with its verdict and the warning row',
      () async {
        cubit.start();
        await cubit.onScanned(owned);

        expect(active().verdict, isA<OwnedVerdict>());
        expect(active().staged.single.duplicate, isTrue);
      },
    );

    test('a new book is staged and needs no verdict banner', () async {
      cubit.start();
      await cubit.onScanned(fresh);

      expect(active().verdict, isNull);
      expect(active().staged.single.isbn13, fresh);
    });
  });

  group('lookup mode ("Im Laden")', () {
    setUp(() => cubit.start());

    test('stages nothing, but still answers for an owned book', () async {
      cubit.setLookupOnly(true);
      await cubit.onScanned(owned);

      expect(active().staged, isEmpty);
      expect(active().verdict, isA<OwnedVerdict>());
    });

    test('a new book gets a verdict with its looked-up title', () async {
      cubit.setLookupOnly(true);
      await cubit.onScanned(fresh);

      final verdict = active().verdict;
      expect(active().staged, isEmpty);
      expect(verdict, isA<NewVerdict>());
      expect((verdict as NewVerdict).metadata?.title, 'Title $fresh');
    });

    test('scanning the same book twice answers twice', () async {
      cubit.setLookupOnly(true);
      await cubit.onScanned(owned);
      cubit.dismissVerdict();
      expect(active().verdict, isNull);

      await cubit.onScanned(owned);

      expect(active().verdict, isA<OwnedVerdict>());
    });

    test('"add" stages the book and clears the verdict', () async {
      cubit.setLookupOnly(true);
      await cubit.onScanned(fresh);

      await cubit.addVerdictToStaged();

      expect(active().verdict, isNull);
      expect(active().staged.single.isbn13, fresh);
    });

    test('"wishlist" saves the book as wishlist and starts the cover '
        'search', () async {
      cubit.setLookupOnly(true);
      await cubit.onScanned(fresh);

      await cubit.addVerdictToWishlist();

      final saved = (await books.getAllBooks()).singleWhere(
        (b) => b.isbn13 == fresh,
      );
      expect(saved.status, BookStatus.wishlist);
      expect(saved.title, 'Title $fresh');
      expect(active().verdict, isNull);
      expect(added, 1);
    });

    test('a wishlist book can be bought: it moves to the library', () async {
      cubit.setLookupOnly(true);
      await cubit.onScanned(fresh);
      await cubit.addVerdictToWishlist();
      await cubit.onScanned(fresh);
      expect(active().verdict, isA<WishlistVerdict>());

      await cubit.moveVerdictToLibrary();

      final saved = (await books.getAllBooks()).singleWhere(
        (b) => b.isbn13 == fresh,
      );
      expect(saved.status, BookStatus.unread);
      expect(active().verdict, isNull);
    });
  });

  test('without an ownership checker nothing changes', () async {
    final plain = ScannerCubit(
      books,
      MetadataLookupQueue(
        MetadataAggregatorService([_FakeSource()]),
        minInterval: Duration.zero,
      ),
    );
    addTearDown(plain.close);
    plain.start();
    await plain.onScanned(owned);

    expect((plain.state as ScannerActive).verdict, isNull);
  });

  group('robustness', () {
    late _FlakyBooks flaky;
    late ScannerCubit shop;

    setUp(() {
      flaky = _FlakyBooks(BooksDao(db));
      shop = ScannerCubit(
        flaky,
        MetadataLookupQueue(
          MetadataAggregatorService([_FakeSource()]),
          minInterval: Duration.zero,
        ),
        ownership: OwnershipChecker(
          flaky,
          LocationRepositoryImpl(LocationsDao(db)),
          SeriesRepositoryImpl(SeriesDao(db)),
        ),
        onBooksAdded: () => added++,
      )..start();
      shop.setLookupOnly(true);
    });

    tearDown(() => shop.close());

    ScannerActive now() => shop.state as ScannerActive;

    test('a double tap on "wishlist" saves the book once', () async {
      await shop.onScanned(fresh);

      await Future.wait([
        shop.addVerdictToWishlist(),
        shop.addVerdictToWishlist(),
      ]);

      expect(flaky.inserts, 1);
      expect(now().saveFailed, isFalse);
      expect(added, 1);
    });

    test(
      'a failed save brings the card back, with the failure shown',
      () async {
        await shop.onScanned(fresh);
        flaky.failing = true;

        await shop.addVerdictToWishlist();

        expect(now().verdict, isA<NewVerdict>());
        expect(now().verdictFailed, isTrue);
        expect(
          now().saveFailed,
          isFalse,
          reason: 'that flag is for "save all"',
        );
        expect(added, 0);

        flaky.failing = false;
        await shop.addVerdictToWishlist();
        expect(now().verdict, isNull);
        expect(now().verdictFailed, isFalse);
        expect(added, 1);
      },
    );

    test('the card of the newest scan wins, whatever answers first', () async {
      final checker = _GatedChecker(
        flaky,
        LocationRepositoryImpl(LocationsDao(db)),
        SeriesRepositoryImpl(SeriesDao(db)),
      );
      final racing = ScannerCubit(
        flaky,
        MetadataLookupQueue(
          MetadataAggregatorService([_FakeSource()]),
          minInterval: Duration.zero,
        ),
        ownership: checker,
      )..start();
      addTearDown(racing.close);
      racing.setLookupOnly(true);

      final older = racing.onScanned(owned);
      final newer = racing.onScanned(fresh);
      checker.gates[fresh]!.complete(const NewVerdict(fresh));
      await newer;
      checker.gates[owned]!.complete(const TrashedVerdict(owned));
      await older;

      expect((racing.state as ScannerActive).verdict?.isbn13, fresh);
    });
  });
}
