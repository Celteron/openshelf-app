import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';
import 'package:openreads/domain/services/metadata_lookup_queue.dart';
import 'package:openreads/features/scanner/scanner_cubit.dart';
import 'package:openreads/features/scanner/scanner_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

class _NoRepo implements BookRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Locations implements LocationRepository {
  int asked = 0;

  @override
  Future<List<Location>> getLocations() async {
    asked++;
    return const [
      Location(id: 3, name: 'Regal', type: LocationType.shelf, sortOrder: 0),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _SeededCubit extends ScannerCubit {
  _SeededCubit(List<StagedBook> staged)
    : super(
        _NoRepo(),
        MetadataLookupQueue(const MetadataAggregatorService([])),
      ) {
    emit(ScannerActive(staged: staged));
  }

  @override
  void start({StagedDefaults defaults = const StagedDefaults()}) {}

  /// Lets a test put the cubit into any state, e.g. a failed save.
  void seed(ScannerState next) => emit(next);
}

/// Editing the staging shelf before saving (FR-R2-12).
void main() {
  const isbn = '9783257229530';

  late _Locations locations;

  Future<_SeededCubit> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final cubit = _SeededCubit([
      const StagedBook(
        isbn,
        metadata: BookMetadata(
          title: 'Der Vorleser',
          authors: ['Bernhard Schlink'],
          pageCount: 207,
        ),
      ),
    ]);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      RepositoryProvider<LocationRepository>.value(
        value: locations = _Locations(),
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
    await tester.pumpAndSettle();
    return cubit;
  }

  /// The camera preview only exists on Android/iOS.
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

  StagedBook only(ScannerCubit cubit) =>
      (cubit.state as ScannerActive).staged.single;

  shelfTest('a failed save says so; the books stay staged', (tester) async {
    final cubit = await pump(tester);
    final active = cubit.state as ScannerActive;

    cubit.seed(active.copyWith(saveFailed: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // snack bar in

    expect(
      find.text(
        'Speichern fehlgeschlagen. Prüfe den Standort und versuche es erneut.',
      ),
      findsOneWidget,
    );
    expect(find.text('Der Vorleser'), findsOneWidget);
  });

  shelfTest('a deleted shared location is dropped', (tester) async {
    final cubit = await pump(tester);
    cubit.setShared(const StagedDefaults(locationId: 999));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('staged-shared')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shared-apply')));
    await tester.pumpAndSettle();

    expect((cubit.state as ScannerActive).shared.locationId, isNull);
  });

  shelfTest('the shared summary reads the locations once, not per scan', (
    tester,
  ) async {
    final cubit = await pump(tester);
    cubit.setShared(const StagedDefaults(locationId: 3));
    await tester.pumpAndSettle();
    expect(find.textContaining('Regal'), findsOneWidget);
    final before = locations.asked;

    for (var i = 0; i < 3; i++) {
      cubit.seed((cubit.state as ScannerActive).copyWith(scanning: i.isEven));
      await tester.pumpAndSettle();
    }

    expect(locations.asked, before);
    expect(find.textContaining('Regal'), findsOneWidget);
  });

  shelfTest('a staged book shows title and author', (tester) async {
    await pump(tester);

    expect(find.text('Der Vorleser'), findsOneWidget);
    expect(find.text('Bernhard Schlink'), findsOneWidget);
  });

  shelfTest('tapping a staged book edits it before saving', (tester) async {
    final cubit = await pump(tester);

    await tester.tap(find.text('Der Vorleser'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('staged-edit-title')),
      'Der Vorleser (Schullektüre)',
    );
    await tester.tap(find.byKey(const ValueKey('staged-edit-save')));
    await tester.pumpAndSettle();

    expect(only(cubit).metadata!.title, 'Der Vorleser (Schullektüre)');
    expect(only(cubit).metadata!.pageCount, 207);
    expect(only(cubit).edited, {'title'}, reason: 'only what changed');
    expect(find.text('Der Vorleser (Schullektüre)'), findsOneWidget);
  });

  shelfTest('a staged book can be removed', (tester) async {
    final cubit = await pump(tester);

    await tester.tap(find.byKey(const ValueKey('staged-remove:$isbn')));
    await tester.pumpAndSettle();

    expect((cubit.state as ScannerActive).staged, isEmpty);
  });

  shelfTest('shared values are set once for the whole batch', (tester) async {
    final cubit = await pump(tester);

    await tester.tap(find.byKey(const ValueKey('staged-shared')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shared-status')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelesen').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shared-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shared-apply')));
    await tester.pumpAndSettle();

    final shared = (cubit.state as ScannerActive).shared;
    expect(shared.status, BookStatus.read);
    expect(shared.locationId, 3);
    // The shelf shows what will be applied.
    expect(find.textContaining('Gelesen'), findsOneWidget);
  });
}
