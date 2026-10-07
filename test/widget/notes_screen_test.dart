import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/notes_repository.dart';
import 'package:openreads/features/notes/notes_cubit.dart';
import 'package:openreads/features/notes/notes_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';
import 'package:openreads/l10n/app_localizations_de.dart';

class FakeNotesRepository implements NotesRepository {
  final _controller = StreamController<List<BookNote>>.broadcast();
  final List<BookNote> notes;
  final added = <(NoteKind, String, int?)>[];
  final deleted = <int>[];

  FakeNotesRepository(this.notes);

  @override
  Stream<List<BookNote>> watchNotes(int bookId) async* {
    yield notes;
    yield* _controller.stream;
  }

  @override
  Future<List<BookNote>> getNotes(int bookId) async => notes;

  @override
  Future<int> addNote(
    int bookId, {
    required NoteKind kind,
    required String content,
    int? pageNumber,
  }) async {
    added.add((kind, content.trim(), pageNumber));
    return 1;
  }

  @override
  Future<void> updateNote(
    int id, {
    required NoteKind kind,
    required String content,
    int? pageNumber,
  }) async {}

  @override
  Future<void> deleteNote(int id) async => deleted.add(id);
}

BookNote note(int id, NoteKind kind, String content, {int? page}) => BookNote(
  id: id,
  bookId: 1,
  kind: kind,
  content: content,
  pageNumber: page,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<void> pump(WidgetTester tester, FakeNotesRepository repo) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => NotesCubit(1, repo)..load(),
        child: const NotesView(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('clipboard text: notes verbatim, quotes quoted with page', () {
    final l10n = AppLocalizationsDe();
    expect(noteClipboardText(l10n, note(1, NoteKind.note, 'Idee')), 'Idee');
    expect(
      noteClipboardText(l10n, note(2, NoteKind.quote, 'Zitat', page: 42)),
      '„Zitat“ (S. 42)',
    );
    expect(noteClipboardText(l10n, note(3, NoteKind.quote, 'Ohne')), '„Ohne“');
  });

  testWidgets('lists notes and quotes in separate tabs', (tester) async {
    await pump(
      tester,
      FakeNotesRepository([
        note(1, NoteKind.note, 'Meine Notiz'),
        note(2, NoteKind.quote, 'Ein Zitat', page: 7),
      ]),
    );

    expect(find.text('Meine Notiz'), findsOneWidget);
    expect(find.textContaining('Ein Zitat'), findsNothing);

    await tester.tap(find.text('Zitate'));
    await tester.pumpAndSettle();
    expect(find.text('„Ein Zitat“'), findsOneWidget);
    expect(find.text('S. 7'), findsOneWidget);
  });

  testWidgets('quick-copy puts the quote on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pump(
      tester,
      FakeNotesRepository([note(2, NoteKind.quote, 'Ein Zitat', page: 7)]),
    );
    await tester.tap(find.text('Zitate'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Kopieren'));
    await tester.pump();

    expect(copied, '„Ein Zitat“ (S. 7)');
    expect(find.text('In die Zwischenablage kopiert'), findsOneWidget);
  });

  testWidgets('adds a quote with a page number from the dialog', (
    tester,
  ) async {
    final repo = FakeNotesRepository(const []);
    await pump(tester, repo);

    await tester.tap(find.text('Zitate'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // The quote segment is pre-selected because the quotes tab is active.
    await tester.enterText(
      find.widgetWithText(TextField, 'Text'),
      'Neues Zitat',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Seite (optional)'),
      '12',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(repo.added, [(NoteKind.quote, 'Neues Zitat', 12)]);
  });

  testWidgets('empty tab shows the empty message', (tester) async {
    await pump(tester, FakeNotesRepository(const []));
    expect(find.text('Noch keine Einträge'), findsOneWidget);
  });
}
