---
description: "Task list for OpenShelf Phase 1 — Core Library, Metadata, Import, Locations, Scanner & Lending"
---

# Tasks: OpenShelf — Phase 1

**Input**: `.spec/spec.md` (user stories + requirements), OpenShelf Constitution
(`.specify/memory/constitution.md`).

**Prerequisites**: `spec.md` (complete). Tests are REQUIRED for metadata aggregator,
importer parsers, migrations, and rating/stats (Constitution Article IV).

**Organization**: Tasks are grouped into 4 Sprints (chronological). Each task carries a
`[P]` flag (parallel-safe) and a `[US#]` label for traceability to a user story.

## Format: `[ID] [P?] [US#] Description`

- **[P]**: independent of other in-sprint tasks (different files, no shared edit).
- **[US#]**: maps to a user story in `spec.md`.
- Exact file paths are given per task.

## Path Conventions

```text
lib/
├── data/
│   ├── database/            # tables.dart, app_database.dart, daos/
│   ├── metadata/            # dnb_client, marc21_parser, google_books_client, ...
│   ├── importers/           # BookImporter + implementations
│   └── cover/               # CoverCacheService
├── domain/
│   ├── models/              # BookMetadata, AggregatedMetadata, ImportRow, ...
│   ├── repositories/        # abstract interfaces
│   └── services/            # MetadataAggregatorService, ImportService
└── features/
    ├── library/             # screens + cubits
    ├── metadata/
    ├── scanner/
    ├── importer/
    ├── locations/
    └── lending/
test/
├── unit/                    # parser, merge, importers, migration
└── integration/             # scan→lookup→stage→assign→save, import→location→search
```

---

## Sprint 1: DB Schemas & Drift Setup (Foundational)

**Purpose**: Persistence foundation. Blocks ALL user stories.

- [ ] T001 Update `pubspec.yaml`: add `drift`, `drift_flutter`, `sqlite3_flutter_libs`,
  `drift_dev`, `build_runner`; bump SDK to latest stable Flutter/Dart; remove `sqflite`.
- [ ] T002 Define enums + `StringListConverter` in `lib/data/database/tables.dart`.
- [ ] T003 [P] Define `Books` table (fields, indices, FKs) in `lib/data/database/tables.dart`.
- [ ] T004 [P] Define `Locations` table (self-referential hierarchy) in `lib/data/database/tables.dart`.
- [ ] T005 [P] Define `Series` table in `lib/data/database/tables.dart`.
- [ ] T006 [P] Define `Lending` table in `lib/data/database/tables.dart`.
- [ ] T007 Create `AppDatabase` (`schemaVersion = 1`, `MigrationStrategy`, `PRAGMA
  foreign_keys = ON`) in `lib/data/database/app_database.dart`.
- [ ] T008 Run `dart run build_runner build` to generate `app_database.g.dart`.
- [ ] T009 Create DAOs `BooksDao`, `LocationsDao`, `SeriesDao`, `LendingDao` in
  `lib/data/database/daos/`.
- [ ] T010 Create repository interfaces (`BookRepository`, `LocationRepository`,
  `SeriesRepository`, `LendingRepository`) in `lib/domain/repositories/` + Drift impls.
- [ ] T011 [P] [US1] Unit test: schema creation + FK enforcement (in-memory `NativeDatabase`)
  in `test/unit/database_schema_test.dart`.
- [ ] T012 [P] [US1] Unit test: migration scaffold (version 1 baseline, upgrade path) in
  `test/unit/database_migration_test.dart`.
- [ ] T013 Wire `AppDatabase` into app DI/provider.

**Checkpoint**: `flutter test` green; DB reads/writes work in-memory and on-device.

---

## Sprint 2: Metadata Pipeline (DNB + Google Books)

**Purpose**: The DACH differentiator. Depends on Sprint 1.

- [ ] T014 Define `BookMetadata` / `AggregatedMetadata` models + `MetadataSourceId` in
  `lib/domain/models/`.
- [ ] T015 [P] Implement `DnbClient` (SRU HTTP + query builder, error detection) in
  `lib/data/metadata/dnb_client.dart`.
- [ ] T016 [P] Implement `Marc21Parser` (MARC21 XML → `BookMetadata`, tag mappings 020/100/
  245/264/300/490/830) in `lib/data/metadata/marc21_parser.dart`.
- [ ] T017 [P] Implement `GoogleBooksClient` in `lib/data/metadata/google_books_client.dart`.
- [ ] T018 [P] Implement `OpenLibraryClient` in `lib/data/metadata/open_library_client.dart`.
- [ ] T019 Implement `MetadataAggregatorService` (fixed priority + deterministic merge) in
  `lib/domain/services/metadata_aggregator_service.dart`.
- [ ] T020 Implement `CoverCacheService` (download + `cover_local_path`) in
  `lib/data/cover/cover_cache_service.dart`.
- [ ] T021 [P] [US2] Unit test: `Marc21Parser` (fixtures incl. 490/830 series, 245$b
  subtitle, multiple 020$a) in `test/unit/marc21_parser_test.dart`.
- [ ] T022 [P] [US2] Unit test: merge rules (user-edit precedence, source priority) in
  `test/unit/metadata_aggregator_test.dart`.
- [ ] T023 [P] [US2] Unit test: `DnbClient` query building + malformed-XML → `null`
  fallback in `test/unit/dnb_client_test.dart`.
- [ ] T024 [US2] Implement `MetadataCubit` and wire lookup into "Add book" / ISBN lookup
  flow in `lib/features/metadata/`.

**Checkpoint**: A known DNB ISBN resolves with a DNB-verified badge; refresh never clobbers
a user-edited title; covers persist offline.

---

## Sprint 3: Importer & Location Hierarchy

**Purpose**: Migration + physical organization. Depends on Sprint 1.

- [ ] T025 Define `BookImporter` interface + `ImportFile`/`ImportRow`/`RowError`/
  `ImportResult` models in `lib/data/importers/` and `lib/domain/models/`.
- [ ] T026 [P] [US4] Implement `OpenreadsCsvImporter` in `lib/data/importers/openreads_csv_importer.dart`.
- [ ] T027 [P] [US4] Implement `OpenreadsJsonImporter` in `lib/data/importers/openreads_json_importer.dart`.
- [ ] T028 [P] [US4] Implement `GoodreadsCsvImporter` in `lib/data/importers/goodreads_csv_importer.dart`.
- [ ] T029 [P] [US4] Implement `StoryGraphCsvImporter` in `lib/data/importers/storygraph_csv_importer.dart`.
- [ ] T030 [P] [US4] Implement `BookstatsCsvImporter` + `BookstatsJsonImporter` in
  `lib/data/importers/bookstats_*_importer.dart`.
- [ ] T031 [US4] Implement `ColumnMapper` (flexible header → field mapping) in
  `lib/data/importers/column_mapper.dart`.
- [ ] T032 [US4] Implement `ImportService` (chunked batch insert, transaction rollback,
  per-row error log) in `lib/domain/services/import_service.dart`.
- [ ] T033 [US3] Implement `LocationRepository` tree ops (CRUD, move, reorder, reparent
  guard) in `lib/domain/repositories/`.
- [ ] T034 [US3] Implement batch location assignment (select N books → reassign, single
  transaction) in `lib/features/locations/`.
- [ ] T035 [P] [US4] Unit test: each importer with fixture files in `test/unit/importers/`.
- [ ] T036 [P] [US4] Unit test: `ImportService` rollback on critical failure in
  `test/unit/import_service_test.dart`.
- [ ] T037 [US4] Implement Importer screen (file pick, format detect, column-map preview,
  run import) in `lib/features/importer/`.

**Checkpoint**: A 500-row Goodreads fixture imports with an error report; location tree
renders and batch assignment persists.

---

## Sprint 4: Batch Scanner, Lending & UI Polish

**Purpose**: High-throughput scanning + lending + accessibility. Depends on Sprints 1–3.

- [ ] T038 [US5] Implement continuous scanner view + staging shelf state (`ScannerCubit`)
  in `lib/features/scanner/`.
- [ ] T039 [US5] Implement batch save (staging → DB, ISBN dedup) + bulk location assign in
  `lib/features/scanner/`.
- [ ] T040 [US2] Implement series auto-extract (MARC21 490/830 → create/link `Series`) on
  scan in `lib/domain/services/`.
- [ ] T041 [US6] Implement `LendingCubit` + repository (lend, mark returned) in
  `lib/features/lending/`.
- [ ] T042 [US6] Implement lending badge overlay + "Verleihen" / "Als zurückgegeben
  markieren" actions in `lib/features/lending/` and book list/detail.
- [ ] T043 [US3] Implement "Mein Regal" location tree view in `lib/features/locations/`.
- [ ] T044 [US2] Implement Book Details with DNB verification badge in
  `lib/features/library/`.
- [ ] T045 [US1] Apply Material 3 theming (dark/light), responsive tablet layouts across
  screens.
- [ ] T046 [US1] Accessibility pass (≥48×48 dp targets, high contrast, screen reader labels).
- [ ] T047 [P] [US5] Integration test: scan → lookup → stage → assign → save flow in
  `test/integration/scan_flow_test.dart`.
- [ ] T048 [P] [US4] Integration test: import → location assign → search in
  `test/integration/import_flow_test.dart`.
- [ ] T049 Polish: run full `flutter test`, `dart analyze`, `dart format lib`; constitution
  compliance review (Constitution Articles I–VII).

**Checkpoint**: End-to-end offline demo: scan 10 books → save → assign → lend one → search
offline — all green.

---

## Dependencies & Execution Order

### Sprint Dependencies

- **Sprint 1 (Foundational)**: No dependencies — start immediately. BLOCKS all others.
- **Sprint 2 (Metadata)**: Depends on Sprint 1 (DAOs/repos) only.
- **Sprint 3 (Importer & Locations)**: Depends on Sprint 1.
- **Sprint 4 (Scanner, Lending, Polish)**: Depends on Sprints 1–3.

### User Story Mapping

| Sprint | Stories | Priority |
|--------|---------|----------|
| 1 | US1 (foundation) | P1 |
| 2 | US2 (metadata/DNB) | P1 |
| 3 | US3 (locations), US4 (import) | P2 |
| 4 | US5 (scanner), US6 (lending), US1 (polish) | P3 |

### Parallel Opportunities

- Sprint 1: T003–T006 (table defs) and T011–T012 (tests) are parallel-safe.
- Sprint 2: T015–T018 (clients/parser) are parallel-safe; tests T021–T023 likewise.
- Sprint 3: T026–T030 (importers) and T035–T036 (tests) are parallel-safe.
- Sprint 4: T047–T048 (integration tests) are parallel-safe.

---

## Notes

- Write tests FIRST for metadata merge and importers (Constitution Article IV); verify they
  FAIL before implementing, then go green.
- Commit after each task or logical group (Angular-style messages per `CONTRIBUTING.md`).
- No destructive DB migration is permitted; each schema change needs a versioned `onUpgrade`
  step + test (Constitution Article II).
- All network calls fail gracefully offline; user edits are never overwritten (Constitution
  Articles I & III).
