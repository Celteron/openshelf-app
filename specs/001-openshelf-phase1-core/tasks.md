---
description: "Task list for OpenShelf Phase 1 — Core Library, Metadata, Import, Locations, Scanner & Lending"
---

# Tasks: OpenShelf — Phase 1

**Input**: Design documents from `/specs/001-openshelf-phase1-core/` (`plan.md`,
`spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`) + OpenShelf
Constitution (`.specify/memory/constitution.md`).

**Prerequisites**: `plan.md`, `spec.md` complete. Tests are REQUIRED for the metadata
aggregator, database migrations, and rating/ISBN calculation logic (Constitution
Article IV.2); importers are built against committed fixtures (spec §5.3).

**Organization**: Tasks are grouped by user story so each story is independently
implementable, testable, and shippable as an increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelizable (different files, no shared edit, no dependency on an
  incomplete task).
- **[Story]**: maps to a user story in `spec.md` (US1–US6).
- Every task carries an exact file path.

## Path Conventions

```text
lib/
├── data/
│   ├── database/            # tables.dart, app_database.dart, daos/
│   ├── repositories/        # Drift repository implementations
│   ├── metadata/            # dnb_client, marc21_parser, google_books_client, open_library_client
│   ├── importers/           # BookImporter + implementations + column_mapper
│   └── cover/               # cover_cache_service
├── domain/
│   ├── models/              # book_metadata, aggregated_metadata, import models
│   ├── repositories/        # abstract repository interfaces
│   └── services/            # metadata_aggregator_service, import_service
├── features/
│   ├── library/             # list/detail/add/search + rating + badge
│   ├── metadata/            # lookup + merge preview cubit
│   ├── locations/           # tree view + batch assign
│   ├── importer/            # picker/mapper/run
│   ├── scanner/             # continuous scan + staging shelf
│   └── lending/             # lend/return + badge
└── core/                    # retained: themes, constants, helpers, localization
test/
├── unit/                    # schema, migration, isbn, rating, parser, merge, importers
├── integration/             # scan flow, import flow
└── fixtures/                # marc21/*.xml, goodreads.csv, bookstats/*.{csv,json}
```

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependency/SDK migration.

- [x] T001 Update `pubspec.yaml`: bump Dart SDK to `>=3.10.0 <4.0.0`; add `drift`,
  `drift_flutter`, `drift_dev`, `build_runner`, `xml`, `mobile_scanner`; remove
  `sqflite` and `barcode_scan2`.
- [x] T002 [P] Rename Android `applicationId` to `de.openshelf.app` in
  `android/app/build.gradle` and iOS bundle id in `ios/Runner.xcodeproj/project.pbxproj`.
- [x] T003 [P] Create `lib/data/`, `lib/domain/`, `lib/features/` directory skeleton
  (subdirs `database/`, `repositories/`, `metadata/`, `importers/`, `cover/`,
  `models/`, `services/`, `library/`, `metadata/`, `locations/`, `importer/`,
  `scanner/`, `lending/`) per plan.md.
- [x] T004 Run `flutter pub get` and confirm the project still builds after the SDK and
  dependency change.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Drift persistence layer and cross-cutting helpers. EVERY user story depends
on this phase.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T005 Define enums (`BookStatus {unread,reading,read,dnf,wishlist,reReading}`,
  `BookFormat {hardcover,paperback,ebook,audiobook}`,
  `LocationType {room,shelf,compartment}`,
  `MetadataSource {dnb,googleBooks,openLibrary,manual}`) and `StringListConverter`
  in `lib/data/database/tables.dart`.
- [x] T006 Define `Books` table (fields, indices `idx_books_isbn10`,
  `idx_books_location`, `idx_books_status`, `idx_books_series`, FKs) in
  `lib/data/database/tables.dart`. Constraints: `isbn13` text nullable UNIQUE;
  `rating` real default 0.0 in 0.5 steps 0.0–5.0; `status` default `unread`.
- [x] T007 Define `Locations` table (self-referential `parentId` FK, `sortOrder`
  default 0) in `lib/data/database/tables.dart`.
- [x] T008 Define `Series` table (`name` text UNIQUE, `totalPlannedVolumes` nullable) in
  `lib/data/database/tables.dart`.
- [x] T009 Define `Lending` table (`idx_lending_book`, `bookId` FK ON DELETE CASCADE)
  in `lib/data/database/tables.dart`.
- [x] T010 Create `AppDatabase` (`schemaVersion = 1`, `MigrationStrategy` with
  `onCreate`/`onUpgrade`/`beforeOpen` running `PRAGMA foreign_keys = ON`) in
  `lib/data/database/app_database.dart`.
- [x] T011 Run `dart run build_runner build --delete-conflicting-outputs` to generate
  `lib/data/database/app_database.g.dart`.
- [x] T012 [P] Create `BooksDao` in `lib/data/database/daos/books_dao.dart`.
- [x] T013 [P] Create `LocationsDao` in `lib/data/database/daos/locations_dao.dart`.
- [x] T014 [P] Create `SeriesDao` in `lib/data/database/daos/series_dao.dart`.
- [x] T015 [P] Create `LendingDao` in `lib/data/database/daos/lending_dao.dart`.
- [x] T016 Create repository interfaces (`BookRepository`, `LocationRepository`,
  `SeriesRepository`, `LendingRepository`) in `lib/domain/repositories/` matching
  `contracts/interfaces.md`.
- [x] T017 [P] Implement ISBN normalization helper (validate; ISBN-10 → ISBN-13 with
  recomputed check digit; prefer 13-digit) in `lib/core/helpers/isbn.dart`.
- [x] T018 [P] Implement rating normalization helper (round to nearest 0.5, clamp
  0.0–5.0) in `lib/core/helpers/rating.dart`.
- [x] T019 Wire `AppDatabase` + repositories into DI in
  `lib/core/dependency_injection.dart`.
- [x] T020 [P] Unit test: schema creation + FK enforcement (in-memory
  `NativeDatabase.memory()`) in `test/unit/database_schema_test.dart`.
- [x] T021 [P] Unit test: migration scaffold (v1 baseline + stepwise upgrade path) in
  `test/unit/database_migration_test.dart`.
- [x] T022 [P] Unit test: ISBN normalization (10↔13, checksum, edge cases) in
  `test/unit/isbn_test.dart`.
- [x] T023 [P] Unit test: rating rounding/clamp to 0.5 steps in `test/unit/rating_test.dart`.

**Checkpoint**: `flutter test` green for schema/migration/isbn/rating; DB reads/writes
work in-memory and on-device.

---

## Phase 3: User Story 1 — Private offline library (Priority: P1) 🎯 MVP

**Goal**: A user adds books manually or by ISBN and browses/edits them entirely offline.

**Independent Test**: Airplane mode on → add three books → relaunch → confirm they
persist and are searchable with no network; rating 3.5 persists exactly.

### Implementation for User Story 1

- [x] T024 [US1] Implement `BookRepository` Drift impl (local search <300ms, status
  filter, insert, update, rating persistence) in
  `lib/data/repositories/book_repository_impl.dart`.
- [x] T025 [P] [US1] Implement `LibraryCubit` (list/filter/search books, status/rating
  edits) in `lib/features/library/library_cubit.dart`.
- [x] T026 [US1] Implement library list/grid screen with search field + status filter in
  `lib/features/library/library_screen.dart`.
- [x] T027 [US1] Implement manual add-book form (title, subtitle, authors, ISBN-10/13,
  publisher, year, page count, format, language, status, rating) in
  `lib/features/library/add_book_screen.dart`.
- [x] T028 [P] [US1] Implement 0.5-step rating control widget in
  `lib/features/library/widgets/rating_control.dart`.
- [x] T029 [US1] Implement book detail screen (view/edit fields, status selector) in
  `lib/features/library/book_detail_screen.dart`.
- [x] T030 [P] [US1] Unit test: `BookRepository` search/filter + 0.5-step rating
  persistence in `test/unit/book_repository_test.dart`.

**Checkpoint**: US1 fully functional and testable independently (offline add/browse/
search/edit).

---

## Phase 4: User Story 2 — DACH metadata enrichment (Priority: P1)

**Goal**: ISBN lookup via DNB (authoritative German data) + Google Books (cover/
description); user edits never overwritten; DNB-verified badge shown.

**Independent Test**: Look up a known DNB ISBN; verify fields + source attribution +
cover caching; hand-edit title then refresh and confirm the title is preserved.

### Implementation for User Story 2

- [x] T031 [US2] Define `BookMetadata`/`AggregatedMetadata` models + `MetadataSourceId`
  in `lib/domain/models/book_metadata.dart` (match `contracts/interfaces.md`; use
  `double?` for `seriesVolume`).
- [x] T032 [P] [US2] Implement `DnbClient` (SRU query builder for
  `https://services.dnb.de/sru/dnb`, `num={isbn}`, `recordSchema=MARC21-xml`;
  return `null` on `numberOfRecords=0`, `<diagnostic>`, HTTP error, malformed XML) in
  `lib/data/metadata/dnb_client.dart`.
- [x] T033 [P] [US2] Implement `Marc21Parser` (MARC21-XML → `BookMetadata`; tags
  020/100/700/245$a/b/264|260$b/c/300$a/490/830/008, prefer 13-digit `020$a`) in
  `lib/data/metadata/marc21_parser.dart`.
- [x] T034 [P] [US2] Implement `GoogleBooksClient` (fill only high-res cover URL +
  description; skip generic placeholder covers) in
  `lib/data/metadata/google_books_client.dart`.
- [x] T035 [P] [US2] Implement `OpenLibraryClient` (fallback when DNB + Google yield
  nothing) in `lib/data/metadata/open_library_client.dart`.
- [x] T036 [US2] Implement `MetadataAggregatorService` (fixed priority
  DNB→Google→Open Library; deterministic merge; preserve `editedFields`) in
  `lib/domain/services/metadata_aggregator_service.dart`.
- [x] T037 [P] [US2] Implement `CoverCacheService` (download cover to
  `documents/covers/<isbn13>.jpg`, set `cover_local_path`) in
  `lib/data/cover/cover_cache_service.dart`.
- [x] T038 [US2] Implement `SeriesRepository` Drift impl (`findByName` case-insensitive,
  `findOrCreate`) in `lib/data/repositories/series_repository_impl.dart`.
- [x] T039 [US2] Implement `MetadataCubit` (lookup orchestration + merge preview) in
  `lib/features/metadata/metadata_cubit.dart`.
- [x] T040 [US2] Wire ISBN lookup into add-book flow + "refresh metadata" action in
  `lib/features/metadata/`.
- [x] T041 [US2] Implement DNB verification badge ("DNB-verifiziert" when
  `metadataSource == dnb` and unmodified, else "bearbeitet") in
  `lib/features/library/widgets/verification_badge.dart`.
- [x] T042 [P] [US2] Unit test: `Marc21Parser` against fixtures (490/830 series,
  245$b subtitle, multiple `020$a`) in `test/unit/marc21_parser_test.dart`.
- [x] T043 [P] [US2] Unit test: merge rules (user-edit precedence, source priority) in
  `test/unit/metadata_aggregator_test.dart`.
- [x] T044 [P] [US2] Unit test: `DnbClient` query building + malformed-XML → `null`
  fallback in `test/unit/dnb_client_test.dart`.

**Checkpoint**: A known DNB ISBN resolves with a DNB-verified badge; refresh never
clobbers a user-edited title; covers persist offline.

---

## Phase 5: User Story 3 — Physical location hierarchy & batch assignment (Priority: P2)

**Goal**: Model Room → Shelf → Compartment and bulk-assign books to a location.

**Independent Test**: Create room → shelf → compartment; select 5 books and reassign
them to the compartment in one action.

### Implementation for User Story 3

- [x] T045 [US3] Implement `LocationRepository` Drift impl (tree ops: create, move,
  reorder, reparent; **deletion guard** — block delete when children/books exist) in
  `lib/data/repositories/location_repository_impl.dart`.
- [x] T046 [US3] Implement `LocationTreeCubit` (load tree, expand/collapse, select node,
  CRUD) in `lib/features/locations/location_tree_cubit.dart`.
- [x] T047 [US3] Implement "Mein Regal" location tree view (Room→Shelf→Compartment) +
  FAB "add location" in `lib/features/locations/location_tree_screen.dart`.
- [x] T048 [US3] Implement batch assignment (select N books → assign to location, single
  transaction) in `lib/features/locations/batch_assign.dart`.
- [x] T049 [US3] Surface deletion-guard message (block delete when non-empty, no silent
  orphaning) in `lib/features/locations/`.
- [x] T050 [P] [US3] Unit test: location hierarchy + deletion guard + bulk-assign
  transaction in `test/unit/location_repository_test.dart`.

**Checkpoint**: Location tree renders in order; batch assignment persists in one
transaction; non-empty locations cannot be deleted.

---

## Phase 6: User Story 4 — Import existing collection (Priority: P2)

**Goal**: Migrate from Openreads/Goodreads/StoryGraph/Bookstats via CSV/JSON.

**Independent Test**: Import a 500-row Goodreads CSV fixture; verify books + per-row
error report; critical mid-import failure rolls back with no partial books.

### Implementation for User Story 4

- [x] T051 [US4] Define `BookImporter` interface + `ImportFile`/`ImportRow`/`RowError`/
  `ImportResult` models in `lib/data/importers/book_importer.dart`.
- [x] T052 [P] [US4] Implement `OpenreadsCsvImporter` (native status/rating mapping) in
  `lib/data/importers/openreads_csv_importer.dart`.
- [x] T053 [P] [US4] Implement `OpenreadsJsonImporter` in
  `lib/data/importers/openreads_json_importer.dart`.
- [x] T054 [P] [US4] Implement `GoodreadsCsvImporter` (`Title`, `Author`, `Additional
  Authors`, `ISBN`, `ISBN13`, `My Rating` 1–5→0.5-step, `Exclusive Shelf`
  read/currently-reading/to-read → read/reading/wishlist, `Number of Pages`) in
  `lib/data/importers/goodreads_csv_importer.dart`.
- [x] T055 [P] [US4] Implement `StoryGraphCsvImporter` (`Title`, `Authors`, `ISBN/UID`,
  `Rating`) in `lib/data/importers/storygraph_csv_importer.dart`.
- [x] T056 [P] [US4] Implement `BookstatsCsvImporter` + `BookstatsJsonImporter` in
  `lib/data/importers/bookstats_csv_importer.dart` and
  `lib/data/importers/bookstats_json_importer.dart`.
- [x] T057 [US4] Implement `ColumnMapper` (flexible header → canonical field mapping) in
  `lib/data/importers/column_mapper.dart`.
- [x] T058 [US4] Implement `ImportService` (chunked 500/transaction insert, per-row error
  log, rollback current transaction on critical failure, ISBN dedup) in
  `lib/domain/services/import_service.dart`.
- [x] T059 [US4] Implement `ImporterCubit` (`selecting|mapping|importing|done(report)`)
  in `lib/features/importer/importer_cubit.dart`.
- [x] T060 [US4] Implement importer screen (file pick, format detect, column-map preview
  table, run with progress/error log) in `lib/features/importer/importer_screen.dart`.
- [x] T061 [P] [US4] Unit test: each importer against `test/fixtures/` (incl. 500-row
  Goodreads + Bookstats fixtures) in `test/unit/importers/`.
- [x] T062 [P] [US4] Unit test: `ImportService` rollback on critical failure in
  `test/unit/import_service_test.dart`.

**Checkpoint**: 500-row Goodreads fixture imports with a complete error report; rollback
verified; column mapper preview works.

---

## Phase 7: User Story 5 — Continuous batch barcode scanning (Priority: P3)

**Goal**: Scan ISBNs rapidly; camera stays active; books accumulate on a staging shelf
for review and bulk save.

**Independent Test**: Scan 10 ISBNs without refocusing; staging list grows; a single
"save all" persists them and skips duplicates.

### Implementation for User Story 5

- [x] T063 [US5] Implement `ScannerCubit` (`idle|scanning|staging|saving`; staging list;
  dedup vs. staged + already-owned ISBN) in `lib/features/scanner/scanner_cubit.dart`.
- [x] T064 [US5] Implement continuous scanner view (`mobile_scanner` with
  `BarcodeFormat.ean13` + `DetectionSpeed.noDuplicates`, live counter, collapsible
  staging-shelf panel, persistent "save all" CTA) in
  `lib/features/scanner/scanner_screen.dart`.
- [x] T065 [US5] Implement batch save (staging → DB, ISBN dedup) + bulk location assign
  on save in `lib/features/scanner/`.
- [x] T066 [US5] Throttle/queue background metadata lookup for staged books in
  `lib/features/scanner/`.
- [x] T067 [P] [US5] Integration test: scan → lookup → stage → assign → save flow in
  `test/integration/scan_flow_test.dart`.

**Checkpoint**: 10 ISBNs scan without manual refocus; staging clears after "save all";
duplicates skipped.

---

## Phase 8: User Story 6 — Lending tracker (Verleihverwaltung) (Priority: P3)

**Goal**: Record who borrowed a book and when; show a badge on the cover; mark returned.

**Independent Test**: Mark a book "Verliehen an Anna"; verify badge; then mark returned
and confirm the badge clears.

### Implementation for User Story 6

- [x] T068 [US6] Implement `LendingRepository` Drift impl (`lend`, `markReturned`,
  `watchActiveLending`) in `lib/data/repositories/lending_repository_impl.dart`.
- [x] T069 [US6] Implement `LendingCubit` (lend / mark returned) in
  `lib/features/lending/lending_cubit.dart`.
- [x] T070 [US6] Implement lending badge overlay + "Verleihen" / "Als zurückgegeben
  markieren" actions in `lib/features/lending/` and book list/detail.

**Checkpoint**: Lend/return cycle works; badge overlays and clears correctly.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements affecting multiple user stories + constitution compliance.

- [x] T071 Apply Material 3 theming (dark/light) + responsive tablet layouts across
  screens in `lib/core/themes/`.
- [x] T072 [P] Accessibility pass (≥48×48 dp targets, high contrast, screen-reader
  labels) across all screens.
- [x] T073 [P] Localization: ensure German (default) + English strings in
  `assets/translations/`.
- [x] T074 [P] Extend backup/export to serialize `Locations`, `Series`, and `Lending`
  (in addition to `Books`) in `lib/core/helpers/backup/` (Constitution Article I.3).
- [x] T075 Run full `flutter test`, `dart analyze`, `dart format lib test`; constitution
  compliance review (Articles I–VII).

**Checkpoint**: End-to-end offline demo (scan → save → assign → lend → search) green;
analyze/format clean.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**.
- **User Stories (Phases 3–8)**: All depend on Foundational completion.
- **Polish (Phase 9)**: Depends on all desired user stories.

### User Story Dependencies

- **US1 (P1)**: after Foundational; no story dependencies.
- **US2 (P1)**: after Foundational; depends on US1's `BookRepository` for persistence.
- **US3 (P2)**: after Foundational; independent (own repository + tree).
- **US4 (P2)**: after Foundational; depends on US1 `BookRepository` + ISBN helper.
- **US5 (P3)**: after US1/US2 (staging save + lookup) and US3 (bulk location assign).
- **US6 (P3)**: after US1 (book list/detail badge surfaces).

### Within Each User Story

- Models before services; services before UI; UI before integration wiring.
- Tests (where mandated) written to FAIL first, then implementation makes them green.
- Story complete before moving to the next priority.

### Parallel Opportunities

- Phase 1: T002, T003 parallel.
- Phase 2: T012–T015 (DAOs), T017–T018 (helpers), T020–T023 (tests) parallel.
- US1: T025, T028, T030 parallel.
- US2: T032–T035 (clients/parser), T037, T042–T044 (tests) parallel.
- US4: T052–T056 (importers), T061–T062 (tests) parallel.
- US5: T067 parallel with later tasks.
- Polish: T072–T074 parallel.
- Once Foundational completes, US1–US4 can proceed in parallel (if staffed); US5/US6
  follow their story dependencies.

---

## Parallel Example: User Story 2

```bash
# Launch all independent metadata clients/parser together:
Task: "Implement DnbClient in lib/data/metadata/dnb_client.dart"
Task: "Implement Marc21Parser in lib/data/metadata/marc21_parser.dart"
Task: "Implement GoogleBooksClient in lib/data/metadata/google_books_client.dart"
Task: "Implement OpenLibraryClient in lib/data/metadata/open_library_client.dart"
Task: "Implement CoverCacheService in lib/data/cover/cover_cache_service.dart"

# Then the service that composes them:
Task: "Implement MetadataAggregatorService in lib/domain/services/metadata_aggregator_service.dart"
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1 (Setup) + Phase 2 (Foundational).
2. Complete Phase 3 (US1).
3. **STOP and VALIDATE**: run the US1 independent test (offline add/browse/search/edit).
4. Demo/deploy the offline library.

### Incremental Delivery

1. Setup + Foundational → persistence ready.
2. US1 → offline library (MVP).
3. US2 → DNB metadata enrichment (DACH differentiator).
4. US3 + US4 → locations + import.
5. US5 + US6 → scanner + lending.
6. Polish → theming, accessibility, localization, export completeness.

### Parallel Team Strategy

1. Team completes Setup + Foundational together.
2. Once Foundational is done: Dev A → US1, Dev B → US2, Dev C → US3, Dev D → US4.
3. US5/US6 picked up as stories complete their dependencies.

---

## Notes

- Write tests FIRST for metadata merge, importers, and migration (Article IV.2); verify
  they FAIL before implementing, then go green.
- No destructive DB migration; each schema change needs a versioned `onUpgrade` step +
  test (Article II).
- All network calls fail gracefully offline; user edits never overwritten (Articles I &
  III).
- `presentation` code must never import `package:drift` or HTTP clients (Article II).
- Commit after each task or logical group (Angular-style messages per `CONTRIBUTING.md`).
