import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/books_dao.dart';
import 'package:openreads/data/importers/importers.dart';
import 'package:openreads/data/repositories/book_repository_impl.dart';
import 'package:openreads/domain/models/import.dart';
import 'package:openreads/domain/services/import_service.dart';
import 'package:openreads/features/importer/importer_cubit.dart';
import 'package:openreads/features/importer/importer_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

void main() {
  const csv =
      '"Titel";"Autor(en)";"ISBN";"Kaufpreis";"Lesestatus"\n'
      '"Buch";"Doe, Jane";"9783736315471";"9,99";"Gelesen"\n';

  late AppDatabase db;
  late ImporterCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cubit =
        ImporterCubit(
          ImportService(BookRepositoryImpl(BooksDao(db))),
          defaultImporters(),
        )..selectFile(
          const ImportFile(
            name: 'x.csv',
            content: csv,
            type: ImportFileType.csv,
          ),
        );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(value: cubit, child: const ImporterScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows every column with its sample value and mapping', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Format: Bookstats CSV'), findsOneWidget);
    for (final header in ['Titel', 'Autor(en)', 'ISBN', 'Kaufpreis']) {
      // The name also appears as the label of the field it is mapped to.
      expect(find.text(header), findsWidgets);
    }
    expect(find.text('9,99'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('import-run')))
          .onPressed,
      isNotNull,
      reason: 'the title is matched',
    );
    expect(find.byKey(const ValueKey('map:3')), findsOneWidget);
    expect(find.text('Nicht importieren'), findsWidgets);
  });

  testWidgets('choosing a field for a column updates the mapping', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('map:3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preis').last);
    await tester.pumpAndSettle();

    final price = (cubit.state as ImporterMapping).columns.singleWhere(
      (c) => c.header == 'Kaufpreis',
    );
    expect(price.field, 'price');
  });

  testWidgets('Importieren runs the import with the chosen mapping', (
    tester,
  ) async {
    await pump(tester);
    cubit.assign(3, 'price');
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await cubit.runImport();
    });
    await tester.pumpAndSettle();

    expect(find.text('Importiert: 1'), findsOneWidget);
    final book = await tester.runAsync(() => db.select(db.books).getSingle());
    expect(book!.priceCents, 999);
  });

  testWidgets('Importieren is disabled until a column is the title', (
    tester,
  ) async {
    cubit.selectFile(
      const ImportFile(
        name: 'x.csv',
        content: 'Wort;Zahl\nHallo;5\n',
        type: ImportFileType.csv,
      ),
    );
    await pump(tester);

    FilledButton button() =>
        tester.widget<FilledButton>(find.byKey(const ValueKey('import-run')));
    expect(button().onPressed, isNull);
    expect(
      find.text('Ordne mindestens eine Spalte dem Titel zu.'),
      findsOneWidget,
    );

    cubit.assign(0, 'title');
    await tester.pumpAndSettle();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('an unnamed column is shown by its number', (tester) async {
    cubit.selectFile(
      const ImportFile(
        name: 'x.csv',
        content: 'Titel;\nBuch;x\n',
        type: ImportFileType.csv,
      ),
    );
    await pump(tester);

    expect(find.text('Spalte 2'), findsOneWidget);
  });
}
