# Feature Specification: OpenShelf — Feedback Round 2 (Navigation, Capture, Statistics, Home)

**Feature Branch**: `feat/openshelf-phase1-2` (continued)
**Created**: 2026-11-01
**Status**: Approved by the product owner in chat on 2026-11-01, including the slipcase model, the cover additions and the import/export and colour findings

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
| R11 | Unclear whether a cover exists online; no online cover search when editing | Placeholders look the same whether or not a lookup ran; the form offers camera and gallery only |
| R12 | Import shows no progress and no clear "done"; a second import needs an app restart | `ImporterCubit` is app-wide and never returns to `ImporterSelecting`; `ImporterImporting.processed` is never updated because `ImportService.import` reports no progress |
| R13 | Import and export should be one screen with two actions | Export tiles live in Settings, the importer is a separate screen |
| R14 | Colour scheme should match the new logo (teal to petrol glass, amber ribbon) | The theme still uses the Openreads accent colours |
| R15 | Data structures as space-saving as possible | Standing product rule from now on |

## 2. Requirements

### Package 1: Quick wins (R1, R2, R5)
- **FR-R2-01** The library's default sort is title, A→Z. Picking a sort still works as before.
- **FR-R2-02** Import and export leave the bottom navigation. The Settings section "Import & export" opens the importer and holds the export actions. The bottom navigation keeps library, shelf, scan and statistics.
- **FR-R2-03** The tag filter is a "Tags" chip at the start of the filter row (with the active count) that opens a sheet. The sheet lists all tags as wrapping chips with a search field. Active tags show as removable chips above the list; with no active tag nothing takes up space. Several active tags still narrow the list (AND).

### Package 2: Import & export (R12, R13)
- **FR-R2-04** One "Import & export" screen, reached from Settings, offers two actions: import and export (JSON backup, CSV).
- **FR-R2-05** The import shows a determinate progress bar (rows done of total). It ends with a clear result: success icon and counts, or the error. Both offer "New import" and "Done". Leaving the screen after a result, or while still mapping, starts the next visit fresh; a running import keeps going and its progress is shown when the screen is opened again.

### Package 3: Colour scheme (R14)
- **FR-R2-06** The default theme derives from the logo: teal/petrol as seed colour, amber as accent, in light, dark and AMOLED. Material You and the custom accent setting keep working. The product owner picks from rendered previews.

### Package 4: Book data (R7, R9, R11, R15)
- **FR-R2-07** `Books` gains "received as": purchase, gift, loan, review copy, other; nullable. Schema migration with test and snapshot (Constitution II.3), editable in the form, shown in the detail view, in JSON/CSV export and restore (I.3), never overwritten by imports (III.2). The Bookstats importers map `Erhalten als` (Kauf, Geschenk, Leihe/Ausleihe, Rezensionsexemplar, anything else → other).
- **FR-R2-08** `Books` remembers that an online cover search found nothing. It is set only when every source answers "not found" (never when offline or timing out), cleared when a cover is set or the cover URL/ISBN changes, kept out of exports (device state), and "Download missing covers" skips flagged books and counts them as without online cover.
- **FR-R2-09** *(ADR-0003)* A slipcase is a container of volumes. The physical object (ISBN, price, received as/at, location, cover) stays on the slipcase. Every volume is a normal book with its own title, pages, status, reading data and rating. Statistics count volumes, not the slipcase; the price counts once. The slipcase's status is derived from its volumes. An existing entry can be "split into volumes". The library shows a slipcase as one entry with its volume count, expandable. A mix of read and unread volumes counts as "reading" and shows "x of n read"; on a split, sessions, notes, review and reading seconds move to volume 1.
- **FR-R2-10** Space: new columns use the most compact type that holds the information (integer codes or booleans instead of text or timestamps, nullable instead of stored defaults), with no derived columns. Cover files are stored downscaled and compressed, because they dominate the app's storage (ADR-0004: fit 720×1080, JPEG q82, existing files compacted once, own photos included).

- **FR-R2-21** *(Later)* An export that includes the cover files, so a full backup restores covers too.

### Package 5: Capture & covers (R4, R10, R11)
- **FR-R2-11** The library "+" opens a choice with three large options: scan ISBN, enter manually, search online.
- **FR-R2-12** Staged scans show cover, title and author. Tapping one opens an editor before saving. "Save all" can set shared values for all staged books (location, format, status, received as).
- **FR-R2-13** The cover actions offer "Search online" next to camera and gallery. It shows the covers found via the ISBN (stored URL, DNB, Google Books, Open Library) and via title and author (other editions on Open Library). The chosen cover is cached and marked as a user edit.
- **FR-R2-14** Two grey placeholder assets: "not searched yet" and "no cover found online". The library has a "Without cover" filter chip, shown only when such books exist. The detail view offers camera, gallery and online search on a missing cover. After "Download missing covers", the result names the books without an online cover and offers "Show", which opens the filtered library.

- **FR-R2-22** *(Feedback during package 5)* The book form shows "reading start" and "reading end" (as the detail page derives them from the sessions) and lets the user change them: the earliest session's start and the latest finished session's end move, the end also sets the finish date; a book without sessions gets one dated session without reading time. Reading times never change.
- **FR-R2-23** *(Feedback during package 5)* A book entered by hand without ISBN can be completed online from its detail page and its form: a search by title and author (Open Library) whose pick fills only empty fields, adds the ISBN and cover, and never overwrites what the user entered.
- **FR-R2-24** *(Feedback during package 6)* Numbers are grouped by the app language ("12.345 Seiten" / "12,345 pages"). Reading time is only time actually read (sessions plus time entered by hand, never the span between start and finish date); overviews such as records show long durations in days, details in hours, minutes and seconds.

### Package 6: Statistics (R6, R7, R8)
- **FR-R2-15** The statistics screen is grouped into sections; the year filter stays on top.
- **FR-R2-16** Averages and records ignore slipcase containers and books without the needed value (e.g. no page count). Reading time includes `Books.readingSeconds` (open item T3-25).
- **FR-R2-17** Drill-down: tapping a month lists that month's finished books; a book opens its detail view, and "show in library" opens the library filtered to them. Status segments do the same for their status.
- **FR-R2-18** New statistics: unread stack ("SUB") per month, books added vs. finished per month, distribution by "received as", spending per year.

### Package 7: Home (R3)
- **FR-R2-19** A new first tab "Home" shows an animated donut of read / reading / unread with the total in the centre (a segment opens the filtered library), the three most recently added books, currently reading with progress, the yearly goal, a mini chart of the unread-stack trend and a row of favourites. Bottom navigation: home, library, scan, statistics, shelf.

### Package 8: User-defined statistics (R6, follow-up)
- **FR-R2-20** *(Later, own spec section once packages 1–7 ship)* Users assemble their own statistics (measure, period, chart type).

## 3. Non-Goals
- Editing or deselecting single rows in the CSV importer (only on request).
- Remembering the last chosen sort across app starts.
- SQLite export (still open from Constitution I.3; separate change).

## 4. Constitution Check
- I.1/I.2: everything works offline; every network call stays tied to a user action (online cover search, download missing covers).
- I.3: every new user-data field is part of JSON/CSV export and restore; the cover-search flag is device state.
- II.3: schema changes come with migrations, tests and snapshots.
- III.2: imports only fill gaps; "received as" entered by the user is never overwritten.
- IV.2: statistics engines get unit tests.
- V: Material 3, 48 dp targets, screen-reader labels for the donut and chart drill-downs, dark/light.
