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

  const StagedBook(this.isbn13, {this.metadata, this.duplicate = false});
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

  const ScannerActive({
    required this.staged,
    this.scanning = false,
    this.saving = false,
  });

  ScannerActive copyWith({
    List<StagedBook>? staged,
    bool? scanning,
    bool? saving,
  }) {
    return ScannerActive(
      staged: staged ?? this.staged,
      scanning: scanning ?? this.scanning,
      saving: saving ?? this.saving,
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

  void start() {
    final current = state;
    emit(
      ScannerActive(
        staged: current is ScannerActive ? current.staged : const [],
        scanning: true,
      ),
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

  void _updateMetadata(String isbn13, BookMetadata metadata) {
    final current = state;
    if (current is! ScannerActive) return;
    emit(
      current.copyWith(
        staged: current.staged
            .map(
              (s) => s.isbn13 == isbn13
                  ? StagedBook(isbn13, metadata: metadata)
                  : s,
            )
            .toList(),
      ),
    );
  }

  /// Persists all staged books (with an optional bulk location assignment) and
  /// clears the staging shelf (US5.2/US5.3).
  Future<void> saveAll({int? locationId}) async {
    final current = state;
    if (current is! ScannerActive) return;
    emit(current.copyWith(saving: true));

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
          editedFields: const [],
          isbn13: Value(staged.isbn13),
          subtitle: Value(meta?.subtitle),
          publisher: Value(meta?.publisher),
          publishedYear: Value(meta?.publishedYear),
          pageCount: Value(meta?.pageCount),
          language: Value(meta?.language),
          description: Value(meta?.description),
          coverUrl: Value(meta?.coverUrl),
          locationId: Value(locationId),
          status: const Value(BookStatus.unread),
        ),
      );
    }

    if (companions.isNotEmpty) {
      await _bookRepository.insertAll(companions);
    }

    emit(const ScannerActive(staged: [], scanning: false, saving: false));
  }
}
