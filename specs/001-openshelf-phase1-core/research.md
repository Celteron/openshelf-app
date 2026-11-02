# Research — OpenShelf Phase 1

Phase 0 output. Resolves every "NEEDS CLARIFICATION" from the Technical Context and
records the technology decisions that drive the Phase 1 design.

## 1. Persistence: Drift setup & the `sqlite3_flutter_libs` EOL

- **Decision**: Use Drift `^2.35.1` (min Dart 3.10) opened via `drift_flutter`'s
  `driftDatabase(name: 'openshelf')`. Use `drift_dev` + `build_runner` for codegen.
- **Rationale**: `sqlite3_flutter_libs` is EOL (`0.6.0+eol`) and fails to bundle
  `libsqlite3.so` on current Android toolchains (`dlopen failed` at startup). `drift_flutter`
  is the current official path that bundles the native SQLite lib and opens the DB in the
  app documents directory via `path_provider`. It also enables test time `NativeDatabase.memory()`.
- **Alternatives considered**: (a) `drift/native.dart` + `sqlite3_flutter_libs` — rejected
  (EOL). (b) `sqflite` (inherited) — rejected by Constitution Article II (Drift mandated).

## 2. DNB SRU endpoint & MARC21 namespace

- **Decision**: Base URL `https://services.dnb.de/sru/dnb`, query `num=<isbn>`,
  `recordSchema=MARC21-xml`, `maximumRecords=10`, `version=1.1`, `operation=searchRetrieve`.
  Parse with the `xml` package using namespace `http://www.loc.gov/MARC21/slim`.
- **Rationale**: DNB's current catalogue path is `sru/dnb` (not `sru/bib` as written in
  spec §4.5). The bibliographic catalogue is `dnb`; `bib` is not a valid catalogue key.
  Records are `record[@type="Bibliographic"]`. `numberOfRecords` lives in the
  `zs:numberOfRecords` element; `<diagnostic>` signals errors.
- **Alternatives considered**: (a) `sru/bib` — invalid path, would 404. (b) RDF/`oai_dc`
  output — rejected; MARC21-xml gives the full tag set (490/830, 008) required by FR-004.

## 3. ISBN normalization & dedup

- **Decision**: Normalize ISBN-10 → ISBN-13 (EAN prefix `978` + recomputed check digit)
  at every entry point (manual, scanner, importer, lookup). Store `isbn13` (UNIQUE) and
  `isbn10` side by side. Multiple `020 $a` values: prefer the 13-digit form.
- **Rationale**: Dedup (FR-014) and metadata lookup keys are single-valued; 13-digit is
  canonical. Guarded by a pure `isbn.dart` helper with unit tests.
- **Alternatives considered**: Keep raw 10/13 as-is — rejected (duplicate detection fails
  across formats; DNB `num=` accepts both but dedup keys diverge).

## 4. Metadata merge model

- **Decision**: Per-book `edited_fields` column (JSON string-list) records field names the
  user modified. A refresh updates only fields *not* in that set. Merge order is strict:
  base < DNB < Google Books (cover+description only) < Open Library (only still-empty
  fields). Google Books and Open Library never overwrite a non-empty DNB value.
- **Rationale**: Implements Constitution Article III.2 and spec §4.3 deterministically.
- **Alternatives considered**: Timestamp-based last-write-wins — rejected (fails the
  "user edits always win" requirement).

## 5. XML parsing for MARC21

- **Decision**: Use `package:xml` (pure Dart). `Marc21Parser` walks `datafield[@tag]` →
  `subfield[@code]` with a documented tag map (020, 100, 700, 245, 264/260, 300, 490, 830,
  `controlfield 008`). Malformed/truncated XML or missing tags → throw a typed parse error
  that the client converts to `null` (graceful fallback, Article IV.3).
- **Rationale**: `xml` is the standard, well-tested Dart XML package; no native deps.
- **Alternatives considered**: Regex-based extraction — rejected (fragile, violates
  Article IV.1 inline-documentation/robustness).

## 6. Remote clients & offline behavior

- **Decision**: Three thin clients (`DnbClient`, `GoogleBooksClient`, `OpenLibraryClient`)
  over `package:http`, each returning `BookMetadata?` and swallowing HTTP/parse errors into
  `null`. `GoogleBooksClient` extracts a high-res cover URL (replace `http`→`https`, strip
  `edge=curl`) and description. `OpenLibraryClient` reads `jscmd=data` JSON. A `User-Agent`
  header is set on all calls (polite DNB limit: ~60 req/min).
- **Rationale**: Satisfies Article I (network only on explicit action), Article IV.3
  (defensive), and spec §4.6.
- **Alternatives considered**: One combined client — rejected (mixes priority and test
  isolation).

## 7. Cover caching

- **Decision**: `CoverCacheService` downloads cover to
  `getApplicationDocumentsDirectory()/covers/<isbn13>.jpg`, writes `cover_local_path`, and
  returns a `file://` path. Renderers resolve `cover_local_path` first, then `cover_url`.
- **Rationale**: Offline cover browsing (Article III.3, SC-001). `path_provider` is already
  a dependency.
- **Alternatives considered**: `cached_network_image` only — rejected (cache keyed by URL,
  not stable across offline restarts without `cover_local_path`).

## 8. Continuous scanning

- **Decision**: `mobile_scanner` `^7.4.2` with a `MobileScannerController(formats:
  [BarcodeFormat.ean13], detectionSpeed: DetectionSpeed.noDuplicates)`. Decoded ISBN
  pushes to a staging list; camera stays active; duplicate ISBNs (staged or already owned)
  are skipped and surfaced. Lookup runs in a throttled/queued background stream.
- **Rationale**: `mobile_scanner` 7.x supports `DetectionSpeed.noDuplicates` (no manual
  refocus), is maintained, and requires Flutter ≥3.29. Meets SC-005 (≥1 scan/s).
- **Alternatives considered**: `barcode_scan2` (inherited) — rejected (one-shot, no
  continuous no-duplicates mode, less maintained).

## 9. Import pipeline

- **Decision**: `BookImporter` strategy interface emitting `Stream<ImportRow>`; `csv` +
  `dart:convert` for parsing. `ColumnMapper` maps source headers → canonical fields, with a
  UI preview/override. `ImportService` batches inserts at 500/transaction, collects per-row
  errors, and rolls back the current transaction on critical failure. ISBN dedup mirrors
  the scanner rule.
- **Rationale**: FR-010/011/012, SC-003, Article V.2 (minimize blocking). Sample Bookstats
  files committed as `test/fixtures/bookstats/`.
- **Alternatives considered**: Load-all-then-insert — rejected (memory pressure on >10k
  rows).

## 10. Localization (German default + English)

- **Decision**: Keep `easy_localization` (already in the codebase) with `assets/translations`
  JSON. German is the default locale; English is the fallback.
- **Rationale**: The inherited app already uses `easy_localization` and generated
  `LocaleKeys`; migrating to `flutter_localizations`+ARB is avoidable churn with no Phase 1
  benefit.
- **Alternatives considered**: `flutter_localizations`+ARB — rejected (unnecessary
  migration).

## 11. Data export completeness (Article I.3)

- **Decision**: The existing backup/export feature (inherited, `lib/core/helpers/backup`)
  is extended to serialize the new `Locations`, `Series`, and `Lending` tables in addition
  to `Books`, preserving full round-trip export/import.
- **Rationale**: Constitution Article I.3 mandates full export for *every* data-structure
  change. New tables must not be silently excluded.
- **Alternatives considered**: Defer export of new tables — rejected (constitution
  violation).

## 12. Testing strategy

- **Decision**: `NativeDatabase.memory()` for DAO/schema/migration tests (no device
  needed); `http`'s `MockClient` for remote clients; committed MARC21 XML + importer
  fixtures under `test/fixtures/`; integration tests on device for scan/import flows.
- **Rationale**: Article IV.2 requires tests for aggregator, migrations, rating engine.
- **Alternatives considered**: `sqlite3_flutter_libs` in tests — rejected (EOL; in-memory
  native DB is simpler and CI-friendly).

## Open risks / deferred

- Exact DNB `num=` index behaviour for hyphens vs. digits — validate against a known DACH
  ISBN corpus during Sprint 2 (SC-002 targets ≥95%).
- `mobile_scanner` on low-end Android — confirm ≥1 scan/s on a mid-range device (SC-005).
- Bookstats column shapes vary; locked down by committed fixtures + `ColumnMapper` UI
  override (spec §5.3).
