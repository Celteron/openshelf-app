import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';
import 'package:openreads/domain/services/metadata_lookup_queue.dart';
import 'package:openreads/features/common/widgets/book_cover.dart';
import 'package:openreads/features/scanner/scanner_cubit.dart';
import 'package:openreads/features/scanner/scanner_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

import '../helpers/test_images.dart';

class _NoRepo implements BookRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// A scanner whose staging shelf is pre-filled, so the test covers the shelf's
/// cover wiring without the lookup pipeline.
class _SeededCubit extends ScannerCubit {
  _SeededCubit(List<StagedBook> staged)
    : super(
        _NoRepo(),
        MetadataLookupQueue(const MetadataAggregatorService([])),
      ) {
    emit(ScannerActive(staged: staged));
  }

  @override
  void start() {}
}

void main() {
  late Directory dir;
  late CoverCacheService cache;
  var downloads = 0;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('staging_cover_test');
    downloads = 0;
    cache = CoverCacheService(
      baseDirectory: dir,
      client: MockClient((_) async {
        downloads++;
        return http.Response.bytes(
          testPng(),
          200,
          headers: {'content-type': 'image/jpeg'},
        );
      }),
    );
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  /// The camera preview only exists on Android/iOS; the staging shelf below it
  /// is what is under test. The override must be cleared inside the test body
  /// (Flutter checks it before tearDown runs).
  void shelfTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await body(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  StagedBook staged(String isbn, {String? cover, bool duplicate = false}) =>
      StagedBook(
        isbn,
        duplicate: duplicate,
        metadata: BookMetadata(title: 'Titel $isbn', coverUrl: cover),
      );

  Future<void> pumpShelf(WidgetTester tester, List<StagedBook> books) async {
    final cubit = _SeededCubit(books);
    addTearDown(cubit.close);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        RepositoryProvider<CoverCacheService>.value(
          value: cache,
          child: BlocProvider<ScannerCubit>.value(
            value: cubit,
            child: const MaterialApp(
              locale: Locale('de'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: ScannerScreen(),
            ),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        await tester.pump();
      }
    });
  }

  shelfTest('a staged book shows its downloaded cover', (tester) async {
    await pumpShelf(tester, [
      staged('9783257229530', cover: 'https://x/a.jpg'),
    ]);

    expect(find.text('Titel 9783257229530'), findsOneWidget);
    expect(
      find.byKey(ValueKey('cover-image:${dir.path}/covers/9783257229530.jpg')),
      findsOneWidget,
    );
    expect(downloads, 1);
  });

  shelfTest('a book without a cover URL shows the placeholder', (tester) async {
    await pumpShelf(tester, [staged('9783257229530')]);

    expect(find.byKey(const ValueKey('cover-placeholder')), findsOneWidget);
    expect(downloads, 0);
  });

  shelfTest('every staged book gets its own cover, cached by ISBN', (
    tester,
  ) async {
    await pumpShelf(tester, [
      staged('9783257229530', cover: 'https://x/a.jpg'),
      staged('9780441172719', cover: 'https://x/b.jpg'),
    ]);

    expect(find.byType(UrlCover), findsNWidgets(2));
    expect(cache.cachedPath('9783257229530'), isNotNull);
    expect(cache.cachedPath('9780441172719'), isNotNull);
    expect(downloads, 2);
  });

  shelfTest('an already owned book shows the warning, not a cover', (
    tester,
  ) async {
    await pumpShelf(tester, [
      staged('9783257229530', cover: 'https://x/a.jpg', duplicate: true),
    ]);

    expect(find.byIcon(Icons.warning), findsOneWidget);
    expect(find.byType(UrlCover), findsNothing);
    expect(downloads, 0);
  });

  shelfTest('the library cover later reuses the staged file', (tester) async {
    await pumpShelf(tester, [
      staged('9783257229530', cover: 'https://x/a.jpg'),
    ]);

    // BookCover keys by ISBN-13 too, so saving the book needs no new download.
    expect(cache.cachedPath('9783257229530'), isNotNull);
    expect(downloads, 1);
  });
}
