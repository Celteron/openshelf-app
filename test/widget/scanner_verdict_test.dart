import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/scan_verdict.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';
import 'package:openreads/domain/services/metadata_lookup_queue.dart';
import 'package:openreads/features/scanner/scanner_cubit.dart';
import 'package:openreads/features/scanner/scanner_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

class _NoRepo implements BookRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _SpyCubit extends ScannerCubit {
  final calls = <String>[];

  _SpyCubit()
    : super(
        _NoRepo(),
        MetadataLookupQueue(const MetadataAggregatorService([])),
      ) {
    emit(const ScannerActive(staged: []));
  }

  @override
  void start({StagedDefaults defaults = const StagedDefaults()}) {}

  void seed(ScanVerdict verdict, {bool failed = false}) => emit(
    (state as ScannerActive).copyWith(verdict: verdict, verdictFailed: failed),
  );

  @override
  Future<void> addVerdictToStaged() async => calls.add('add');

  @override
  Future<void> addVerdictToWishlist() async => calls.add('wishlist');

  @override
  Future<void> moveVerdictToLibrary() async => calls.add('bought');
}

Book _book(String title, {BookStatus status = BookStatus.read}) => Book(
  id: 1,
  title: title,
  authors: const ['A'],
  status: status,
  rating: 4,
  isbn13: '9783866801929',
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late _SpyCubit cubit;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    cubit = _SpyCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<ScannerCubit>.value(
        value: cubit,
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ScannerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void verdictTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await body(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  verdictTest('an owned book says where it stands and what is missing', (
    tester,
  ) async {
    await pump(tester);
    cubit.seed(
      OwnedVerdict(
        '9783866801929',
        book: _book('Der Vorleser'),
        locationPath: 'Wohnzimmer › Regal 2 › Fach 3',
        series: const SeriesStanding(
          id: 1,
          name: 'Krimi-Reihe',
          total: 6,
          missing: [4, 6],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Besitzt du'), findsOneWidget);
    expect(find.text('Der Vorleser'), findsOneWidget);
    expect(find.text('Wohnzimmer › Regal 2 › Fach 3'), findsOneWidget);
    expect(find.text('Krimi-Reihe: Bände 4, 6 fehlen'), findsOneWidget);
  });

  verdictTest('a complete series says so; a book without place says so', (
    tester,
  ) async {
    await pump(tester);
    cubit.seed(
      OwnedVerdict(
        '9783866801929',
        book: _book('Band 6'),
        series: const SeriesStanding(id: 1, name: 'Reihe', total: 6),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kein Standort'), findsOneWidget);
    expect(find.text('Reihe: komplett (6 Bände)'), findsOneWidget);
  });

  verdictTest('a new book offers add and wishlist', (tester) async {
    await pump(tester);
    cubit.seed(
      const NewVerdict(
        '9780306406157',
        metadata: BookMetadata(title: 'Neuer Roman'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noch nicht in der Bibliothek'), findsOneWidget);
    expect(find.text('Neuer Roman'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('verdict-add')));
    await tester.tap(find.byKey(const ValueKey('verdict-wishlist')));
    expect(cubit.calls, ['add', 'wishlist']);
  });

  verdictTest('a wishlist book can be marked as bought', (tester) async {
    await pump(tester);
    cubit.seed(
      WishlistVerdict(
        '9783866801929',
        book: _book('Wunsch', status: BookStatus.wishlist),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auf deiner Wunschliste'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('verdict-bought')));
    expect(cubit.calls, ['bought']);
  });

  verdictTest('a trashed book says so', (tester) async {
    await pump(tester);
    cubit.seed(const TrashedVerdict('9783866801929'));
    await tester.pumpAndSettle();

    expect(find.text('Liegt im Papierkorb'), findsOneWidget);
  });

  verdictTest('the close button hides the card', (tester) async {
    await pump(tester);
    cubit.seed(const TrashedVerdict('9783866801929'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('verdict-dismiss')));
    await tester.pumpAndSettle();

    expect(find.text('Liegt im Papierkorb'), findsNothing);
  });

  verdictTest('the shop chip switches lookup mode on and off', (tester) async {
    await pump(tester);
    bool lookupOnly() => (cubit.state as ScannerActive).lookupOnly;

    await tester.tap(find.byKey(const ValueKey('scan-lookup-mode')));
    await tester.pumpAndSettle();
    expect(lookupOnly(), isTrue);

    await tester.tap(find.byKey(const ValueKey('scan-lookup-mode')));
    await tester.pumpAndSettle();
    expect(lookupOnly(), isFalse);
  });

  verdictTest('a failed save shows on the card, which stays', (tester) async {
    await pump(tester);
    cubit.seed(const NewVerdict('9780306406157'), failed: true);
    await tester.pumpAndSettle();

    expect(
      find.text('Speichern fehlgeschlagen. Bitte noch einmal versuchen.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('verdict-wishlist')), findsOneWidget);
  });
}
