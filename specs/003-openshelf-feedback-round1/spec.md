# Feature Specification: OpenShelf — Feedback Round 1 (Book fields, Import matcher, Covers)

**Feature Branch**: `feat/openshelf-phase1-2` (continued)
**Created**: 2026-10-08
**Status**: Approved by the product owner in chat (plan + answers on 2026-10-08)

## 1. Background

First hands-on test on SteamOS produced these findings:

| # | Finding | Root cause (verified in code) |
|---|---|---|
| F1 | No genre, price, purchase/received date | `Books` has no such columns; Bookstats genre ends up as a tag, "erhalten am" overwrites `createdAt` |
| F2 | Reading start/end and duration not visible | Data exists as `ReadingSessions`, shown only on the reading screen; no total duration |
| F3 | Book data cannot be copied (e.g. ISBN) | `_MetadataTable` renders plain `Text` |
| F4 | "Edit" below the cover does nothing | `VerificationBadge` is a `Chip` with an edit icon: a status label that looks like a button |
| F5 | No cover for ISBN 9783833874239 | Google Books answers `HTTP 429 RESOURCE_EXHAUSTED` (shared anonymous daily quota); Open Library has no cover (404); DNB has one (`portal.dnb.de/opac/mvb/cover?isbn=`, JPEG) but is not used |
| F6 | Bookstats CSV import shows no matcher | `ImporterCubit.selectFile` jumps straight to a read-only summary; `ColumnMapper` has no UI |
| F7 | Licence | Upstream Openreads is GPL-2.0 without "or later" (LICENSE, no file headers) |

## 2. Requirements

- **FR-F1-01** `Books` gains `genre` (free text, user-editable), `priceCents` (integer, EUR) and `receivedAt` (date). Schema v4, backward-compatible migration, migration test, schema snapshot (Constitution II.3).
- **FR-F1-02** The new fields are editable in the book form, shown in the detail view, included in JSON and CSV export and restored from OpenShelf JSON/CSV backups (Constitution I.3).
- **FR-F1-03** A user-entered genre/price/received date is never overwritten by an import or a metadata merge (Constitution III.2). Imports only fill gaps.
- **FR-F1-04** The Bookstats importers map `Genre` → `genre`, `Erhalten am` → `receivedAt`, and a price column (`Preis`) → `priceCents`. `Kategorie` stays a tag. `createdAt` keeps its current behaviour ("added" date taken from "erhalten am", non-regression); `receivedAt` is filled in addition.
- **FR-F1-05** The detail view shows reading start, reading end and total reading duration derived from the reading sessions.
- **FR-F1-06** Every value in the book detail table is selectable and has a one-tap copy action.
- **FR-F1-07** The verification badge is a non-interactive label (no edit icon).
- **FR-F1-08** Importer shows a column-matching step (header → field, overridable) before a CSV import runs; the result feeds the importer's `ColumnMapper`.
- **FR-F1-09** The explicit "download missing covers" action tries the stored URL (Google Books via the metadata lookup) → DNB cover service → Open Library; HTTP 429 is "source unavailable" and hands over to the next source. Merely displaying a book asks only its stored URL (or Open Library when it has none), so browsing never contacts new third parties (Constitution I.2). All covers are cached locally (III.3).
- **FR-F1-10** Licence: stay on GPL-2.0 for the derivative work (see `doc/adr/0001-lizenz-gpl-2-0.md`) unless the upstream author grants GPL-3.0.
- **FR-F1-11** Settings → Data: "Empty library" asks *trash* (restorable) or *delete for good* (second confirmation); "Delete all data" removes database, cover files and settings after typing a confirmation word. The library offers "select all" in selection mode.
- **FR-F1-12** Rating control shows five stars (left half = .5, right half = full). The whole 300×56 dp bar is one slider-like touch target (tap or drag; the value is saved on release), so Constitution V.3 holds for the control; screen readers get per-half labels and increase/decrease. SnackBars with an undo action dismiss themselves.
- **FR-F1-13** The detail view shows one ISBN row and separates the reading *period* (start → end, in days) from the *time read*; manual sessions take an optional time with unit (minutes/hours) and optional pages; a time without dates is kept in `Books.readingSeconds` (schema v5).
- **FR-F1-14** The importer accepts any CSV ("Custom CSV", last in the detection order); columns are matched by position, and importing requires a title column.
- **FR-F1-15** A book found by a source but without a cover URL gets the DNB cover URL. `GoogleBooksClient` accepts an optional API key (tests/development only; the app passes none).

## 3. Non-Goals

Multi-currency prices (EUR only for now, stored as cents so a currency column can be added later), a Google Books API key setting (candidate follow-up).

## 4. Tests (mandatory per Constitution IV.2)

Migration v3→v4 keeps data; importer fixture for Bookstats genre/price/received; merge never overwrites user values; reading-duration unit tests; matcher cubit tests; cover fallback unit tests with mocked HTTP (no live network in CI).
