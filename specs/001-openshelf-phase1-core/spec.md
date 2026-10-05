# Feature Specification: OpenShelf — Phase 1 (Core Library, Metadata, Import, Locations, Scanner & Lending)

**Feature Branch**: `001-openshelf-phase1-core`

**Created**: 2026-10-05

**Status**: Draft

**Input**: User description: "Build Phase 1 of OpenShelf — a privacy-first, DACH-focused Flutter fork of Openreads for physical library management. Deliver a multi-source metadata engine (DNB SRU → Google Books → Open Library), a modular importer pipeline, a physical location hierarchy (Room → Shelf → Slot), an extended domain model (Series/Lending), a continuous batch scanner, and a lending tracker, plus Drift schema definitions and a 4-sprint task breakdown."

---

## 1. Executive Summary & Revised Architecture

### 1.1 Purpose

OpenShelf is an **offline-first**, privacy-centric mobile application for organizing a
physical book collection. Phase 1 delivers the foundation and the DACH-market
differentiator: accurate, German-language-first metadata via the Deutsche
Nationalbibliothek (DNB), deterministic merging that never clobbers user edits, and a
location model that mirrors how collectors actually shelve books (room → shelf →
compartment).

### 1.2 Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | **Bloc (`flutter_bloc`)** | Already a dependency in the inherited Openreads codebase; enforces the UI / State / Repository separation mandated by the Constitution (Article II). |
| Persistence | **Drift (SQLite)** | Constitution mandates Drift for all DB access. Replaces the inherited `sqflite` layer. |
| Metadata orchestration | **`MetadataAggregatorService`** (facade over strategy sources) | Enforces the fixed priority chain DNB → Google Books → Open Library. |
| Import extensibility | **`BookImporter` strategy interface** | Pluggable parsers, each independently testable. |
| Cover storage | **Local file cache + `cover_local_path` column** | Offline-first: covers must survive without connectivity (Constitution Article III). |
| Package id | `de.openshelf.app` | New applicationId (Android) / bundle id (iOS) — see Assumptions. |

### 1.3 Service Boundaries (layered)

```text
Presentation (Material 3 widgets, routes/screens)
        │  events / states
State (Cubits/Blocs: Library, Metadata, Scanner, Importer, Locations, Lending)
        │  calls
Domain (repositories — abstract interfaces, pure models)
        │  implementations
Data  ──┬─ Drift DAOs → SQLite (AppDatabase)
        └─ Remote clients (DnbClient, GoogleBooksClient, OpenLibraryClient)
           + parsers (Marc21Parser) + CoverCacheService
```

**Boundary rule:** presentation code MUST NOT import `package:drift` or HTTP clients
directly. All data access crosses a repository interface. Remote network calls are
permitted only in the metadata/import flows and MUST degrade gracefully offline
(Constitution Articles I & III).

---

## Clarifications

### Session 2026-10-05

- Q: Should reading statistics and reading-progress tracking be included in Phase 1, or deferred? → A: Defer (Option A) — Phase 1 delivers library, metadata, import, locations, series, scanner, and lending only; reading statistics/progress is deferred to a later phase.
- Q: How should the system decide which fields may be auto-updated after a manual edit? → A: Per-field tracking (Option A) — store a "user-edited fields" set; refresh updates only unedited fields.
- Q: What happens when deleting a location that has children or assigned books? → A: Block deletion (Option A) — the user must move/empty it first; no silent orphaning.
- Q: Are there sample Bookstats files to build/test the importer against? → A: Yes (Option A) — the user will provide sample Bookstats CSV/JSON files (uploaded to the repo separately); importer + fixture tests are built against real data.
- Q: Which UI languages should OpenShelf support in Phase 1? → A: German + English (Option B) — German default, English fallback.

---

## 2. User Scenarios & Testing *(mandatory)*

### User Story 1 — Private offline library (Priority: P1) 🎯 MVP

A user adds books manually or by ISBN and browses/edits them entirely offline.

**Why this priority**: The library is the product's core; every other story builds on it.

**Independent Test**: Install with airplane mode on, add three books, relaunch, confirm
they persist and are searchable — no network required.

**Acceptance Scenarios**:

1. **Given** no network, **When** the user adds a book manually (title + author + ISBN),
   **Then** the book is saved and appears in the library list.
2. **Given** books exist, **When** the user searches locally, **Then** matching books are
   returned in under 300 ms without connectivity.
3. **Given** a book's `rating` is set to 3.5, **When** reopened, **Then** the 0.5-step
   rating persists exactly.

### User Story 2 — DACH metadata enrichment (Priority: P1)

A user scans/looks up an ISBN; DNB provides authoritative German bibliographic data,
Google Books fills cover/description, and user edits are never overwritten.

**Why this priority**: This is the DACH-market differentiator and the reason users switch.

**Independent Test**: Look up a known DNB ISBN (e.g. a German-language title) offline→online
transition and verify fields, source attribution, and cover caching.

**Acceptance Scenarios**:

1. **Given** an ISBN present in DNB, **When** lookup runs, **Then** title, subtitle,
   author, publisher, year, page count, series, and volume are populated from DNB and
   the book shows a **DNB-verified badge**.
2. **Given** DNB returns data, **When** Google Books is queried, **Then** only missing
   cover URL and description are filled — never overwriting DNB values.
3. **Given** a user has hand-edited the title, **When** metadata refresh runs, **Then** the
   edited title is preserved and other fields may update.
4. **Given** a cover URL was fetched, **When** the device goes offline, **Then** the cover
   still renders from local cache.
5. **Given** a MARC21 record with tags 490/830, **When** lookup completes, **Then** a
   `Series` entry is created/linked and `series_volume` is set automatically.

### User Story 3 — Physical location hierarchy & batch assignment (Priority: P2)

A user models Room → Shelf → Slot and bulk-assigns books to a location.

**Why this priority**: Core value for "best physical library organization".

**Independent Test**: Create a room, a shelf under it, a slot under that; select 5 books
and reassign them to the slot in one action.

**Acceptance Scenarios**:

1. **Given** no locations, **When** the user creates "Wohnzimmer" (room), then "Billy Links"
   (shelf), then "Fach 2" (compartment) as children, **Then** the tree renders in order.
2. **Given** N selected books, **When** "assign to location" runs, **Then** all N `location_id`
   values update in a single transaction.

### User Story 4 — Import existing collection (Priority: P2)

A user migrates from Openreads/Goodreads/StoryGraph/Bookstats via CSV/JSON.

**Why this priority**: Unblocks "ex-Bookstats users"; native Openreads migration is the
first-class path.

**Independent Test**: Import a 500-row Goodreads CSV fixture and verify books + error report.

**Acceptance Scenarios**:

1. **Given** an Openreads CSV export, **When** imported, **Then** books are created with
   correct status/rating mappings.
2. **Given** a malformed row, **When** import runs, **Then** the row is skipped and logged
   (row number + reason) without aborting the import.
3. **Given** a critical mid-import failure, **When** it occurs, **Then** the transaction
   rolls back and no partial books are persisted.

### User Story 5 — Continuous batch barcode scanning (Priority: P3)

A user scans ISBNs rapidly; the camera stays active and books accumulate on a staging
shelf for review and bulk save.

**Why this priority**: High throughput for physical collectors; lower risk than core flows.

**Independent Test**: Scan 10 ISBNs without tapping to refocus; verify staging list grows
and a single "save all" persists them.

**Acceptance Scenarios**:

1. **Given** the scanner is open, **When** an ISBN is decoded, **Then** the book is added
   to staging and the camera keeps scanning without further input.
2. **Given** staged books, **When** "save all" runs, **Then** books persist, duplicates by
   ISBN are skipped, and staging clears.
3. **Given** staged books, **When** the user bulk-assigns a location, **Then** the
   assignment applies to all staged books on save.

### User Story 6 — Lending tracker (Verleihverwaltung) (Priority: P3)

A user records who borrowed a book and when, and sees a badge on the cover.

**Why this priority**: Differentiator, but safe to defer to final sprint.

**Independent Test**: Mark a book "Verliehen an Anna", verify badge, then mark returned.

**Acceptance Scenarios**:

1. **Given** a book, **When** "Verleihen" sets a borrower + date, **Then** a "Verliehen an
   [Name]" badge overlays the cover in the list.
2. **Given** a lent book, **When** "Als zurückgegeben markieren" runs, **Then** `returned_at`
   is set and the badge clears.

### Edge Cases

- ISBN with 10 vs 13 digits; ISBN-10 conversion to ISBN-13 before dedup/lookup.
- Multiple `020$a` ISBNs in one MARC21 record (select 13-digit preferentially).
- DNB SRU returns `numberOfRecords = 0` or a `<diagnostic>` error element.
- Malformed MARC21/JSON responses (truncated XML, wrong encoding) → graceful fallback.
- Google Books returns no volume or a generic cover placeholder → skip cover, keep metadata.
- Duplicate scan of an already-owned ISBN → skip and surface "already in library".
- A location deleted while it still has child locations/books → deletion is BLOCKED (user must move/empty it first); no silent orphaning.
- Two books sharing an ISBN (different editions) → warn, do not silently merge.
- Very large imports (>10k rows) → chunked batch inserts to avoid UI freeze and memory pressure.

---

## 3. Drift SQLite Schemas & Migration Strategy

### 3.1 Enumerations

```dart
enum BookStatus    { unread, reading, read, dnf, wishlist, reReading }
enum BookFormat    { hardcover, paperback, ebook, audiobook }
enum LocationType  { room, shelf, compartment }
enum MetadataSource{ dnb, googleBooks, openLibrary, manual }
```

### 3.2 Table Definitions

```dart
// lib/data/database/tables.dart
import 'dart:convert';
import 'package:drift/drift.dart';

/// Stores `List<String>` (authors) as a JSON text column.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  @override List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<dynamic>).cast<String>();
  @override String toSql(List<String> value) => jsonEncode(value);
}

@TableIndex(name: 'idx_books_isbn10',   columns: {#isbn10})
@TableIndex(name: 'idx_books_location', columns: {#locationId})
@TableIndex(name: 'idx_books_status',   columns: {#status})
@TableIndex(name: 'idx_books_series',   columns: {#seriesId})
class Books extends Table {
  IntColumn get id          => integer().autoIncrement()();
  TextColumn get isbn13     => text().nullable().unique()();   // unique; NULL allowed (no ISBN)
  TextColumn get isbn10     => text().nullable()();
  TextColumn get title      => text()();
  TextColumn get subtitle   => text().nullable()();
  TextColumn get authors    => text().map(const StringListConverter())();
  TextColumn get publisher  => text().nullable()();
  IntColumn get publishedYear => integer().nullable()();
  IntColumn get pageCount   => integer().nullable()();
  TextColumn get format     => textEnum<BookFormat>().nullable()();
  TextColumn get language   => text().nullable()();
  TextColumn get status     => textEnum<BookStatus>().withDefault(const Constant('unread'))();
  RealColumn get rating     => real().withDefault(const Constant(0.0))();   // 0.0–5.0, 0.5 steps
  IntColumn get locationId  => integer().nullable().references(Locations, #id)();
  IntColumn get seriesId    => integer().nullable().references(Series, #id)();
  RealColumn get seriesVolume => real().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get coverUrl     => text().nullable()();
  TextColumn get coverLocalPath => text().nullable()();
  TextColumn get metadataSource => textEnum<MetadataSource>().nullable()();
  TextColumn get editedFields => text().map(const StringListConverter())(); // user-edited field names
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Locations extends Table {
  IntColumn get id        => integer().autoIncrement()();
  TextColumn get name     => text()();
  TextColumn get type     => textEnum<LocationType>()();               // room | shelf | compartment
  IntColumn get parentId  => integer().nullable().references(Locations, #id)(); // self-ref hierarchy
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Series extends Table {
  IntColumn get id                 => integer().autoIncrement()();
  TextColumn get name              => text().unique()();
  IntColumn get totalPlannedVolumes => integer().nullable()();
}

@TableIndex(name: 'idx_lending_book', columns: {#bookId})
class Lending extends Table {
  IntColumn get id             => integer().autoIncrement()();
  IntColumn get bookId         => integer().references(Books, #id)();
  TextColumn get borrowerName  => text()();
  DateTimeColumn get lentAt    => dateTime()();
  DateTimeColumn get expectedReturn => dateTime().nullable()();
  DateTimeColumn get returnedAt     => dateTime().nullable()();
}
```

### 3.3 Database & Foreign Keys

```dart
// lib/data/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Books, Locations, Series, Lending])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Stepwise, backward-compatible migrations ONLY. No destructive ops.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
```

### 3.4 Foreign Key Rules & Indices

- `Books.locationId → Locations.id` (`ON DELETE SET NULL`, nullable) — deleting a location
  must NOT delete books. Deletion of a location that still has children or assigned books is
  BLOCKED until it is emptied (prevents orphaning child locations).
- `Books.seriesId → Series.id` (`ON DELETE SET NULL`).
- `Lending.bookId → Books.id` (`ON DELETE CASCADE`) — deleting a book removes its lending rows.
- Indexes: `idx_books_isbn10`, `idx_books_location`, `idx_books_status`, `idx_books_series`,
  `idx_lending_book`. `isbn13` is covered by its UNIQUE constraint.

### 3.5 Migration Strategy (Constitution Article II — Migration Safety)

- Schema version starts at `1`. Future changes increment the version and add an `onUpgrade`
  branch per version step.
- Destructive changes (dropping/redefining columns or tables) are **prohibited** unless a
  backward-compatible migration script and tests accompany them.
- **Legacy Openreads data**: because the package id changes to `de.openshelf.app`, the OS
  data sandbox differs from the upstream app — an in-place `sqflite`→Drift migration is not
  possible. Migration is via **export/import** (User Story 4) instead. See Assumptions.

---

## 4. Metadata Aggregator & DNB MARC21 Parser Specification

### 4.1 Priority Chain (fixed)

```text
1. DNB SRU (MARC21-XML)   → authoritative bibliographic fields
2. Google Books (JSON)     → enrichment only: cover URL (high-res) + description
3. Open Library (JSON)     → fallback when 1 and 2 yield nothing
```

### 4.2 Class Contracts

```dart
class BookMetadata {
  final String? isbn13, isbn10, title, subtitle, publisher, language, description;
  final List<String> authors;
  final int? publishedYear, pageCount;
  final BookFormat? format;
  final String? coverUrl;
  final String? seriesName;
  final num? seriesVolume;
}

abstract class MetadataSource {
  MetadataSource get id;                       // dnb | googleBooks | openLibrary
  Future<BookMetadata?> lookupByIsbn(String isbn13);
}

/// Orchestrates sources in strict order and merges deterministically.
abstract class MetadataAggregatorService {
  Future<AggregatedMetadata> enrich(BookMetadata base, {bool preserveUserEdits = true});
}
```

### 4.3 Deterministic Merge Rules

1. **User edits always win.** A per-book `edited_fields` set records exactly which fields
   the user has modified; a refresh updates only fields NOT in that set.
2. **Higher-priority source wins.** DNB fields are authoritative; Google Books MUST only
   fill fields still empty after DNB (cover URL, description).
3. **No silent overwrite.** A source value never replaces a non-empty higher-priority value
   without explicit, per-attribute user consent.

### 4.4 MARC21 Tag Mappings (DNB SRU)

| MARC tag / subfield | OpenShelf field | Notes |
|---------------------|-----------------|-------|
| `020 $a` | `isbn13` / `isbn10` | Multiple values; prefer 13-digit, keep 10-digit. |
| `100 $a` | `authors[0]` | Primary author (person). |
| `700 $a` | `authors[1..]` | Additional authors. |
| `245 $a` | `title` | |
| `245 $b` | `subtitle` | |
| `245 $c` | (optional) | Statement of responsibility — ignored for v1. |
| `264 $b` (fallback `260 $b`) | `publisher` | |
| `264 $c` (fallback `260 $c`) | `publishedYear` | Parse leading `YYYY`. |
| `300 $a` | `pageCount` | Parse leading integer from extent ("412 Seiten"). |
| `490 $a` | `seriesName` | Series statement. |
| `490 $v` | `seriesVolume` | Volume number. |
| `830 $a` / `830 $v` | `seriesName` / `seriesVolume` | Authoritative form; overrides 490 when present. |
| `008` (pos 35–37) | `language` | ISO 639-2 code. |

### 4.5 Endpoints

- **DNB SRU**: `https://services.dnb.de/sru/bib?version=1.1&operation=searchRetrieve&query=num%3D{isbn}&recordSchema=MARC21-xml&maximumRecords=10`
- **Google Books**: `https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}`
- **Open Library**: `https://openlibrary.org/api/books?bibkeys=ISBN:{isbn}&format=json&jscmd=data`

### 4.6 Error Handling & Local Image Caching

- `DnbClient` MUST detect `numberOfRecords = 0`, `<diagnostic>` elements, HTTP errors, and
  malformed XML, returning `null` so the next source runs (never throw past the service).
- `CoverCacheService` downloads the cover to the app documents directory and stores its path
  in `cover_local_path`; the list/detail renderers resolve `cover_local_path` first.

---

## 5. Importer Pipeline Architecture

### 5.1 Strategy Interface

```dart
enum ImportFileType { csv, json }

abstract class BookImporter {
  String get formatName;                       // "Openreads CSV", "Goodreads CSV", ...
  ImportFileType get supportedType;
  bool canParse(ImportFile file);              // format detection (header/ext shape)
  Stream<ImportRow> parse(ImportFile file);    // row-by-row; emits ImportRow
}

class ImportRow {                              // one row = one candidate book
  final int rowNumber;
  final BookMetadata? book;
  final String? error;                         // per-row error (skipped rows)
}
```

### 5.2 Implementations

| Importer | Type | Notes |
|----------|------|-------|
| `OpenreadsCsvImporter` | CSV | Native migration — status/rating column mapping. |
| `OpenreadsJsonImporter` | JSON | Native migration. |
| `GoodreadsCsvImporter` | CSV | Maps "Title", "Author", "ISBN", "My Rating", "Bookshelves". |
| `StoryGraphCsvImporter` | CSV | Maps "Title", "Authors", "ISBN/UID", "Rating". |
| `BookstatsCsvImporter` / `BookstatsJsonImporter` | CSV/JSON | Legacy Bookstats format; column mapper required. |

### 5.3 Mapping Rules (Goodreads & Bookstats)

- **Goodreads**: `Book Id`, `Title`, `Author` (may contain multiple authors separated by
  `,`), `Additional Authors`, `ISBN`, `ISBN13`, `My Rating` (1–5 → 0.5-step), `Exclusive
  Shelf` (`read`/`currently-reading`/`to-read` → `read`/`reading`/`wishlist`), `Number of
  Pages`.
- **Bookstats**: legacy German columns vary; resolved via the flexible `ColumnMapper`, which
  maps source headers to canonical fields and lets the user confirm/override the mapping in
  the UI before import. Sample Bookstats CSV/JSON files (provided separately) MUST be added
  as test fixtures under `test/fixtures/bookstats/` to lock down the mappings.

### 5.4 `ImportService`

- Accepts a parsed `Stream<ImportRow>`, batches inserts (chunked, e.g. 500/transaction),
  collects per-row errors into a report, and rolls back the current transaction on any
  critical failure (Constitution Article III/IV).
- Duplicate ISBN detection mirrors the scanner's dedup rule (skip + report).

---

## 6. UI/UX Screen Mapping & State Specifications

### 6.1 "Mein Regal" — Location Tree View

- **Layout**: expandable tree (Room → Shelf → Compartment) rendered from `Locations`
  self-references; a flat book grid for the selected node; FAB for "add book" and "add
  location".
- **State**: `LocationTreeCubit` (load tree, expand/collapse, select node) + `LibraryCubit`
  (books of selected node, search query, status filter).
- **Batch**: long-press to enter selection mode; multi-select → "assign to location" sheet.

### 6.2 Continuous Batch Scanner View

- **Layout**: full-screen camera preview (via `mobile_scanner`), a live counter, and a
  collapsible "Staging Shelf" panel; persistent "save all" CTA.
- **State**: `ScannerCubit` — `idle | scanning | staging | saving`. ISBN decode pushes to a
  staging list without leaving the camera. Lookup runs in background (throttled/queued).

### 6.3 Book Details (DNB Verification Badge)

- **Layout**: cover (with lending badge overlay), title/subtitle, authors, metadata table,
  rating control (0.5 steps), status selector, series/volume, location, "refresh metadata".
- **State**: `BookDetailCubit` — load book, run lookup, render merge preview.
- **Badge**: a "DNB-verifiziert" chip shows when `metadataSource == dnb` and metadata is
  unmodified; user edits change the badge to "bearbeitet".

### 6.4 Importer Screen

- **Layout**: file picker (CSV/JSON), auto-detected format name, a **column mapping preview**
  table (source header → target field), and an "import" run with a live progress/error log.
- **State**: `ImporterCubit` — `selecting | mapping | importing | done(report)`.

### 6.5 State Management Map (Bloc)

| Cubit/Bloc | Responsibilities |
|------------|------------------|
| `LibraryCubit` | list/filter/search books, status/rating edits |
| `MetadataCubit` | lookup orchestration, merge preview |
| `ScannerCubit` | continuous scan + staging shelf |
| `ImporterCubit` | import lifecycle + column mapping |
| `LocationTreeCubit` | location CRUD, hierarchy, batch assignment |
| `LendingCubit` | lend / mark returned |
| `SeriesCubit` | series lookup/merge |

---

## 7. Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST persist books locally via Drift and remain fully functional offline.
- **FR-002**: System MUST support manual book entry (title, subtitle, authors, ISBN-10/13,
  publisher, year, page count, format, language, status, rating, location, series).
- **FR-003**: System MUST resolve metadata in the fixed order DNB SRU → Google Books → Open
  Library (Article III).
- **FR-004**: System MUST parse MARC21 tags 020/100/245/264/300/490/830 into the book model.
- **FR-005**: System MUST track user-edited fields per book and preserve them during any
  metadata refresh (refresh updates only unedited fields).
- **FR-006**: System MUST cache remote cover images locally and render them offline.
- **FR-007**: System MUST auto-create/link `Series` from MARC21 490/830 on scan.
- **FR-008**: System MUST support a self-referential Room → Shelf → Compartment hierarchy,
  and MUST block deletion of a location that still has children or assigned books.
- **FR-009**: System MUST bulk-assign N selected books to one location in a single transaction.
- **FR-010**: System MUST import Openreads CSV/JSON, Goodreads CSV, StoryGraph CSV, and
  Bookstats CSV/JSON.
- **FR-011**: System MUST provide a flexible column mapper and per-row error logging.
- **FR-012**: System MUST roll back a batch import on critical failure.
- **FR-013**: System MUST support continuous scanning with a staging shelf and single
  "save all".
- **FR-014**: System MUST deduplicate scanned/imported books by ISBN.
- **FR-015**: System MUST track lending (borrower, lent date, expected return, returned).
- **FR-016**: System MUST show a lending badge overlay on covers and one-tap lend/return.
- **FR-017**: System MUST enforce Material Design 3, dark/light themes, and responsive
  mobile/tablet layouts (Article V).
- **FR-018**: System MUST provide ≥48×48 dp tap targets, high-contrast text, and screen
  reader labels on interactive elements (Article V).
- **FR-019**: System MUST support German (default) and English UI localizations in Phase 1.

### Key Entities

- **Book**: the bibliographic + ownership record (fields per §3.2).
- **Location**: a node in the Room/Shelf/Compartment tree (self-referential).
- **Series**: a named sequence with optional planned volume count.
- **Lending**: a borrow event linked to one book, with optional return timestamp.

---

## 8. Success Criteria *(mandatory)*

- **SC-001**: 100% of Phase 1 features (library, local search, metadata of cached books,
  import, locations, scanner, lending) work with airplane mode enabled.
- **SC-002**: DNB ISBN lookup resolves correctly for ≥95% of valid DACH ISBNs in test corpus.
- **SC-003**: A 1,000-row import completes in under 5 s on a mid-range device with a
  complete per-row error report.
- **SC-004**: Metadata refresh never overwrites a user-edited field (verified by test).
- **SC-005**: Batch scanner sustains ≥1 scan/second with no manual refocus for 10 scans.
- **SC-006**: All interactive elements pass WCAG 2.1 AA contrast and 48×48 dp target checks.

---

## 9. Assumptions & Licensing

- **Target users**: DACH-region physical book collectors, including ex-Bookstats users.
- **Out of scope (Phase 1)**: Reading statistics and reading-progress tracking (charts,
  reading dates/time, pages/day) are deferred to a later phase; the `Book` model omits
  reading-progress fields in Phase 1.
- **SDK bump**: The inherited `pubspec.yaml` pins Dart `>=2.18.2 <3.0.0` and uses `sqflite`.
  Phase 1 requires upgrading to the latest stable Flutter/Dart and adding Drift; `sqflite`
  is removed in favor of Drift.
- **Package rename**: `de.openshelf.app` becomes the Android `applicationId` / iOS bundle id.
  This changes the data sandbox, so legacy Openreads data is migrated via export/import, not
  an in-place DB migration.
- **No accounts, no telemetry**: consistent with Constitution Article I; network use is
  limited to metadata lookup and cover retrieval.
- **Bookstats samples**: Sample Bookstats CSV/JSON files will be provided separately and
  committed as test fixtures; the importer is built and tested against them (see §5.3).
- **Licensing**: The inherited codebase is licensed under the **GNU GPL v2** (see `LICENSE`,
  which matches upstream Openreads). Phase 1 introduces no license change; all new OpenShelf
  code MUST remain GPLv2-compatible open source. *(Note: this supersedes any prior reference
  to GPLv3; the actual upstream license is GPLv2.)*
