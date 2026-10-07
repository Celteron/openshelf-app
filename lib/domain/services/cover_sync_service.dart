import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/repositories/book_repository.dart';

class CoverSyncResult {
  /// Books that had a cover URL but no local file.
  final int total;
  final int downloaded;
  final int failed;

  const CoverSyncResult({
    required this.total,
    required this.downloaded,
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
    final missing = [
      for (final book in await _books.getAllBooks())
        if ((book.coverUrl ?? '').isNotEmpty &&
            !_covers.exists(book.coverLocalPath))
          book,
    ];

    var done = 0;
    var downloaded = 0;
    for (final book in missing) {
      final path = await _covers.resolve(keyFor(book), book.coverUrl);
      if (path != null) {
        await _books.setCoverLocalPath(book.id, path);
        downloaded++;
      }
      onProgress?.call(++done, missing.length);
    }
    return CoverSyncResult(
      total: missing.length,
      downloaded: downloaded,
      failed: missing.length - downloaded,
    );
  }
}
