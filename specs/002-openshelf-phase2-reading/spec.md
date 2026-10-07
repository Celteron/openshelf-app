# Feature Specification: OpenShelf — Phase 2 (Reading Progress, Notes & Quotes, Tags, Yearly Goal, Wishlist)

**Feature Branch**: `002-openshelf-phase2-reading`
**Created**: 2026-10-07
**Status**: Draft
**Supersedes**: the Phase 1 clarification "Defer reading statistics/progress" (`001/spec.md` §Clarifications, §9).

## 1. Scope & Legacy-Parity Audit

Audit of upstream Openreads (`git show HEAD:lib/model/*`) against OpenShelf Phase 1:

| Capability | Upstream Openreads | OpenShelf Phase 1 | Phase 2 |
|---|---|---|---|
| Per-book reading dates / custom reading time | `Reading{start, finish, customTime}` | — | Reading sessions (superset) |
| Live reading timer, current page, pages/hour | *not in upstream* | — | **New** (requested) |
| Notes | single `notes` text | — | Notes (multiple) |
| Quotes with page number, quick-copy | *not in upstream* | — | **New** (requested) |
| Tags + filter chips | comma-string `tags`, `TagFilterChip` | — | Relational tags + filter chips + management |
| Yearly challenge | `YearlyChallenge{year, books, pages}` | — | Yearly book goal + progress in Statistics |
| Statuses / wishlist | read / in progress / for later / unfinished | enum has wishlist, dnf, reReading but raw `name` labels, no wishlist flow | Localized labels, wishlist→library flow, `finishedAt` |

**Closed in the legacy-superset pass (§8)**: favourites, review text, delete-book UI, list sorting, page goal,
and importing tags/notes/reading dates from Openreads, Goodreads, StoryGraph and Bookstats exports.

## 2. Non-Regression Contract (Phase 1)

DNB/MARC21 engine, metadata queue, location hierarchy, importers, batch scanner, and lending MUST remain
behaviorally unchanged. Phase 2 only adds tables/columns/repositories and additive UI. New capabilities get new
repository interfaces; the legacy-superset pass (§8) additionally extends `BookRepository` with `deleteBook`,
`updateFavorite`, `updateReview` and the atomic `insertImported`.

## 3. User Stories

- **US-A Reading progress (P1)**: Start/stop a live timer on a book; the current page is tracked; each
  session logs duration + pages; reading speed (pages/hour) and history are shown. Starting a session on an
  unread/wishlist book sets it to *reading*; reaching the last page sets it to *read*. Sessions can be logged
  manually and deleted. A running timer survives app restarts (active session = row without `endedAt`).
- **US-B Notes & quotes (P1)**: Per book, add notes and quotes (optional page number), edit, delete, and copy
  a quote/note to the clipboard in one tap.
- **US-C Tags (P2)**: Create/rename/delete tags; assign multiple tags per book; library shows tag filter
  chips (selecting several tags narrows the list: AND semantics); status chips actually filter the list.
- **US-D Yearly goal (P2)**: Set a target number of books for a year; Statistics shows progress, remaining
  books and pace (ahead/behind) based on books *finished* in that year.
- **US-E Wishlist & statuses (P3)**: Localized status labels everywhere; wishlist books show an
  "In Bestand übernehmen" action which moves them to *unread* (owned) without extra dialogs.

## 4. Schema v2 (additive; Constitution II.3)

New columns on `books`: `current_page INTEGER NOT NULL DEFAULT 0`, `finished_at DATETIME NULL`,
`is_favorite BOOLEAN NOT NULL DEFAULT 0`, `review TEXT NULL`.
New tables: `reading_sessions`, `book_notes`, `tags`, `book_tags`, `reading_goals` (with optional
`target_pages INTEGER NULL`); see `tasks.md` T2-02 and T2-16.
`AppDatabase.schemaVersion = 2`; `onUpgrade(from < 2)` adds columns/tables/indexes only. Tested with
drift's `SchemaVerifier` against the committed v1 dump (`drift_schemas/drift_schema_v1.json`) including
data preservation.

## 5. Requirements

- **FR-P2-01** Persist reading sessions with start, end, duration, start/end page; at most one active
  session per book.
- **FR-P2-02** Compute pages/hour from completed sessions with pages > 0 and duration > 0 (pure, unit-tested).
- **FR-P2-03** Starting a session promotes `unread|wishlist|dnf` → `reading`; stopping at/after `pageCount`
  marks the book `read` and sets `finished_at`.
- **FR-P2-04** `finished_at` is set whenever a book transitions into `read` (Library status change included).
- **FR-P2-05** Notes/quotes CRUD per book, ordered newest first; cascade delete with the book.
- **FR-P2-06** Tags unique by case-insensitive name; deleting a tag removes only its assignments.
- **FR-P2-07** Library filter = text query ∧ status ∧ all selected tags ∧ location.
- **FR-P2-08** One goal row per year; progress = books with `status=read` and `finished_at` (fallback
  `created_at`) in that year.
- **FR-P2-09** Full export (JSON v2) includes all new data (Constitution I.3).
- **FR-P2-10** All new strings in `app_de.arb` + `app_en.arb` with identical key sets.
- **FR-P2-11** Tap targets ≥ 48dp, Semantics labels on new controls (Constitution V.3).

## 6. Success Criteria

- `dart analyze`: 0 issues; `flutter test`: 100% pass incl. migration, service, cubit and widget tests.
- Upgrading a populated v1 database to v2 preserves every Phase 1 row.

## 8. Legacy-Superset Pass (Schema v2 importers & UI polish)

Schema v2 had not shipped when these gaps were closed, so the columns above were added to v2 itself (no v3);
the committed dump and the migration tests were regenerated.

- **FR-P2-12** Every importer (Openreads CSV/JSON, Goodreads, StoryGraph, Bookstats CSV/JSON) writes legacy
  notes, tags, reading dates, favourite and review into the v2 tables. A batch is persisted in ONE transaction
  (books + tags + notes + sessions); any failure rolls the whole batch back.
- **FR-P2-13** Imported reading progress is derived, never invented: a book imported as `read` is fully read
  (`current_page = page_count`) and gets the latest finish date as `finished_at`; imported sessions carry no
  page range and no duration unless the source has one (so reading speed is not skewed). A reading with only a
  start date becomes a zero-length completed session, never a running timer.
- **FR-P2-14** CSV import detects the delimiter (`,` `;` tab) and decodes UTF-8 with an ISO-8859-1 fallback.
  Bookstats exports (`;`, ISO-8859-1, `Last, First` authors, `dd.MM.yyyy` dates) are verified against
  `test/Test_Export_BookStats.csv`.
- **FR-P2-15** Book detail: delete with confirmation, favourite toggle, 0.5-step rating (tapping the current
  value clears it) and an editable review.
- **FR-P2-16** Library: sort by title, author (surname first), rating, date added, reading progress with a
  direction toggle, and a favourites filter.
- **FR-P2-17** Yearly goal: optional page goal next to the book goal. The licence is shown as GPL-3.0.
- **FR-P2-18** Re-import is duplicate-safe. A row matches an existing book by ISBN-13, then ISBN-10, then identical
  title + authors (case-insensitive; the title match only when one side has no ISBN-13, because two ISBN-13s are two
  editions). A match is merged, never copied: **only gaps are filled** (empty fields, unrated, unread status, missing
  finish date), new tags/notes/sessions are added, and nothing the user entered is overwritten. The result reports
  *imported*, *updated* (match gained data), *skipped* and *duplicates* (match with nothing new; counted in *skipped*,
  not an error). Duplicates inside one file collapse the same way.
- **FR-P2-19** The licence is **GPL-3.0**: root `LICENSE` is the official GPL-3.0 text and the Settings screen shows
  GPL-3.0. **Open issue:** upstream Openreads declares "GNU General Public Licence v2.0" without an "or later" grant
  (`settings_screen.dart` at `74b613b0`), and Constitution Art. VII.1 / `001/plan.md` still say GPLv2. Relicensing
  derived code needs the copyright holders' consent or an amendment of the constitution; neither is done here.
- **Legacy parity**: see `legacy-parity-audit.md` — OpenShelf is *not* yet a 100 % superset; the audit lists the gaps.
