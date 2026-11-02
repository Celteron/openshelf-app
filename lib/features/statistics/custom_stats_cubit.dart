import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/models/stat_tile.dart';
import 'package:openreads/domain/models/tag_with_count.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:openreads/domain/repositories/stat_tile_repository.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/domain/services/stat_query.dart';
import 'package:rxdart/rxdart.dart';

sealed class CustomStatsState {
  const CustomStatsState();
}

class CustomStatsLoading extends CustomStatsState {
  const CustomStatsLoading();
}

class CustomStatsLoaded extends CustomStatsState {
  final List<EvaluatedTile> tiles;

  /// The data behind [tiles]; the builder previews a definition with it.
  final StatLibrary library;

  const CustomStatsLoaded(this.tiles, this.library);
}

class CustomStatsError extends CustomStatsState {
  const CustomStatsError();
}

class EvaluatedTile {
  final StatTile tile;
  final StatResult result;
  const EvaluatedTile(this.tile, this.result);
}

/// Keeps the user-defined statistic tiles evaluated over the live library
/// (spec 005): any change to books, sessions, tags, locations or tiles
/// recomputes them.
class CustomStatsCubit extends Cubit<CustomStatsState> {
  final StatTileRepository _tiles;
  final BookRepository _books;
  final ReadingRepository? _reading;
  final TagRepository? _tags;
  final LocationRepository? _locations;
  StreamSubscription<CustomStatsState>? _subscription;

  CustomStatsCubit({
    required StatTileRepository tiles,
    required BookRepository books,
    ReadingRepository? reading,
    TagRepository? tags,
    LocationRepository? locations,
  }) : _tiles = tiles,
       _books = books,
       _reading = reading,
       _tags = tags,
       _locations = locations,
       super(const CustomStatsLoading());

  void load() {
    _subscription?.cancel();
    _subscription =
        Rx.combineLatest6<
              List<StatTile>,
              List<Book>,
              List<ReadingSession>,
              Map<int, Set<int>>,
              List<TagWithCount>,
              List<Location>,
              CustomStatsState
            >(
              _tiles.watchTiles(),
              _books.watchBooks(),
              _reading?.watchAllSessions() ?? Stream.value(const []),
              _tags?.watchTagsByBook() ?? Stream.value(const {}),
              _tags?.watchTags() ?? Stream.value(const []),
              _locations?.watchLocations() ?? Stream.value(const []),
              (tiles, books, sessions, tagsByBook, tags, locations) {
                final library = StatLibrary(
                  books: books,
                  sessions: sessions,
                  tagsByBook: tagsByBook,
                  tagNames: {for (final t in tags) t.tag.id: t.tag.name},
                  locationNames: {for (final l in locations) l.id: l.name},
                );
                return CustomStatsLoaded([
                  for (final tile in tiles)
                    EvaluatedTile(tile, library.evaluate(tile.definition)),
                ], library);
              },
            )
            .listen(emit, onError: (_) => emit(const CustomStatsError()));
  }

  Future<int> addTile(String title, StatDefinition definition) =>
      _tiles.addTile(title, definition);

  Future<void> updateTile(
    int id, {
    String? title,
    StatDefinition? definition,
  }) => _tiles.updateTile(id, title: title, definition: definition);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
