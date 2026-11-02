import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/shelf_wall.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/domain/services/shelf_search.dart';
import 'package:rxdart/rxdart.dart';

sealed class ShelfWallState {
  const ShelfWallState();
}

class ShelfWallLoading extends ShelfWallState {
  const ShelfWallLoading();
}

class ShelfWallLoaded extends ShelfWallState {
  final ShelfWall wall;

  /// What "find it" looks for; empty when it is off.
  final String query;

  /// Ids of the spines that match [query], in the order of the wall.
  final List<int> hits;

  /// The hit the view scrolls to; `null` without hits.
  final int? focusedBookId;

  /// Slipcases shown open, as their volumes.
  final Set<int> expanded;

  const ShelfWallLoaded(
    this.wall, {
    this.query = '',
    this.hits = const [],
    this.focusedBookId,
    this.expanded = const {},
  });

  bool get isSearching => query.trim().isNotEmpty;
}

class ShelfWallError extends ShelfWallState {
  const ShelfWallError();
}

/// A book that was moved, with where it stood before, so it can be undone.
typedef ShelfMove = ({int bookId, int? from, int? to});

/// Keeps the shelf wall in step with the books and the locations.
class ShelfWallCubit extends Cubit<ShelfWallState> {
  final BookRepository _books;
  final LocationRepository _locations;
  StreamSubscription<Object?>? _subscription;
  ShelfWall? _wall;
  String _query = '';
  int? _focus;
  final _expanded = <int>{};

  ShelfWallCubit(this._books, this._locations)
    : super(const ShelfWallLoading());

  void load() {
    _subscription?.cancel();
    _subscription =
        Rx.combineLatest2(
              _locations.watchLocations(),
              _books.watchBooks(),
              ShelfWall.build,
            )
            // The first wall at once, a burst (one write per book while the
            // covers are searched) at most every 300 ms, ending on the last.
            .throttleTime(
              const Duration(milliseconds: 300),
              leading: true,
              trailing: true,
            )
            .listen((wall) {
              _wall = wall;
              _publish();
            }, onError: (_) => emit(const ShelfWallError()));
  }

  /// Marks the books that match [query] and focuses the first.
  void find(String query) {
    _query = query;
    _focus = null;
    _publish();
  }

  /// Puts the book (a slipcase for its volumes) in another place; `null`
  /// means "no location". Returns what was done, or `null` when the book is
  /// not on the wall or already stands there. Throws if saving fails; the
  /// wall then stays as it was.
  Future<ShelfMove?> moveBook(int bookId, int? locationId) async {
    final wall = _wall;
    final position = wall?.positionOf(bookId);
    if (wall == null || position == null) return null;
    final from = wall.rows[position.row].locationId;
    if (from == locationId) return null;
    await _books.bulkAssignLocation([bookId], locationId);
    return (bookId: bookId, from: from, to: locationId);
  }

  void toggleSlipcase(int bookId) {
    if (!_expanded.remove(bookId)) _expanded.add(bookId);
    _publish();
  }

  void nextHit() => _step(1);

  void previousHit() => _step(-1);

  void clearFind() => find('');

  void _step(int by) {
    final current = state;
    if (current is! ShelfWallLoaded || current.hits.isEmpty) return;
    final at = current.hits.indexOf(_focus ?? current.hits.first);
    _focus = current.hits[(at + by) % current.hits.length];
    _publish();
  }

  /// Recomputes the hits for the current wall and query, so a change in the
  /// library keeps an open search right. The focus stays where it was if that
  /// book is still a hit.
  void _publish() {
    final wall = _wall;
    if (wall == null) return;
    final hits = findOnShelf(wall, _query);
    _focus = hits.contains(_focus) ? _focus : hits.firstOrNull;
    // A hit inside a slipcase is only visible when the slipcase is open.
    final focus = _focus;
    if (focus != null && wall.isSlipcase(focus)) _expanded.add(focus);
    emit(
      ShelfWallLoaded(
        wall,
        query: _query,
        hits: hits,
        focusedBookId: _focus,
        expanded: {..._expanded},
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
