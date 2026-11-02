# Tasks: OpenShelf Feedback Round 2

Legend: `[X]` done, `[ ]` open. Each task traces to FR-R2-xx in `spec.md`. Packages 2–6 are refined into atomic tasks when they start.

## Package 1: Quick wins
- [X] T4-01 `LibrarySort()` defaults to title A→Z + tests. (FR-R2-01)
- [X] T4-02 Bottom navigation without the importer; the Settings section "Import & export" opens the importer first, then the exports + widget test. (FR-R2-02)
- [X] T4-03 Tag filter: "Tags (n)" chip first in the filter row, sheet with search and wrapping chips, removable active chips above the list + widget tests; l10n DE + EN. (FR-R2-03)
- [X] T4-04 Version 2.12.0+60, release APK.

## Package 2: Import & export
- [X] T4-10 `ImportService.import(onProgress:)`, cubit parses up front and emits done/total + tests. (FR-R2-05)
- [X] T4-11 `ImporterCubit.reset()` (ignores a running import); result and error views with "New import" / "Done"; reset when the screen closes + tests. (FR-R2-05)
- [X] T4-12 `ImportExportScreen` with both actions (export tests moved from Settings); Settings → Data links to it + tests; l10n DE + EN; version 2.13.0+61. (FR-R2-04)

## Package 3: Colour scheme
- [X] T4-20 Rendered previews of three candidates (A petrol glass, B lagoon, C night shelf); the product owner chose A. (FR-R2-06)
- [X] T4-21 Brand scheme (fidelity petrol, amber tertiary, petrol-tinted dark surfaces), glass component themes, navigation icon contrast ≥ 3:1, stars/favourites/badges from the scheme instead of fixed colours + tests; version 2.14.0+62. (FR-R2-06)

## Package 4a: Book data and covers
- [X] T4-30 `ReceivedAs` enum with pinned codes + converter + tests. (FR-R2-07, -10)
- [X] T4-31 Schema v6: `received_as`, `cover_not_found`, `parent_id`; migration tests v1..v5 → v6, snapshot, helpers. (FR-R2-07..10)
- [X] T4-32 "Received as" data flow: merge, JSON/CSV export and restore, Bookstats mapping, form, detail, l10n. (FR-R2-07)
- [X] T4-33 `CoverFetch` result (found / not found / failed) + tests. (FR-R2-08)
- [X] T4-34 Cover flag: set by "download missing covers", cleared by the repository, no passive lookup when set + tests. (FR-R2-08)
- [X] T4-35 `compactCover` in every cover write, scanner shrink removed + tests. (FR-R2-10)
- [X] T4-36 One-off compaction of existing cover files + tests. (FR-R2-10)
- [X] T4-37 Version bump, release APK (2.15.0+63, 2.15.1+64).

## Package 4b: Slipcases (ADR-0003)
- [X] T4-38 `ShelfPartition`, `slipcaseStatus` + tests. (FR-R2-09)
- [X] T4-39 Statistics and goal over readable/physical sets + tests. (FR-R2-09)
- [X] T4-3A Trash semantics for containers and volumes + tests. (FR-R2-09)
- [X] T4-3B "Split into volumes" (repository + UI) + tests. (FR-R2-09)
- [X] T4-3C Import/export of the relation, scoped duplicate matching + tests. (FR-R2-09)
- [X] T4-3D Library grouping (slipcase entries with `volumes` map instead of a sealed `LibraryEntry`: same expressiveness, no churn in selection/grid), expandable slipcase entry, grouped trash + tests. (FR-R2-09)

## Package 5: Capture & covers
- [X] T4-40 "+" choice sheet. (FR-R2-11)
- [X] T4-41 Editable staged scans, shared values on "save all". (FR-R2-12)
- [X] T4-42 `CoverSearchScreen` (stored URL, DNB, Open Library by ISBN, other editions by title + author), "Search online" in the book form, cached download, picked cover counts as an edit, nothing found sets the cover flag + tests. (FR-R2-13)
- [X] T4-43 Placeholders (not searched / none online), "Without cover" chip, cover actions (camera, gallery, online) on the detail screen of a book without cover, "Show" after "download missing covers" + tests. (FR-R2-14)
- [X] T4-44 Edit reading start/end in the book form + tests. (FR-R2-22)
- [X] T4-45 "Complete online" card on the detail screen of books without ISBN opens the form with the Open Library search (title + first author); a saved book only gets its empty fields and a missing cover filled + tests. (FR-R2-23)

## Package 6: Statistics
- [X] T4-50 Sections (overview, reading, averages & records, library) below the year filter; averages/records over readable books with a value; actual reading time only (sessions + manual) + tests. (FR-R2-15, -16)
- [X] T4-53 Locale number grouping (statistics totals, page counts, goal pages), durations in days / h min / s + tests. (FR-R2-24)
- [X] T4-51 Month bars and status rows open their books, a book opens its detail, "show in library" switches to the library filtered to them (removable selection chip) + tests. (FR-R2-17)
- [X] T4-52 Unread stack at month end, books added per month (next to finished), received-as distribution and spending per year over physical objects + tests. (FR-R2-18)

## Package 7: Home
- [X] T4-60 Home tab first (home, library, scan, statistics, shelf): animated donut read/reading/unread with total, segment or legend row opens the filtered library, goal, currently reading with progress, three recently added, six-month unread trend, favourites + tests. (FR-R2-19)

## Package 8: User-defined statistics
- [X] T4-70 Spec and design draft in `specs/005-user-defined-statistics/spec.md`; open questions for the product owner listed there. (FR-R2-20)
