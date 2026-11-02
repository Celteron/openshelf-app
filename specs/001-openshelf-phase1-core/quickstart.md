# Quickstart — OpenShelf Phase 1

Runnable validation scenarios that prove each user story end-to-end. Prerequisites are
followed by a per-story "run + expected outcome" table. Implementation details live in
`tasks.md`; the merge rules and entity semantics are in `data-model.md` and
`contracts/`.

## Prerequisites

```bash
# 1. Toolchain (already on this machine: Flutter 3.35.5)
flutter --version          # ≥ 3.29 (mobile_scanner 7.x) / ≥ 3.35 recommended

# 2. After Sprint 1 bumps the SDK + adds Drift (T001):
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generate app_database.g.dart

# 3. Run the full unit + integration suite:
flutter test              # unit tests (in-memory Drift, no device needed)
flutter analyze           # zero errors/warnings
dart format lib test      # formatted
```

## Validation scenarios

### US1 — Private offline library (P1)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Enable airplane mode; add 3 books manually (title + author + ISBN) | Books persist and appear in list |
| 2 | Set one book's rating to 3.5; relaunch | Rating persists exactly at 3.5 |
| 3 | Search a title locally | Matching book returns in <300 ms, no network |
| 4 | `flutter test test/unit/database_schema_test.dart` | Schema + FK enforcement pass |

### US2 — DACH metadata enrichment (P1)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Look up a known DNB ISBN (German title) | title/subtitle/author/publisher/year/pages/series/volume populate; **DNB-verifiziert** badge shows |
| 2 | Trigger "refresh metadata" after editing the title by hand | Edited title preserved; other fields may update |
| 3 | Go offline; open the book | Cover still renders from local cache (`cover_local_path`) |
| 4 | `flutter test test/unit/marc21_parser_test.dart test/unit/metadata_aggregator_test.dart test/unit/dnb_client_test.dart` | Parser (incl. 490/830), merge rules, fallback all green |

### US3 — Physical location hierarchy (P2)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Create "Wohnzimmer" (room) → "Billy Links" (shelf) → "Fach 2" (compartment) | Tree renders in order |
| 2 | Select 5 books, "assign to location" | All 5 `location_id`s update in one transaction |
| 3 | Try deleting a non-empty location | Deletion blocked (FR-008) |

### US4 — Import existing collection (P2)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Import `test/fixtures/goodreads.csv` (500 rows) | Books created; error report lists skipped rows (row + reason) |
| 2 | `flutter test test/unit/importers/ test/unit/import_service_test.dart` | Each importer + rollback-on-critical-failure green |

### US5 — Continuous batch scanning (P3)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open scanner; scan 10 ISBNs without refocusing | Staging list grows; camera stays active |
| 2 | "Save all" | Books persist; duplicate ISBNs skipped; staging clears |
| 3 | `flutter test test/integration/scan_flow_test.dart` (device) | scan → lookup → stage → assign → save passes |

### US6 — Lending tracker (P3)

| Step | Action | Expected |
|------|--------|----------|
| 1 | "Verleihen an Anna" with a date | "Verliehen an Anna" badge overlays the cover |
| 2 | "Als zurückgegeben markieren" | `returned_at` set; badge clears |

## Success criteria (spec §8)

| Criterion | How to verify |
|-----------|---------------|
| SC-001 100% features work offline | Run US1–US6 in airplane mode |
| SC-002 DNB ≥95% DACH ISBNs | Sprint 2 ISBN corpus test |
| SC-003 1,000-row import <5 s | Time `test/unit/importers/` bulk fixture |
| SC-004 refresh never clobbers edits | `metadata_aggregator_test.dart` |
| SC-005 ≥1 scan/s, 10 scans | US5 on mid-range device |
| SC-006 WCAG AA + 48×48 dp | `flutter analyze` accessibility pass (Sprint 4) |
