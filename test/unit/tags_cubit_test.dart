import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/data/database/daos/tags_dao.dart';
import 'package:openreads/data/repositories/tag_repository_impl.dart';
import 'package:openreads/features/tags/tags_cubit.dart';

void main() {
  late AppDatabase db;
  late TagRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TagRepositoryImpl(TagsDao(db));
  });
  tearDown(() => db.close());

  test('create/rename/delete report precise results', () async {
    final cubit = TagsCubit(repo)..load();
    addTearDown(cubit.close);

    expect(await cubit.create('  '), isNull);
    final a = (await cubit.create('A'))!;
    final b = (await cubit.create('B'))!;
    expect(await cubit.rename(a, 'b'), TagResult.nameTaken);
    expect(await cubit.rename(a, ' '), TagResult.blank);
    expect(await cubit.rename(a, 'C'), TagResult.ok);

    final loaded = await cubit.stream.firstWhere(
      (s) =>
          s is TagsLoaded &&
          s.tags.map((t) => t.tag.name).toList().join() == 'BC',
    );
    expect((loaded as TagsLoaded).tags, hasLength(2));

    await cubit.delete(b);
    await cubit.stream.firstWhere((s) => s is TagsLoaded && s.tags.length == 1);
  });

  test('BookTagsCubit toggles and creates-and-assigns', () async {
    final bookId = await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            title: 'B',
            authors: const ['A'],
            editedFields: const [],
          ),
        );
    final cubit = BookTagsCubit(bookId, repo)..load();
    addTearDown(cubit.close);

    await cubit.createAndAssign('Neu');
    await cubit.stream.firstWhere((tags) => tags.length == 1);

    final tagId = cubit.state.single.id;
    await cubit.toggle(tagId);
    await cubit.stream.firstWhere((tags) => tags.isEmpty);

    await cubit.createAndAssign('   ');
    expect(await db.select(db.tags).get(), hasLength(1));
  });
}
