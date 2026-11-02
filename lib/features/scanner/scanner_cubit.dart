import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/core/helpers/isbn.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/services/metadata_lookup_queue.dart';

class StagedBook {
  final String isbn13;
  final BookMetadata? metadata;
  final bool duplicate;

  /// Fields the user changed in the staging editor; saved as user edits and
  /// kept when a lookup finishes later.
  final Set<String> edited;

  const StagedBook(
    this.isbn13, {
    this.metadata,
    this.duplicate = false,
    this.edited = const {},
  });
}

/// Values "save all" gives every staged book (FR-R2-12).
class StagedDefaults {
  final int? locationId;
  final BookFormat? format;
  final BookStatus status;
  final ReceivedAs? receivedAs;

  const StagedDefaults({
    this.locationId,
    this.format,
    this.status = BookStatus.unread,
    this.receivedAs,
  });
}

sealed class ScannerState {
  const ScannerState();
}

class ScannerIdle extends ScannerState {
  const ScannerIdle();
}

class ScannerActive extends ScannerState {
  final List<StagedBook> staged;
  final bool scanning;
  final bool saving;
  final StagedDefaults shared;

  /// The last "save all" failed (e.g. a location deleted meanwhile); the
  /// staged books are kept for another try.
  final bool saveFailed;

  const ScannerActive({
    required this.staged,
    this.scanning = false,
    this.saving = false,
    this.shared = const StagedDefaults(),
    this.saveFailed = false,
  });

  ScannerActive copyWith({
    List<StagedBook>? staged,
    bool? scanning,
    bool? saving,
    StagedDefaults? shared,
    bool? saveFailed,
  }) {
    return ScannerActive(
      staged: staged ?? this.staged,
      scanning: scanning ?? this.scanning,
      saving: saving ?? this.saving,
      shared: shared ?? this.shared,
      saveFailed: saveFailed ?? this.saveFailed,
    );
  }
}

/// Continuous-scan state machine (`idle | scanning | staging | saving`) with a
/// staging shelf and ISBN dedup (spec §6.2, US5).
class ScannerCubit extends Cubit<ScannerState> {
  final BookRepository _bookRepository;
  final MetadataLookupQueue _lookupQueue;

  ScannerCubit(this._bookRepository, this._lookupQueue)
    : super(const ScannerIdle());

  /// Starts scanning; a new batch begins with [defaults] (the format and
  /// status chosen in the settings), a running one keeps its shared values.
  void start({StagedDefaults defaults = const StagedDefaults()}) {
    final current = state;
    emit(
      current is ScannerActive
          ? current.copyWith(scanning: true)
          : ScannerActive(staged: const [], scanning: true, shared: defaults),
    );
  }

  void stop() {
    final current = state;
    if (current is ScannerActive) emit(current.copyWith(scanning: false));
  }

  /// Handles a decoded barcode; dedupes against staged and already-owned ISBNs.
  Future<void> onScanned(String rawIsbn) async {
    final isbn13 = normalizeIsbn(rawIsbn);
    final current = state;
    if (current is! ScannerActive || isbn13 == null) return;

    if (current.staged.any((s) => s.isbn13 == isbn13)) return;

    final owned = await _bookRepository.isbnExists(isbn13);
    if (owned) {
      emit(
        current.copyWith(
          staged: [...current.staged, StagedBook(isbn13, duplicate: true)],
        ),
      );
      return;
    }

    emit(current.copyWith(staged: [...current.staged, StagedBook(isbn13)]));

    final result = await _lookupQueue.enqueue(BookMetadata(isbn13: isbn13));
    _updateMetadata(isbn13, result.metadata);
  }

  void _updateMetadata(String isbn13, BookMetadata metadata) => _replace(
    isbn13,
    (s) => StagedBook(
      isbn13,
      metadata: _keepEdits(metadata, s.metadata, s.edited),
      edited: s.edited,
    ),
  );

  /// Takes the user's [metadata] for the [edited] fields of a staged book.
  void editStaged(String isbn13, BookMetadata metadata, Set<String> edited) =>
      _replace(
        isbn13,
        (s) => StagedBook(
          isbn13,
          metadata: _keepEdits(s.metadata ?? metadata, metadata, edited),
          edited: {...s.edited, ...edited},
        ),
      );

  void removeStaged(String isbn13) {
    final current = state;
    if (current is! ScannerActive) return;
    emit(
      current.copyWith(
        staged: [
          for (final s in current.staged)
            if (s.isbn13 != isbn13) s,
        ],
      ),
    );
  }

  void setShared(StagedDefaults shared) {
    final current = state;
    if (current is ScannerActive) emit(current.copyWith(shared: shared));
  }

  void _replace(String isbn13, StagedBook Function(StagedBook) update) {
    final current = state;
    if (current is! ScannerActive) return;
    emit(
      current.copyWith(
        staged: [
          for (final s in current.staged) s.isbn13 == isbn13 ? update(s) : s,
        ],
      ),
    );
  }

  /// [base] with the [edited] fields taken from [mine]: what the user typed
  /// beats a lookup (Constitution III.2). Covers the fields of the staging
  /// editor.
  static BookMetadata _keepEdits(
    BookMetadata base,
    BookMetadata? mine,
    Set<String> edited,
  ) {
    if (mine == null || edited.isEmpty) return base;
    T pick<T>(String field, T theirs, T own) =>
        edited.contains(field) ? own : theirs;
    return BookMetadata(
      isbn13: base.isbn13,
      isbn10: base.isbn10,
      title: pick('title', base.title, mine.title),
      subtitle: base.subtitle,
      authors: pick('authors', base.authors, mine.authors),
      publisher: pick('publisher', base.publisher, mine.publisher),
      publishedYear: pick(
        'publishedYear',
        base.publishedYear,
        mine.publishedYear,
      ),
      pageCount: pick('pageCount', base.pageCount, mine.pageCount),
      format: base.format,
      language: base.language,
      description: base.description,
      coverUrl: base.coverUrl,
      seriesName: base.seriesName,
      seriesVolume: base.seriesVolume,
    );
  }

  /// Persists all staged books with the [ScannerActive.shared] values and
  /// clears the staging shelf (US5.2/US5.3); the shared values stay for the
  /// next batch.
  Future<void> saveAll() async {
    final current = state;
    if (current is! ScannerActive) return;
    emit(current.copyWith(saving: true, saveFailed: false));
    final shared = current.shared;

    final companions = <BooksCompanion>[];
    for (final staged in current.staged) {
      if (staged.duplicate || staged.isbn13.isEmpty) continue;
      final meta = staged.metadata;
      companions.add(
        BooksCompanion.insert(
          title: (meta?.title != null && meta!.title!.isNotEmpty)
              ? meta.title!
              : staged.isbn13,
          authors: meta?.authors ?? const [],
          editedFields: staged.edited.toList(),
          isbn13: Value(staged.isbn13),
          subtitle: Value(meta?.subtitle),
          publisher: Value(meta?.publisher),
          publishedYear: Value(meta?.publishedYear),
          pageCount: Value(meta?.pageCount),
          language: Value(meta?.language),
          description: Value(meta?.description),
          coverUrl: Value(meta?.coverUrl),
          locationId: Value(shared.locationId),
          format: Value(shared.format),
          status: Value(shared.status),
          receivedAs: Value(shared.receivedAs),
        ),
      );
    }

    try {
      if (companions.isNotEmpty) {
        await _bookRepository.insertAll(companions);
      }
    } catch (_) {
      // Nothing is lost: the batch stays staged and the screen says so.
      final now = state;
      if (now is ScannerActive) {
        emit(now.copyWith(saving: false, saveFailed: true));
      }
      return;
    }

    emit(ScannerActive(staged: const [], shared: shared));
  }
}
