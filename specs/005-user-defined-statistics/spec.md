# Spec 005: User-defined statistics (draft)

Status: **approved with the decisions in section 5** (2026-11-02). Implements FR-R2-20 from spec 004.

## 1. Goal

Users assemble their own statistics tiles: they choose **what** is measured, **how it is grouped**, the **period**, and the **chart type**. The tiles appear in a section "Eigene Statistiken" at the end of the statistics screen, and optionally on the home tab.

Everything is computed on the device from local data (Constitution I.1, I.2). No new network access.

## 2. User stories

- **US1:** As a reader I want "pages per month in 2026 as bars", so that I see my reading rhythm.
- **US2:** As a collector I want "books by genre as a donut", so that I see what my library consists of.
- **US3:** As a buyer I want "spending per year by received-as", so that I see what I bought and what I was given.
- **US4:** As a user I want to start from presets, rename, reorder and delete my tiles.
- **US5:** My tiles survive a backup and restore (Constitution I.3).

## 3. Functional requirements

- **FR-05-01 Measure** (exactly one):
  - number of books
  - pages read
  - reading time (actual time only, FR-R2-24)
  - average rating
  - spending
- **FR-05-02 Grouping** (none or one):
  - month, year
  - status, format, genre, author, location, received-as, tag

  A tile without grouping shows one number.
- **FR-05-03 Period:** all time or a chosen year. Reading measures use the finish date; collection measures (books, spending) use the date added or received.
- **FR-05-04 Filter** (optional): status set, format set, tag set.
- **FR-05-05 Chart type:** number, bar, line (time groupings only), donut (category groupings with at most 8 slices; the rest is grouped as "Other"). The builder offers only the types that fit the chosen grouping.
  - **Tags:** A book counts once per tag. Tag groupings therefore offer only bar charts, never a donut. The tile shows the note "Bücher mit mehreren Tags zählen mehrfach".
- **FR-05-06 Slipcases (ADR-0003):**
  - Reading measures count readable books (singles and volumes).
  - Collection measures (spending, received-as, location) count physical objects.
- **FR-05-07 Drill-down:** Tapping a bar, slice or number lists its books, as in FR-R2-17. Bar charts use the month and category sheet pattern with 48 dp rows.
- **FR-05-08 Management:** create from scratch or from a preset; rename; reorder by drag and drop; delete with an undo snackbar.
- **FR-05-09 Backup:** the JSON export and restore include the tile definitions. CSV export does not; it is book data only.
- **FR-05-10 Accessibility:**
  - Every tile has a semantic summary, e.g. "Seiten pro Monat 2026: Januar 320, …".
  - Colours come from the theme (light and dark).
  - The builder works with a screen reader.

## 4. Design proposal

### 4.1 Domain

A tile definition is a typed value object:

```dart
class StatDefinition {
  final StatMeasure measure;      // enum
  final StatGrouping? grouping;   // enum, null = single number
  final StatPeriod period;        // sealed: AllTime | Year(int)
  final StatFilter filter;        // status/format/tag sets
  final StatChart chart;          // enum
}
```

- **Stable codes:** All enums have stable string codes, like `ReceivedAs`, so stored definitions survive renames.
- **Engine:** `StatQuery.evaluate(definition, books, sessions, tags, {now})` is a pure function. It returns `StatResult` (sealed: `SingleValue | Series(List<(label, value, bookIds)>)`) and runs without a database or framework (Constitution IV.2).
- **Reuse:** The existing helpers `ShelfPartition`, `BookStatistics.finishedOn`, `unreadStackAt` and `GoalProgress.countsForYear` are reused, not duplicated.

### 4.2 Persistence

| Option | Pro | Contra |
|---|---|---|
| **A: Drift table `stat_tiles`** (id, position, title, definition JSON, created_at) | Order and edits are transactional; fits the repository layer; backup through the existing JSON export | Schema v7 with migration and migration test |
| B: one settings key with a JSON list | No schema change | Whole list rewritten on every change; easier to corrupt; settings are not part of every backup path |

**Recommendation: A.** User data belongs in Drift (Constitution II.2), and the migration is additive, so not destructive.
- **Validation:** The definition JSON is validated at the edge. An unknown code drops only that tile and logs nothing to the network.
- **ADR:** [ADR-0005](../../doc/adr/0005-statistik-kacheln-als-drift-tabelle.md) records the decision.

### 4.3 UI

- **Statistics screen:** new last section "Eigene Statistiken" with the tiles and a "+ Statistik" button.
- **Builder:** one screen with four steps (measure → grouping → period/filter → chart and title) and a live preview of the result with the real data.
- **Presets:**
  - pages per month this year
  - books by genre
  - spending per year
  - reading time per month
  - books by format
- **Home tab:** a tile can be pinned to it (part of the first release). The home tab shows at most 3 pinned tiles below the donut.

## 5. Decisions (product owner, 2026-11-02)

1. **Pinning:** Tiles can be pinned to the home tab in the first release.
2. **Periods:** "Year" and "all time" are enough; no "last 12 months".
3. **Tags:** Tags are a grouping. A book counts once per tag, shown as bars only and with a note (see FR-05-05).

## 6. Tasks (once approved)

- [X] **T5-01** `StatDefinition` + codes + JSON round trip + tests.
- [X] **T5-02** `StatQuery.evaluate` for every measure × grouping, including slipcases and empty data + tests.
- [X] **T5-03** Schema v7 `stat_tiles`, migration test v6 → v7, repository + tests.
- [X] **T5-04** JSON backup and restore of the tiles + tests.
- [X] **T5-05** Builder with presets and live preview + widget tests; l10n DE and EN.
- [X] **T5-06** Section on the statistics screen with drill-down, reordering, delete/undo + widget tests.
- [ ] **T5-07** Pinning to the home tab (at most 3 tiles) + widget tests.
