import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/features/trash/trash_cubit.dart';
import 'package:openreads/features/trash/trash_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

class FakeTrashRepo implements BookRepository {
  final _changes = StreamController<void>.broadcast();
  final List<Book> trashed;
  final restored = <int>[];
  final purged = <int>[];
  var emptied = 0;

  FakeTrashRepo(this.trashed);

  @override
  Stream<List<Book>> watchTrashedBooks() async* {
    yield [...trashed];
    await for (final _ in _changes.stream) {
      yield [...trashed];
    }
  }

  @override
  Future<void> restoreBook(int id) async {
    restored.add(id);
    trashed.removeWhere((b) => b.id == id);
    _changes.add(null);
  }

  @override
  Future<void> purgeBook(int id) async {
    purged.add(id);
    trashed.removeWhere((b) => b.id == id);
    _changes.add(null);
  }

  @override
  Future<int> emptyTrash() async {
    emptied++;
    final n = trashed.length;
    trashed.clear();
    _changes.add(null);
    return n;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book book(int id, String title) => Book(
  id: id,
  title: title,
  authors: const ['Autor'],
  status: BookStatus.unread,
  rating: 0,
  editedFields: const [],
  currentPage: 0,
  isFavorite: false,
  coverNotFound: false,
  deletedAt: DateTime(2026, 4, 1),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<FakeTrashRepo> pump(WidgetTester tester, List<Book> trashed) async {
  final repo = FakeTrashRepo(trashed);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => TrashCubit(repo),
        child: const TrashScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('shows a message when the trash is empty', (tester) async {
    await pump(tester, []);

    expect(find.byKey(const ValueKey('trash-empty')), findsOneWidget);
    expect(find.text('Der Papierkorb ist leer'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('empty-trash')))
          .onPressed,
      isNull,
      reason: 'nothing to empty',
    );
  });

  testWidgets('lists the trashed books', (tester) async {
    await pump(tester, [book(1, 'Eins'), book(2, 'Zwei')]);

    expect(find.text('Eins'), findsOneWidget);
    expect(find.text('Zwei'), findsOneWidget);
    expect(find.byKey(const ValueKey('trash-empty')), findsNothing);
  });

  testWidgets('restoring a book removes it from the list', (tester) async {
    final repo = await pump(tester, [book(1, 'Eins'), book(2, 'Zwei')]);

    await tester.tap(find.byKey(const ValueKey('restore:1')));
    await tester.pumpAndSettle();

    expect(repo.restored, [1]);
    expect(find.text('Eins'), findsNothing);
    expect(find.text('Zwei'), findsOneWidget);
  });

  testWidgets('deleting forever asks first', (tester) async {
    final repo = await pump(tester, [book(1, 'Eins')]);

    await tester.tap(find.byKey(const ValueKey('purge:1')));
    await tester.pumpAndSettle();
    expect(find.text('„Eins“ endgültig löschen?'), findsOneWidget);
    expect(find.textContaining('unwiderruflich'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(repo.purged, isEmpty);
    expect(find.text('Eins'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('purge:1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trash-confirm')));
    await tester.pumpAndSettle();

    expect(repo.purged, [1]);
    expect(find.text('Eins'), findsNothing);
    expect(find.text('Der Papierkorb ist leer'), findsOneWidget);
  });

  testWidgets('emptying the trash asks first and clears everything', (
    tester,
  ) async {
    final repo = await pump(tester, [book(1, 'Eins'), book(2, 'Zwei')]);

    await tester.tap(find.byKey(const ValueKey('empty-trash')));
    await tester.pumpAndSettle();
    expect(find.text('Papierkorb leeren?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(repo.emptied, 0);

    await tester.tap(find.byKey(const ValueKey('empty-trash')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trash-confirm')));
    await tester.pumpAndSettle();

    expect(repo.emptied, 1);
    expect(find.text('Der Papierkorb ist leer'), findsOneWidget);
  });
}
