# Tasks: OpenShelf Feedback Round 1

Legend: `[X]` done, `[ ]` open. Each task traces to FR-F1-xx in `spec.md`.

## Schema & data (FR-F1-01..04)
- [X] T3-01 `Books.genre/priceCents/receivedAt`, `schemaVersion = 4`, migration `from < 4`, snapshot `drift_schema_v4.json`, generated verifier helpers. (FR-F1-01)
- [X] T3-02 Migration tests v1/v2/v3 → v4 incl. data preservation (`database_upgrade_test.dart`). (FR-F1-01)
- [X] T3-03 `core/helpers/price.dart` (parse/format cents) + `price_test.dart`. (FR-F1-02)
- [X] T3-04 `BookDraft`, `BookImport`, `ImportService`, `mergeMissingFields` (fill-only), JSON + CSV export, JSON/CSV restore + `book_extra_fields_test.dart`. (FR-F1-02, -03)
- [X] T3-05 Bookstats CSV/JSON: `Genre`, `Preis`, `Erhalten am`, `Dauer (Stunden/Minuten)`; genre stays a tag as well. (FR-F1-04)

## UI (FR-F1-05..07)
- [X] T3-06 `ReadingSummary` (start, end, time, day span) + tests. (FR-F1-05)
- [X] T3-07 Detail view: new rows, reading start/end/time, selectable + copy button per value. (FR-F1-05, -06)
- [X] T3-08 `VerificationBadge` without edit icon. (FR-F1-07)
- [X] T3-09 Book form: genre, price (validated), received date (picker, clearable). (FR-F1-02)
- [X] T3-10 l10n DE + EN for all new strings (parity test green).

## Importer matcher (FR-F1-08)
- [X] T3-11 `CsvImporter.parse(mapper:)`, `columns()`, `mappableFields`; `ImportColumn`.
- [X] T3-12 `ImporterCubit`: columns, `assign`, `changeImporter`, import with chosen mapping + tests.
- [X] T3-13 Matcher screen (format switch, per-column dropdown with sample) + widget tests.

## Covers (FR-F1-09)
- [X] T3-14 `coverCandidates` / `dnbCoverUrl` / `CoverCacheService.resolveAny` (429 = next source) + tests.
- [X] T3-15 `BookCover` and `CoverSyncService` use the chain.
- [X] T3-16 Live check `test/integration/cover_live_test.dart` (1 request, tag `live-network`).

## Licence (FR-F1-10)
- [X] T3-17 Licence reverted to GPL-2.0: `LICENSE` restored from `1b4b606c`, `licenseText` DE/EN, tests; decision in `doc/adr/0001-lizenz-gpl-2-0.md`.

## Round 2 (FR-F1-11..15)
- [X] T3-18 Undo SnackBar `persist: false`; five-star `RatingControl` with half/full zones.
- [X] T3-19 One ISBN row; reading period vs. time read; schema v5 `readingSeconds` (migration, import, merge, export, restore); manual session dialog with optional time + unit.
- [X] T3-20 `trashAllBooks` / `deleteAllBooksPermanently`, `DataResetRepository`, `DataWipeService`; Settings → Data; "select all".
- [X] T3-21 Matcher by column index, `canImport` needs a title, `OwnCsvImporter` (last in detection order).
- [X] T3-22 DNB cover URL fallback in the aggregator; optional `apiKey` in `GoogleBooksClient` (live test reads `GOOGLE_BOOKS_API_KEY`).
- [ ] T3-23 Open: camera scan + crop of a cover photo (see chat), Google Books key in the app settings (not wanted for now).
- [X] T3-24 Review fixes: edit keeps `readingSeconds`; `CoverCacheService.deleteAll` only removes its own `*.jpg` (never a user folder); lookup never swaps an existing cover for the DNB guess; failing DNB guess still tries Open Library; non-finite session time rejected; failing import ends in an error state; rating control exposes increase/decrease.
- [X] T3-26 Rating bar enlarged (60×56 dp per star) with tap + drag; a failing save shows the error and keeps the form.
- [ ] T3-25 Open: Statistics ignore `readingSeconds`. "Select all" survives a filter change. Cover folder still lives in the documents directory.
