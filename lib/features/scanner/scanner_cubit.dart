import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/core/helpers/isbn.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/scan_verdict.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/services/ownership_checker.dart';
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

  /// "In the shop" mode: scans only answer "do I have it?" and stage nothing.
  final bool lookupOnly;

  /// The answer to the latest scan that has one worth showing; `null` when
  /// there is none or the user dismissed it.
  final ScanVerdict? verdict;

  /// Saving from the verdict card ("wishlist", "bought") failed; the card
  /// stays so the user can try again.
  final bool verdictFailed;

  const ScannerActive({
    required this.staged,
    this.scanning = false,
    this.saving = false,
    this.shared = const StagedDefaults(),
    this.saveFailed = false,
    this.lookupOnly = false,
    this.verdict,
    this.verdictFailed = false,
  });

  ScannerActive copyWith({
    List<StagedBook>? staged,
    bool? scanning,
    bool? saving,
    StagedDefaults? shared,
    bool? saveFailed,
    bool? lookupOnly,
    ScanVerdict? verdict,
    bool? verdictFailed,
    bool clearVerdict = false,
  }) {
    return ScannerActive(
      staged: staged ?? this.staged,
      scanning: scanning ?? this.scanning,
      saving: saving ?? this.saving,
      shared: shared ?? this.shared,
      saveFailed: saveFailed ?? this.saveFailed,
      lookupOnly: lookupOnly ?? this.lookupOnly,
      verdict: clearVerdict ? null : (verdict ?? this.verdict),
      // A new or cleared card starts without a failure.
      verdictFailed:
          verdictFailed ??
          (clearVerdict || verdict != null ? false : this.verdictFailed),
    );
  }
}

/// Continuous-scan state machine (`idle | scanning | staging | saving`) with a
/// staging shelf and ISBN dedup (spec §6.2, US5).
class ScannerCubit extends Cubit<ScannerState> {
  final BookRepository _bookRepository;
  final MetadataLookupQueue _lookupQueue;

  /// Counts scans, so a slow answer to an older scan never replaces the card
  /// of a newer one (two barcodes can arrive in one camera frame).
  int _latestScan = 0;

  /// Called once after a batch was saved, e.g. to look up the covers of the
  /// new books. Scanning and saving are the user actions behind that.
  final void Function()? _onBooksAdded;

  /// Answers "do I own this?" for a scan. Without it scans give no verdict
  /// and the "in the shop" mode does nothing.
  final OwnershipChecker? _ownership;

  ScannerCubit(
    this._bookRepository,
    this._lookupQueue, {
    OwnershipChecker? ownership,
    void Function()? onBooksAdded,
  }) : _ownership = ownership,
       _onBooksAdded = onBooksAdded,
       super(const ScannerIdle());

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

  /// Handles a decoded barcode. Capture mode stages new books and dedupes
  /// against staged and already-owned ISBNs; lookup mode ("in the shop")
  /// only answers whether the book is owned.
  Future<void> onScanned(String rawIsbn) async {
    final isbn13 = normalizeIsbn(rawIsbn);
    final current = state;
    if (current is! ScannerActive || isbn13 == null) return;
    final scan = ++_latestScan;

    if (current.lookupOnly) return _lookUp(isbn13, scan);

    if (current.staged.any((s) => s.isbn13 == isbn13)) return;

    final owned = await _bookRepository.isbnExists(isbn13);
    if (owned) {
      // Told apart from a new book by the verdict: where it stands, which
      // volumes are missing.
      final verdict = await _ownership?.check(isbn13);
      _emitActive(
        (s) => s.copyWith(
          staged: [...s.staged, StagedBook(isbn13, duplicate: true)],
          // `null` keeps the card the newer scan already shows.
          verdict: scan == _latestScan ? verdict : null,
        ),
      );
      return;
    }

    _emitActive(
      (s) => s.copyWith(
        staged: [...s.staged, StagedBook(isbn13)],
        clearVerdict: true,
      ),
    );
    await _lookUpInto(isbn13);
  }

  Future<void> _lookUpInto(String isbn13) async {
    final result = await _lookupQueue.enqueue(BookMetadata(isbn13: isbn13));
    _updateMetadata(isbn13, result.metadata);
  }

  /// Lookup mode: the verdict is the whole answer, nothing is staged.
  Future<void> _lookUp(String isbn13, int scan) async {
    final ownership = _ownership;
    if (ownership == null) return;
    final verdict = await ownership.check(isbn13);
    if (scan != _latestScan) return;
    _emitActive((s) => s.copyWith(verdict: verdict));
    if (verdict is! NewVerdict) return;

    final result = await _lookupQueue.enqueue(BookMetadata(isbn13: isbn13));
    // The user may have scanned on or dismissed the card meanwhile.
    _emitActive((s) {
      final shown = s.verdict;
      return shown is NewVerdict && shown.isbn13 == isbn13
          ? s.copyWith(verdict: NewVerdict(isbn13, metadata: result.metadata))
          : s;
    });
  }

  void setLookupOnly(bool value) =>
      _emitActive((s) => s.copyWith(lookupOnly: value, clearVerdict: true));

  void dismissVerdict() => _emitActive((s) => s.copyWith(clearVerdict: true));

  /// "Add" on a new book's verdict: stages it like a capture-mode scan.
  Future<void> addVerdictToStaged() async {
    final verdict = _verdictAs<NewVerdict>();
    if (verdict == null) return;
    final isbn13 = verdict.isbn13;
    final metadata = verdict.metadata;
    _emitActive(
      (s) => s.copyWith(
        staged: [
          ...s.staged.where((b) => b.isbn13 != isbn13),
          StagedBook(isbn13, metadata: metadata),
        ],
        clearVerdict: true,
      ),
    );
    if (metadata == null) await _lookUpInto(isbn13);
  }

  /// "Wishlist" on a new book's verdict: saves it as a wishlist book at once.
  Future<void> addVerdictToWishlist() async {
    final verdict = _verdictAs<NewVerdict>();
    if (verdict == null) return;
    final isbn13 = verdict.isbn13;
    // The card goes first: a second tap while this runs finds nothing to do.
    _emitActive((s) => s.copyWith(clearVerdict: true));
    final metadata =
        verdict.metadata ??
        (await _lookupQueue.enqueue(BookMetadata(isbn13: isbn13))).metadata;
    try {
      await _bookRepository.insertAll([
        _companion(
          isbn13,
          metadata,
          const {},
          const StagedDefaults(status: BookStatus.wishlist),
        ),
      ]);
    } catch (_) {
      // Back on screen with the failure, unless a newer scan has its card.
      _emitActive(
        (s) => s.verdict == null
            ? s.copyWith(
                verdict: NewVerdict(isbn13, metadata: metadata),
                verdictFailed: true,
              )
            : s,
      );
      return;
    }
    _onBooksAdded?.call();
  }

  /// "Bought" on a wishlist book's verdict: it joins the library.
  Future<void> moveVerdictToLibrary() async {
    final verdict = _verdictAs<WishlistVerdict>();
    if (verdict == null) return;
    try {
      await _bookRepository.updateStatus(verdict.book.id, BookStatus.unread);
    } catch (_) {
      _emitActive((s) => s.copyWith(verdictFailed: true));
      return;
    }
    _emitActive((s) => s.copyWith(clearVerdict: true));
  }

  /// The card on screen when it is a [T], else `null`.
  T? _verdictAs<T extends ScanVerdict>() {
    final current = state;
    return current is ScannerActive && current.verdict is T
        ? current.verdict as T
        : null;
  }

  /// Applies [update] to the running scan; a no-op when none runs. The state
  /// is read again here because lookups finish after the user moved on.
  void _emitActive(ScannerActive Function(ScannerActive) update) {
    final current = state;
    if (current is ScannerActive) emit(update(current));
  }

  /// The row for one scanned book. Without metadata the ISBN stands in as the
  /// title, so a failed lookup never loses the scan.
  static BooksCompanion _companion(
    String isbn13,
    BookMetadata? meta,
    Set<String> edited,
    StagedDefaults shared,
  ) => BooksCompanion.insert(
    title: (meta?.title != null && meta!.title!.isNotEmpty)
        ? meta.title!
        : isbn13,
    authors: meta?.authors ?? const [],
    editedFields: edited.toList(),
    isbn13: Value(isbn13),
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
  );

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
      companions.add(
        _companion(staged.isbn13, staged.metadata, staged.edited, shared),
      );
    }

    try {
      if (companions.isNotEmpty) {
        await _bookRepository.insertAll(companions);
        _onBooksAdded?.call();
      }
    } catch (_) {
      // Nothing is lost: the batch stays staged and the screen says so.
      final now = state;
      if (now is ScannerActive) {
        emit(now.copyWith(saving: false, saveFailed: true));
      }
      return;
    }

    emit(
      ScannerActive(
        staged: const [],
        shared: shared,
        lookupOnly: current.lookupOnly,
      ),
    );
  }
}
