import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/repositories/book_repository.dart';

class CoverSyncResult {
  /// Books that were looked up (a cover URL or ISBN but no local file).
  final int total;
  final int downloaded;

  /// Books no source has a cover for: found now, or known from earlier runs
  /// (those are skipped and not part of [total]).
  final int notFound;

  /// Books whose sources could not be reached (offline, timeout, 429, 5xx).
  final int failed;

  const CoverSyncResult({
    required this.total,
    required this.downloaded,
    required this.notFound,
    required this.failed,
  });
}

/// Downloads the covers that are known by URL but missing on this device
/// (Openreads "download missing covers"), e.g. after an import or a restore.
class CoverSyncService {
  final BookRepository _books;
  final CoverCacheService _covers;

  CoverSyncService(this._books, this._covers);

  /// Cache key of a book: its ISBN-13, else its id.
  static String keyFor(Book book) => book.isbn13 ?? 'book-${book.id}';

  Future<CoverSyncResult> downloadMissing({
    void Function(int done, int total)? onProgress,
  }) async {
    var knownMissing = 0;
    final missing = <Book>[];
    for (final book in await _books.getAllBooks()) {
      if (((book.coverUrl ?? '').isEmpty && book.isbn13 == null) ||
          _covers.exists(book.coverLocalPath)) {
        continue;
      }
      // Asked before and every source said no: the per-book online search is
      // the way to retry, not this bulk run.
      if (book.coverNotFound) {
        knownMissing++;
      } else {
        missing.add(book);
      }
    }

    var done = 0;
    var downloaded = 0;
    var notFound = 0;
    var failed = 0;
    for (final book in missing) {
      final result = await _covers.findAny(
        keyFor(book),
        coverCandidates(coverUrl: book.coverUrl, isbn: book.isbn13),
      );
      switch (result) {
        case CoverFound(:final path):
          await _books.setCoverLocalPath(book.id, path);
          downloaded++;
        case CoverMissing():
          await _books.setCoverNotFound(book.id);
          notFound++;
        case CoverUnavailable():
          failed++;
      }
      onProgress?.call(++done, missing.length);
    }
    return CoverSyncResult(
      total: missing.length,
      downloaded: downloaded,
      notFound: notFound + knownMissing,
      failed: failed,
    );
  }
}
