import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/reading_stats.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:openreads/domain/services/reading_tracker_service.dart';

sealed class ReadingState {
  const ReadingState();
}

class ReadingLoading extends ReadingState {
  const ReadingLoading();
}

class ReadingLoaded extends ReadingState {
  final Book book;

  /// The running timer session, if any.
  final ReadingSession? active;

  /// Completed and running sessions, newest first.
  final List<ReadingSession> sessions;
  final ReadingStats stats;

  const ReadingLoaded({
    required this.book,
    required this.active,
    required this.sessions,
    required this.stats,
  });
}

class ReadingError extends ReadingState {
  const ReadingError();
}

/// Drives the reading-progress screen of one book: live timer, current page,
/// session history and reading speed (Phase 2, US-A).
class ReadingCubit extends Cubit<ReadingState> {
  final int bookId;
  final ReadingTrackerService _tracker;
  final ReadingRepository _reading;
  final BookRepository _books;

  List<ReadingSession> _sessions = const [];
  ReadingSession? _active;
  bool _sessionsSeen = false;
  bool _activeSeen = false;
  StreamSubscription<List<ReadingSession>>? _sessionsSub;
  StreamSubscription<ReadingSession?>? _activeSub;

  ReadingCubit({
    required this.bookId,
    required ReadingTrackerService tracker,
    required ReadingRepository readingRepository,
    required BookRepository bookRepository,
  }) : _tracker = tracker,
       _reading = readingRepository,
       _books = bookRepository,
       super(const ReadingLoading());

  void load() {
    _sessionsSub?.cancel();
    _activeSub?.cancel();
    _sessionsSub = _reading.watchSessions(bookId).listen((sessions) {
      _sessions = sessions;
      _sessionsSeen = true;
      _publish();
    }, onError: (_) => emit(const ReadingError()));
    _activeSub = _reading.watchActiveSession(bookId).listen((active) {
      _active = active;
      _activeSeen = true;
      _publish();
    }, onError: (_) => emit(const ReadingError()));
  }

  Future<void> _publish() async {
    if (!_sessionsSeen || !_activeSeen || isClosed) return;
    final book = await _books.getBook(bookId);
    if (isClosed) return;
    if (book == null) {
      emit(const ReadingError());
      return;
    }
    emit(
      ReadingLoaded(
        book: book,
        active: _active,
        sessions: _sessions,
        stats: ReadingStats.compute(_sessions),
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _publish();
    } catch (_) {
      if (!isClosed) emit(const ReadingError());
    }
  }

  Future<void> start() => _run(() => _tracker.start(bookId));

  Future<void> stop({int? endPage}) =>
      _run(() => _tracker.stop(bookId, endPage: endPage));

  Future<void> setPage(int page) =>
      _run(() => _tracker.setCurrentPage(bookId, page));

  Future<void> logSession({
    required DateTime startedAt,
    required Duration duration,
    required int startPage,
    required int endPage,
  }) => _run(
    () => _tracker.logManual(
      bookId,
      startedAt: startedAt,
      duration: duration,
      startPage: startPage,
      endPage: endPage,
    ),
  );

  Future<void> deleteSession(int sessionId) =>
      _run(() => _reading.deleteSession(sessionId));

  @override
  Future<void> close() async {
    await _sessionsSub?.cancel();
    await _activeSub?.cancel();
    return super.close();
  }
}
