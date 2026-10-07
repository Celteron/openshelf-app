# Tasks: OpenShelf Phase 2

Legend: `[X]` done. Each task traces to FR-P2-xx in `spec.md`.

## Sprint 5 — Foundation
- [X] T2-01 Dump v1 schema (`drift_schemas/drift_schema_v1.json`) before any table change. (FR-P2-09)
- [X] T2-02 Tables: `Books.currentPage/finishedAt`, `ReadingSessions`, `BookNotes`, `Tags`, `BookTags`, `ReadingGoals`; enum `NoteKind`.
- [X] T2-03 `schemaVersion = 2` + `onUpgrade`; dump v2; generate verifier helpers; migration tests (structure + data preservation).

## Sprint 6 — Domain & data
- [X] T2-04 Pure models: `ReadingStats`, `GoalProgress`; unit tests.
- [X] T2-05 Repositories + DAOs: Reading, Notes, Tags, Goals; `finishedAt` in `updateStatus`; tests.
- [X] T2-06 `ReadingTrackerService` (start/stop/manual/page, status promotion); tests with injected clock.
- [X] T2-07 Export v2 + test.

## Sprint 7 — Presentation
- [X] T2-08 `features/reading`: cubit + screen (live timer, page, speed, history, manual log).
- [X] T2-09 `features/notes`: cubit + screen (notes/quotes, page, copy).
- [X] T2-10 `features/tags`: cubit, management screen, book tag picker; library tag chips; fix status chip filtering.
- [X] T2-11 Statistics: yearly goal card (set/clear) + reading speed card.
- [X] T2-12 Wishlist flow + localized status labels.
- [X] T2-13 Wire DI/main/detail/settings; l10n DE+EN; ARB parity test.

## Sprint 8 — Verification
- [X] T2-14 Widget tests (notes copy, tag chips, goal card). 
- [X] T2-15 `dart analyze` = 0, `flutter test` = 100%.

## Sprint 9 — Legacy superset, schema v2 importers & UI polish
- [X] T2-16 Schema v2 additions (before release, so no v3): `Books.isFavorite/review`, `ReadingGoals.targetPages`;
  regenerate `drift_schema_v2.json` + migration helpers; migration test asserts the new defaults. (FR-P2-12/15/17)
- [X] T2-17 Importers → v2: shared parsing (dates, tags, `Last, First` authors, Openreads `readings`),
  `ImportedBook` + atomic `BooksDao.insertImported`, delimiter detection, UTF-8/Latin-1 decoding. (FR-P2-12–14)
- [X] T2-18 `test/importers/bookstats_import_test.dart` against `Test_Export_BookStats.csv` (773 books, 83 tags,
  110 sessions) + per-importer v2 tests + rollback test. (FR-P2-12–14)
- [X] T2-19 Book detail: delete dialog, favourite, review, rating clear; `BookRepository.deleteBook/updateFavorite/
  updateReview`. (FR-P2-15)
- [X] T2-20 Library: `LibrarySort`, sort menu, favourites filter. (FR-P2-16)
- [X] T2-21 Optional yearly page goal (repository, progress model, statistics card, dialog). (FR-P2-17)
- [X] T2-22 Fix: tag names are matched case-insensitively in Dart (SQLite `lower()` is ASCII-only) — regression
  test with `Übernatürliches`.
- [X] T2-23 `dart analyze` = 0, `flutter test` = 100%.

## Sprint 10 — Duplicate-safe re-import, licence, parity audit
- [X] T2-24 `BooksDao.importBatch` + `import_merge.dart`: ISBN-13 → ISBN-10 → title+authors matching inside the batch
  transaction, gap-filling merge, tag/note/session union; `ImportResult.updated/duplicates`; summary UI + DE/EN strings. (FR-P2-18)
- [X] T2-25 `test/importers/duplicate_import_test.dart` (773-book re-import is a no-op, merge/no-overwrite, matching rules,
  CSV round trip) + `test/widget/importer_summary_test.dart`. (FR-P2-18)
- [X] T2-26 Root `LICENSE` → GPL-3.0; licence-text test. Open issue recorded in FR-P2-19. (FR-P2-19)
- [X] T2-27 `legacy-parity-audit.md`: feature-by-feature audit against upstream `74b613b0` with a gap backlog.
- [X] T2-28 `dart analyze` = 0, `flutter test` = 100%.
