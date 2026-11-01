# Feature Specification: OpenShelf — Feedback Round 2 (Navigation, Capture, Statistics, Home)

**Feature Branch**: `feat/openshelf-phase1-2` (continued)
**Created**: 2026-11-01
**Status**: Plan approved by the product owner in chat on 2026-11-01; package 2 (slipcases) pending the data-model confirmation below

## 1. Background

First use of the sideloaded APK on the partner's phone produced ten findings:

| # | Finding | Current state (verified in code) |
|---|---|---|
| R1 | Tag filter is a long row scrolling to the right | `_TagFilterBar` is a horizontal `SingleChildScrollView` of all tags |
| R2 | Default sort should be by title | `LibrarySort()` defaults to `added`, descending |
| R3 | Home page should look like Bookstats: recently added, animated read/unread donut, favourite widgets | The app opens on the library list |
| R4 | The "+" for manual entry is confusing next to scanning | The library FAB opens the manual form directly; scanning is a separate tab |
| R5 | Import/export should not be a main tab | `ImporterScreen` is the fifth bottom-navigation destination |
| R6 | Statistics need tidying, plus new statistics designed by us and, later, user-defined ones | `StatisticsScreen` is a flat list of cards |
| R7 | Averages and records include slipcases (Bookstats data: one slipcase with 1184 pages is the "longest book") | No concept of a slipcase; it is one `Books` row |
| R8 | Drill-down: monthly bars → books of that month → book or filtered library | Bars are not interactive |
| R9 | "Received as" (purchase, gift, loan, …) as field and statistic | No column; the Bookstats column `Erhalten als` (Kauf, Rezensionsexemplar) is ignored |
| R10 | Scanning several books: save all, or adjust them before saving | `ScannerCubit.saveAll` stores the staged metadata unchanged; staged items are not editable |

## 2. Requirements

### Package 1: Quick wins (R1, R2, R5)
- **FR-R2-01** The library's default sort is title, A→Z. Picking a sort still works as before.
- **FR-R2-02** Import and export leave the bottom navigation. The Settings section "Import & export" opens the importer and holds the export actions. The bottom navigation keeps library, shelf, scan and statistics.
- **FR-R2-03** The tag filter is a "Tags" chip at the start of the filter row (with the active count) that opens a sheet. The sheet lists all tags as wrapping chips with a search field. Active tags show as removable chips above the list; with no active tag nothing takes up space. Several active tags still narrow the list (AND).

### Package 2: New book data (R7, R9)
- **FR-R2-04** `Books` gains "received as" (`acquisition`): purchase, gift, loan, review copy, other; nullable. Schema migration with test and snapshot (Constitution II.3), editable in the form, shown in the detail view, in JSON/CSV export and restore (I.3), never overwritten by imports (III.2). The Bookstats importers map `Erhalten als` (Kauf, Geschenk, Leihe/Ausleihe, Rezensionsexemplar, anything else → other).
- **FR-R2-05** *(Proposed, pending confirmation and an architecture review)* A slipcase is a container of volumes. The physical object (ISBN, price, received as/at, location, cover) stays on the slipcase. Every volume is a normal book with its own title, pages, status, reading data and rating. Statistics count volumes, not the slipcase; the price counts once. The slipcase's status is derived from its volumes. An existing entry can be "split into volumes". The library shows a slipcase as one entry with its volume count, expandable.

### Package 3: Capture (R4, R10)
- **FR-R2-06** The library "+" opens a choice with three large options: scan ISBN, enter manually, search online.
- **FR-R2-07** Staged scans show cover, title and author. Tapping one opens an editor before saving. "Save all" can set shared values for all staged books (location, format, status, received as).

### Package 4: Statistics (R6, R7, R8)
- **FR-R2-08** The statistics screen is grouped into sections; the year filter stays on top.
- **FR-R2-09** Averages and records ignore slipcase containers and books without the needed value (e.g. no page count). Reading time includes `Books.readingSeconds` (open item T3-25).
- **FR-R2-10** Drill-down: tapping a month lists that month's finished books; a book opens its detail view, and "show in library" opens the library filtered to them. Status segments do the same for their status.
- **FR-R2-11** New statistics: unread stack ("SUB") per month, books added vs. finished per month, distribution by "received as", spending per year.

### Package 5: Home (R3)
- **FR-R2-12** A new first tab "Home" shows an animated donut of read / reading / unread with the total in the centre (a segment opens the filtered library), the three most recently added books, currently reading with progress, the yearly goal, a mini chart of the unread-stack trend and a row of favourites. Bottom navigation: home, library, scan, statistics, shelf.

### Package 6: User-defined statistics (R6, follow-up)
- **FR-R2-13** *(Later, own spec section once packages 1–5 ship)* Users assemble their own statistics (measure, period, chart type).

## 3. Non-Goals
- Editing or deselecting single rows in the CSV importer (only on request).
- Remembering the last chosen sort across app starts.
- SQLite export (still open from Constitution I.3; separate change).

## 4. Constitution Check
- I.1/I.2: everything works offline; no new network calls (online search already exists and is user-initiated).
- I.3: every new field is part of JSON/CSV export and restore.
- II.3: schema changes come with migrations, tests and snapshots.
- III.2: imports only fill gaps; "received as" entered by the user is never overwritten.
- IV.2: statistics engines get unit tests.
- V: Material 3, 48 dp targets, screen-reader labels for the donut and chart drill-downs, dark/light.
