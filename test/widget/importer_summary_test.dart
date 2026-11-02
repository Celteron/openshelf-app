import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';
import 'package:openreads/features/importer/importer_cubit.dart';
import 'package:openreads/features/importer/import_export_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

class _FakeImportService implements ImportService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> pumpSummary(WidgetTester tester, ImportResult result) async {
  final cubit = ImporterCubit(_FakeImportService(), const [])
    ..emit(ImporterDone(result));
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider.value(value: cubit, child: const ImportExportScreen()),
    ),
  );
}

void main() {
  testWidgets('the summary reports new, updated, skipped and duplicates', (
    tester,
  ) async {
    await pumpSummary(
      tester,
      const ImportResult(
        imported: 5,
        updated: 3,
        skipped: 9,
        duplicates: 8,
        errors: [RowError(rowNumber: 4, reason: 'Missing title')],
      ),
    );

    expect(find.text('Importiert: 5'), findsOneWidget);
    expect(find.text('Aktualisiert: 3'), findsOneWidget);
    expect(find.text('Übersprungen: 9'), findsOneWidget);
    expect(find.text('Davon bereits vorhandene Duplikate: 8'), findsOneWidget);
    expect(find.textContaining('Missing title'), findsOneWidget);
  });

  testWidgets('the duplicate line is hidden when there are none', (
    tester,
  ) async {
    await pumpSummary(
      tester,
      const ImportResult(imported: 1, skipped: 0, errors: []),
    );

    expect(find.textContaining('Duplikate'), findsNothing);
    expect(find.text('Aktualisiert: 0'), findsOneWidget);
  });
}
