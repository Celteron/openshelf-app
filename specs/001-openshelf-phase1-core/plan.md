# Implementation Plan: OpenShelf — Phase 1 (Core Library, Metadata, Import, Locations, Scanner & Lending)

**Branch**: `001-openshelf-phase1-core` | **Date**: 2026-10-06 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-openshelf-phase1-core/spec.md`

## Summary

OpenShelf Phase 1 re-founds the inherited Openreads codebase into an offline-first,
privacy-centric physical book library for the DACH market. It replaces the `sqflite`
persistence layer with **Drift (SQLite)**, adds a **multi-source metadata engine**
(DNB SRU → Google Books → Open Library) with deterministic, user-edit-preserving merge
rules, a **pluggable importer pipeline** (Openreads/Goodreads/StoryGraph/Bookstats
CSV/JSON), a **physical location hierarchy** (Room → Shelf → Compartment), a **continuous
batch scanner**, and a **lending tracker**, all behind repository interfaces under a
Bloc-based Presentation → State → Domain → Data layering.

Primary technical approach (from research, see `research.md`): Drift accessed via
`drift_flutter` (replaces the EOL `sqlite3_flutter_libs` path), MARC21-XML parsed with the
`xml` package against the `http://www.loc.gov/MARC21/slim` namespace, and continuous
scanning via `mobile_scanner` using `DetectionSpeed.noDuplicates` on the EAN-13 format.

## Technical Context

**Language/Version**: Dart 3.10+ (latest stable), Flutter 3.35+ (latest stable). The
inherited `pubspec.yaml` pins `>=2.18.2 <3.0.0` and must be bumped (spec §9).

**Primary Dependencies**:
- `flutter_bloc` (already present) — State layer.
- `drift`, `drift_flutter`, `drift_dev`, `build_runner` — persistence + codegen.
- `mobile_scanner` — continuous batch barcode scanning (replaces inherited `barcode_scan2`).
- `xml` — MARC21-XML parsing.
- `http` (already present) — remote clients (DNB/Google Books/Open Library).
- `csv`, `file_picker` (already present) — import pipeline.
- `path_provider` (already present) — cover cache storage.
- `easy_localization` (already present) — German/English localizations.

**Storage**: Drift (SQLite) on-device; opened via `driftDatabase(name: ...)` from
`drift_flutter`. Cover images cached to the app documents directory (file system).

**Testing**: `flutter_test` with in-memory `NativeDatabase.memory()` for schema/DAO tests,
`http` `MockClient` for client tests, and committed fixtures under `test/fixtures/` for
MARC21 and importer parsers. Integration tests via `flutter_test` on device/emulator.

**Target Platform**: Android + iOS, mobile and tablet (responsive layouts).

**Project Type**: Flutter mobile application (offline-first local app).

**Performance Goals**: 1,000-row import < 5 s; local search < 300 ms; scanner ≥ 1 scan/s;
smooth 60 fps list/grid rendering; chunked batch inserts (500/transaction).

**Constraints**: Fully offline-capable primary features; zero telemetry/accounts; GPLv2;
WCAG 2.1 AA contrast + ≥48×48 dp targets; no destructive DB migrations; user edits never
overwritten; network calls opt-in and fail gracefully.

**Scale/Scope**: Single-user local library; up to ~10k books, arbitrary location tree
depth (3 levels), unlimited lending events.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Evidence |
|---------|-------------|--------|----------|
| I.1 | Offline-first: primary features work offline | ✅ PASS | All data local via Drift; network only for metadata/cover lookup (§1.3, SC-001) |
| I.2 | Zero telemetry / no accounts | ✅ PASS | No analytics/tracking deps; metadata clients are opt-in user actions (§9) |
| I.3 | Data sovereignty: full CSV/JSON/SQLite export/import | ✅ PASS | Import via importer pipeline (US4); export carried from inherited code and extended to new tables (see research decision) |
| II.1 | Flutter + strict null-safety, no `dynamic` | ✅ PASS (minor) | Strongly typed models; `StringListConverter` uses `dynamic` only at JSON boundary (justified in research) |
| II.2 | Layered architecture; Drift-only DB access | ✅ PASS | Presentation→State→Domain→Data; presentation must not import `drift`/HTTP (§1.3) |
| II.3 | Migration safety: no destructive changes | ✅ PASS | Schema v1 + stepwise `onUpgrade`; PRAGMA foreign_keys ON (§3.5) |
| III.1 | Fixed metadata hierarchy DNB→Google→Open Library | ✅ PASS | `MetadataAggregatorService` enforces fixed chain (§4.1, FR-003) |
| III.2 | No silent overwrite of user edits | ✅ PASS | Per-field `edited_fields` set; merge preserves edited fields (§4.3, FR-005) |
| III.3 | Local cover caching | ✅ PASS | `CoverCacheService` + `cover_local_path` (§4.6, FR-006) |
| IV.1 | Strong types, exhaustive sealed states, inline docs | ✅ PASS | Sealed state classes + exhaustive matching; MARC parser documented |
| IV.2 | Tests for aggregator, migrations, rating/stats | ✅ PASS | Tasks T011–T012, T021–T023, T035–T036 mandate these |
| IV.3 | Defensive API handling, graceful fallback | ✅ PASS | Clients return `null` on error; malformed XML → fallback (§4.6) |
| V.1 | Material 3, dark/light, responsive | ✅ PASS | FR-017 |
| V.2 | Batch ops minimize blocking, minimal modals | ✅ PASS | Chunked inserts; continuous scanner staging (§5.4, US5) |
| V.3 | Accessibility 48×48 dp, contrast, screen readers | ✅ PASS | FR-018, SC-006 |
| VI.1 | Spec + tasks before implementation | ✅ PASS | `spec.md` + `tasks.md` present |
| VII.1 | GPLv2 compliance | ✅ PASS | No license change; upstream GPLv2 (§9) |

**Gate result**: PASS. No blocking violations. Two minor notes tracked in Complexity
Tracking (JSON `dynamic` in the string-list converter; `num` in the `BookMetadata`
contract) — both resolved in Phase 0/1 with no architectural deviation.

## Project Structure

### Documentation (this feature)

```text
specs/001-openshelf-phase1-core/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (interface contracts)
└── tasks.md             # Phase 2 output (already present)
```

### Source Code (repository root)

Phase 1 re-lays the inherited `lib/` into a layered structure (per §1.3 and the task
path conventions in `tasks.md`):

```text
lib/
├── data/
│   ├── database/            # tables.dart, app_database.dart, daos/
│   ├── metadata/            # dnb_client.dart, marc21_parser.dart, google_books_client.dart, open_library_client.dart
│   ├── importers/           # book_importer.dart + openreads_*/goodreads_*/storygraph_*/bookstats_* + column_mapper.dart
│   └── cover/               # cover_cache_service.dart
├── domain/
│   ├── models/              # book_metadata.dart, aggregated_metadata.dart, import_row.dart, ...
│   ├── repositories/        # abstract repository interfaces
│   └── services/            # metadata_aggregator_service.dart, import_service.dart
├── features/
│   ├── library/             # screens + cubits (list/detail/search)
│   ├── metadata/            # lookup + merge preview
│   ├── scanner/             # continuous scan + staging shelf
│   ├── importer/            # picker/mapper/run
│   ├── locations/           # tree view + batch assign
│   └── lending/             # lend/return + badge
└── core/                    # existing themes/constants/localization (retained & adapted)

test/
├── unit/                    # parser, merge, importers, migration, daos
├── integration/             # scan→lookup→stage→assign→save; import→location→search
└── fixtures/                # marc21/*.xml, goodreads.csv, bookstats/*.{csv,json}
```

**Structure Decision**: Keep the inherited `lib/core` (themes, constants, localization)
for compatibility, but move all business logic out of the inherited `lib/model` +
`lib/resources` into the layered `lib/data` / `lib/domain` / `lib/features` structure.
This satisfies Constitution Article II (layered architecture) while minimizing churn on
theme/localization assets.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `dynamic` in `StringListConverter` (JSON decode boundary) | `dart:convert` `jsonDecode` returns `dynamic`; must cast to `List<String>` | Could hand-roll a JSON array parser, but adds risk and complexity for zero type-safety gain; the cast is localized and unit-tested |
| `num` for `seriesVolume` in `BookMetadata` contract (§4.2) | MARC `490 $v` can be non-integer ("Bd. 3.5") | Using `double?`/`int?` would force an artificial split; `num` maps cleanly to the `RealColumn` |
