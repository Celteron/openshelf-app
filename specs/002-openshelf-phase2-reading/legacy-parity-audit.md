# Legacy Parity Audit — Openreads (Phase 0) vs. OpenShelf (Phase 1 + 2)

**Date**: 2026-10-07 · **Baseline (Phase 0)**: upstream commit `74b613b0` (`git show 74b613b0:lib/...`)
**Method**: legacy features were derived from the upstream *source* (enums, screens, `LocaleKeys` used per screen,
models, backup helpers), not from documentation. Each row was checked against the OpenShelf code at `HEAD`.

Legend: ✅ covered · 🟡 partial · ❌ missing · ➕ OpenShelf extension

## Verdict

**OpenShelf is not yet a 100 % functional superset of Openreads Phase 0.** All *data* of the legacy model is
representable except the Open Library ID, and the core library, tags, notes, favourites, reviews, yearly challenge
and import paths are covered or extended. But a number of legacy *UI features* have no counterpart: **cover images,
Open Library search/editions/covers, display types (grid), trash/restore, backup & restore, statistics charts,
appearance settings, and most localizations.** These are listed in §9 as a prioritized backlog.

Two items on the requested parity list are not Phase 0 features at all: the **reading timer** and **quotes** do not
exist in upstream (confirmed in `spec.md` §1); they are OpenShelf additions.

## 1. Books (CRUD & data model)

| Legacy capability (upstream evidence) | OpenShelf | Status |
|---|---|---|
| Add / edit book: title, subtitle, author, description, pages, publication year, ISBN, format (`add_book_screen`) | `features/library/add_book_screen.dart` | ✅ |
| Four formats (paperback/hardcover/ebook/audiobook) | `BookFormat` enum, same four | ✅ |
| Statuses finished / in progress / for later / unfinished (`BookStatus`) | `BookStatus`: unread, reading, read, dnf, wishlist, reReading (+ wishlist → library flow) | ✅ ➕ |
| Delete book | Confirmation dialog, hard delete with cascade (`BookRepository.deleteBook`) | ✅ |
| **Trash: soft delete, restore (`deleted` flag, `trash_screen`)** | none — deletion is permanent | ❌ |
| Favourite (`like_button`, `favourite`) | heart toggle, favourites filter (`isFavorite`) | ✅ |
| Rating, 0.5 steps (`rating` ×10) | `RatingControl`, 0.0–5.0 in 0.5 steps, tap-to-clear | ✅ |
| Rating shown as bar **or** number (`RatingType`) | bar only | ❌ |
| Review (`my_review`) | `Books.review`, editable in detail | ✅ |
| Notes (single text) | multiple notes **and quotes** with page numbers + copy | ✅ ➕ |
| Tags (comma string, filter chips, default tags) | relational tags, management screen, AND filter chips; **default tags setting missing** | ✅ ➕ / ❌ default |
| Reading dates, multiple readings, custom reading time (`Reading`) | reading sessions (start, end, duration, pages), `finishedAt`; legacy readings import as sessions. **No per-reading start/finish date editor** | 🟡 ➕ |
| Date added / modified shown on the book page | stored (`createdAt`/`updatedAt`), sortable by *added*, **not displayed** | 🟡 |
| Open Library ID (`olid`) | no column; not imported | ❌ |
| **Cover images**: camera/gallery/Open Library cover, crop, blurhash (`cover_view_edit`, `search_covers_screen`) | only `coverUrl` is stored; the list/detail show a placeholder icon; `CoverCacheService` exists but is not wired to any screen | ❌ |

## 2. Lookup & search

| Legacy | OpenShelf | Status |
|---|---|---|
| Manual ISBN lookup (Open Library) | ISBN lookup in the add form: DNB → Google Books → Open Library with provenance (`metadata_cubit`, `metadata_aggregator_service`) | ✅ ➕ |
| Local search (title / author / ISBN) | title, subtitle, authors, ISBN-13/10 | ✅ |
| **Open Library search by general / title / author / ISBN / OLID**, editions list, similar books | ISBN only | ❌ |

## 3. Library list

| Legacy | OpenShelf | Status |
|---|---|---|
| Sort: title, author, rating, pages, start date, finish date, publication year, date added, date modified | title, author (surname), rating, date added, reading progress | 🟡 (missing: pages, start date, finish date, publication year, modified) |
| Display types: list, compact list, grid, detailed grid | list only | ❌ |
| One tab per status with its own sort | status filter chips + one sort | 🟡 (different model) |
| Tag filter chips | ✅ (AND semantics) | ✅ |
| **Year filter chip** | none | ❌ |
| Multi-select bulk edit: format, author, delete | bulk **location** assignment only | 🟡 ➕ |

## 4. Reading progress

| Legacy | OpenShelf | Status |
|---|---|---|
| Start / finish reading buttons, quick rating on finish | live timer, current page, manual sessions, auto-promotion to *reading*/*read* | ✅ ➕ (no quick-rating dialog) |

## 5. Statistics

| Legacy (`statistics_screen/widgets`) | OpenShelf | Status |
|---|---|---|
| Books by status | ✅ | ✅ |
| Yearly challenge: books **and pages** | ✅ (page goal added in this pass) | ✅ |
| **Finished books / pages by month (charts)** | none | ❌ |
| **Year selector** | none (goal is for the current year) | ❌ |
| Average rating, average pages, average reading time | none | ❌ |
| Longest / shortest / fastest / slowest book | none | ❌ |
| — | totals, pages read, top locations, top authors, reading speed (pages/h), total reading time | ➕ |

## 6. Settings

| Legacy | OpenShelf | Status |
|---|---|---|
| Theme: system / light / dark | ✅ | ✅ |
| **Accent colour, Material You, AMOLED/natural dark, font** | none | ❌ |
| Language selection (40 translation files) | German + English | 🟡 |
| Default book format / status / tags | none | ❌ |
| Tab order / list order | n/a (no tabs) | ❌ |
| Download missing covers | n/a (no covers) | ❌ |
| About: version, licence, source code, credits | version, licence **GPL-3.0**, credits | ✅ |
| Welcome / onboarding, rate/support/community links | none | ❌ |

## 7. Import, export & backup

| Legacy | OpenShelf | Status |
|---|---|---|
| Import Openreads CSV | ✅ (follows `doc/csv.md`, now incl. favourite/review/notes/tags/readings) | ✅ |
| Import Goodreads CSV | ✅ | ✅ |
| **Import Bookwyrm CSV** | none | ❌ |
| Export CSV (all legacy columns incl. favourite, review, notes, tags, readings) | CSV has only title … format; **JSON export is complete** | 🟡 |
| **Create backup (local / cloud) and restore** | JSON export exists, but **no restore**: OpenShelf's own export cannot be re-imported | ❌ |
| Import legacy Openreads `.backup` archive | not supported (JSON/CSV files only) | ❌ |
| — | StoryGraph and Bookstats import, duplicate merge on re-import | ➕ |

## 8. OpenShelf extensions (Phase 1 + 2) — verified

| Extension | Evidence | Tests |
|---|---|---|
| DNB SRU + MARC21 parser, Google Books, Open Library, field provenance, throttled lookup queue | `data/metadata/*`, `domain/services/metadata_aggregator_service.dart`, `metadata_lookup_queue.dart` | `dnb_client_test`, `marc21_parser_test`, `metadata_aggregator_test`, `metadata_lookup_queue_test` |
| Location hierarchy Room → Shelf → Compartment | `LocationType`, `locations_dao`, `features/locations/*` | `location_repository_test` |
| Continuous batch scanner with staging shelf, dedupe, bulk location | `features/scanner/*` | `integration/scan_flow_test` |
| Lending tracker | `lending_dao`, `lending_cubit`, detail screen section | cascade/export/schema tests; **no dedicated lending repository test** |
| Schema v2 migration | `AppDatabase.onUpgrade`, `drift_schemas/` | `database_v2_migration_test` (SchemaVerifier + data preservation) |
| Duplicate-safe re-import | `BooksDao.importBatch`, `import_merge.dart` | `test/importers/duplicate_import_test.dart` |

## 9. Gap backlog (to reach a true superset), by priority

1. **Backup & restore round-trip** — importer for OpenShelf's own JSON export; legacy `.backup` archive. *(data-loss risk)*
2. **Covers** — display `coverUrl`/cache in list and detail, manual cover from camera/gallery. *(most visible gap)*
3. **Trash** — soft delete + restore, or an explicit decision to keep permanent deletion.
4. **Display types** (compact list, grid, detailed grid) and the remaining **sort fields** (pages, finish date, publication year, modified).
5. **Statistics**: per-month charts, year selector, averages, longest/shortest/fastest/slowest.
6. **CSV export** with all legacy columns; **Bookwyrm** import; `olid` column.
7. **Open Library search** (title/author/OLID), editions, similar books.
8. **Settings**: accent/Material You/AMOLED/font, rating display, default format/status/tags, more languages.
9. Year filter chip, bulk edit (format/author/delete), quick-rating on finish, welcome flow.
