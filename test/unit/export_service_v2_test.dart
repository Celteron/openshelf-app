import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/domain/models/enums.dart';

void main() {
  test('JSON export v2 contains Phase 2 data (Constitution I.3)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final bookId = await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            title: 'Buch',
            authors: const ['A'],
            editedFields: const [],
            currentPage: const Value(12),
            isFavorite: const Value(true),
            review: const Value('Stark'),
          ),
        );
    await db
        .into(db.readingSessions)
        .insert(
          ReadingSessionsCompanion.insert(
            bookId: bookId,
            startedAt: DateTime(2026, 1, 1, 20),
            endedAt: Value(DateTime(2026, 1, 1, 21)),
            durationSeconds: const Value(3600),
            endPage: const Value(12),
          ),
        );
    await db
        .into(db.bookNotes)
        .insert(
          BookNotesCompanion.insert(
            bookId: bookId,
            kind: NoteKind.quote,
            content: 'Zitat',
            pageNumber: const Value(3),
          ),
        );
    final tagId = await db
        .into(db.tags)
        .insert(TagsCompanion.insert(name: 'Krimi'));
    await db
        .into(db.bookTags)
        .insert(BookTagsCompanion.insert(bookId: bookId, tagId: tagId));
    await db
        .into(db.readingGoals)
        .insert(
          ReadingGoalsCompanion.insert(
            year: const Value(2026),
            targetBooks: 12,
            targetPages: const Value(4000),
          ),
        );

    final json =
        jsonDecode(await ExportService(db).exportJson())
            as Map<String, dynamic>;

    expect(json['version'], 2);
    expect((json['books'] as List).single['currentPage'], 12);
    expect((json['books'] as List).single['isFavorite'], isTrue);
    expect((json['books'] as List).single['review'], 'Stark');
    expect((json['readingSessions'] as List).single['durationSeconds'], 3600);
    expect((json['notes'] as List).single['kind'], 'quote');
    expect((json['tags'] as List).single['name'], 'Krimi');
    expect((json['bookTags'] as List).single['tagId'], tagId);
    expect((json['readingGoals'] as List).single['targetBooks'], 12);
    expect((json['readingGoals'] as List).single['targetPages'], 4000);
  });
}
