import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/export/export_file_saver.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/data/importers/importers.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';
import 'package:openreads/features/importer/import_export_screen.dart';
import 'package:openreads/features/importer/importer_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

class _ImportService extends Fake implements ImportService {}

class _Export extends Fake implements ExportService {
  Object? error;

  @override
  Future<String> exportJson() async {
    if (error != null) throw error!;
    return '{"books":[]}';
  }

  @override
  Future<String> exportBooksCsv() async => 'Titel\n';
}

class _Saver implements ExportFileSaver {
  final saved = <String, String>{};
  String? result = '/storage/Download/export';
  Object? error;

  @override
  Future<String?> save(String fileName, String content) async {
    if (error != null) throw error!;
    saved[fileName] = content;
    return result;
  }
}

/// The combined import/export screen (spec 004 FR-R2-04/05).
void main() {
  late ImporterCubit cubit;
  late _Saver saver;
  late _Export export;

  setUp(() {
    cubit = ImporterCubit(_ImportService(), const []);
    saver = _Saver();
    export = _Export();
  });
  tearDown(() => cubit.close());

  /// Opens the screen from a start page, like Settings does.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ExportService>.value(value: export),
          RepositoryProvider<ExportFileSaver>.value(value: saver),
        ],
        child: BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImportExportScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  const result = ImportResult(imported: 5, updated: 2, skipped: 0, errors: []);

  testWidgets('offers import and export on one screen', (tester) async {
    await pump(tester);

    expect(find.byKey(const ValueKey('import-choose-file')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-json')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-csv')), findsOneWidget);
  });

  testWidgets('a running import shows rows done out of the total', (
    tester,
  ) async {
    await pump(tester);
    cubit.emit(const ImporterImporting(2, 8));
    await tester.pumpAndSettle();

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.25);
    expect(find.text('2 von 8 Zeilen'), findsOneWidget);
  });

  testWidgets('a finished import says so and can start a new one', (
    tester,
  ) async {
    await pump(tester);
    cubit.emit(const ImporterDone(result));
    await tester.pumpAndSettle();

    expect(find.text('Import abgeschlossen'), findsOneWidget);
    expect(find.text('Importiert: 5'), findsOneWidget);

    await tapKey(tester, 'import-again');

    expect(cubit.state, isA<ImporterSelecting>());
    expect(find.byKey(const ValueKey('import-choose-file')), findsOneWidget);
  });

  testWidgets('a failed import shows the error and can start again', (
    tester,
  ) async {
    await pump(tester);
    cubit.emit(const ImporterError(ImportFailure.failed, 'disk full'));
    await tester.pumpAndSettle();

    expect(find.text('Import fehlgeschlagen'), findsOneWidget);
    expect(find.text('Der Import wurde abgebrochen.'), findsOneWidget);
    expect(find.textContaining('disk full'), findsOneWidget, reason: 'detail');

    await tapKey(tester, 'import-again');
    expect(cubit.state, isA<ImporterSelecting>());
  });

  testWidgets('an unknown file format is explained in German', (tester) async {
    await pump(tester);
    cubit.selectFile(
      const ImportFile(name: 'x.txt', content: 'x', type: ImportFileType.csv),
    );
    await tester.pumpAndSettle();

    expect(find.text('Das Dateiformat wird nicht erkannt.'), findsOneWidget);
    expect(find.textContaining('Unsupported'), findsNothing);
  });

  testWidgets('leaving the matcher starts the next visit fresh', (
    tester,
  ) async {
    await pump(tester);
    cubit.emit(
      ImporterMapping(
        const ImportFile(name: 'x.csv', content: '', type: ImportFileType.csv),
        defaultImporters().first,
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(cubit.state, isA<ImporterSelecting>());
  });

  testWidgets('"Done" closes the screen and the next visit starts fresh', (
    tester,
  ) async {
    await pump(tester);
    cubit.emit(const ImporterDone(result));
    await tester.pumpAndSettle();

    await tapKey(tester, 'import-done');

    expect(find.byType(ImportExportScreen), findsNothing);
    expect(cubit.state, isA<ImporterSelecting>());
  });

  testWidgets('leaving during an import keeps it running', (tester) async {
    await pump(tester);
    cubit.emit(const ImporterImporting(1, 8));
    await tester.pumpAndSettle();

    // System back, as on a phone.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(ImportExportScreen), findsNothing);
    expect(cubit.state, isA<ImporterImporting>());
  });

  group('export', () {
    testWidgets('hands the JSON backup to the saver and names the place', (
      tester,
    ) async {
      await pump(tester);
      await tapKey(tester, 'export-json');

      expect(saver.saved, {'openshelf_export.json': '{"books":[]}'});
      expect(
        find.text('Exportiert nach: /storage/Download/export'),
        findsOneWidget,
      );
    });

    testWidgets('hands the CSV to the saver', (tester) async {
      await pump(tester);
      await tapKey(tester, 'export-csv');

      expect(saver.saved, {'openshelf_books.csv': 'Titel\n'});
    });

    testWidgets('a cancelled save dialog shows nothing', (tester) async {
      saver.result = null;
      await pump(tester);
      await tapKey(tester, 'export-json');

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a failing export says so instead of crashing', (tester) async {
      export.error = StateError('db closed');
      await pump(tester);
      await tapKey(tester, 'export-json');

      expect(find.text('Export fehlgeschlagen'), findsOneWidget);
      expect(saver.saved, isEmpty);
    });

    testWidgets('a failing save says so instead of crashing', (tester) async {
      saver.error = const FileSystemException('denied');
      await pump(tester);
      await tapKey(tester, 'export-json');

      expect(find.text('Export fehlgeschlagen'), findsOneWidget);
    });
  });
}
