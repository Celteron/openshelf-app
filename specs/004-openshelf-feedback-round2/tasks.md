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

## Package 4: Book data
- [ ] T4-30 "Received as" + cover-search flag: compact columns, migration + test + snapshot, form, detail, export/restore, Bookstats mapping. (FR-R2-07, -08, -10)
- [ ] T4-31 Smaller stored covers. (FR-R2-10)
- [ ] T4-32 Slipcase data model: architecture review, then refine. (FR-R2-09)

## Package 5: Capture & covers
- [ ] T4-40 "+" choice sheet. (FR-R2-11)
- [ ] T4-41 Editable staged scans, shared values on "save all". (FR-R2-12)
- [ ] T4-42 Online cover search. (FR-R2-13)
- [ ] T4-43 Placeholder assets, "Without cover" filter, detail actions, download result with "Show". (FR-R2-14)

## Package 6: Statistics
- [ ] T4-50 Sections, averages/records rules, reading seconds. (FR-R2-15, -16)
- [ ] T4-51 Drill-down month/status → books → library filter. (FR-R2-17)
- [ ] T4-52 Unread stack, added vs. finished, received-as distribution, spending per year. (FR-R2-18)

## Package 7: Home
- [ ] T4-60 Home tab with donut, recently added, reading, goal, unread trend, favourites. (FR-R2-19)

## Package 8: User-defined statistics
- [ ] T4-70 Spec section and design. (FR-R2-20)
