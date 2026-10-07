# Legacy Parity Audit — Openreads (Phase 0) vs. OpenShelf

**Baseline**: upstream `74b613b0`. **Status after the parity pass**: every Openreads capability is covered or
extended, except the documented exceptions in §3. Legend: ✅ covered · ➕ OpenShelf extension · ⛔ exception.

## 1. Covered (evidence in code and tests)

| Legacy capability | OpenShelf |
|---|---|
| Add/edit book, all fields, 4 formats, description | `add_book_screen` (+ description, cover, Open Library id) ✅ |
| Statuses (4) | 6 statuses incl. wishlist ➕ |
| **Trash: soft delete, restore, purge** | `deleted_at` (schema v3), `TrashScreen`, undo snackbar ✅ |
| Favourite, review, notes, tags, default tags | ✅ (notes + quotes, relational tags) ➕ |
| Rating bar **or** number | `RatingDisplay` setting ✅ |
| Quick rating when finishing | dialog on status → read ✅ |
| Reading dates, several readings, custom time | sessions with optional end date, import of `readings` ✅ |
| Date added / modified, OLID | shown in detail, stored, exported ✅ |
| **Covers**: camera/gallery, Open Library, cache, download missing | `CoverCacheService`, `BookCover`, picker, settings action ✅ |
| Open Library search (general/title/author/ISBN/OLID), editions | `OpenLibrarySearchScreen` ✅ |
| Similar books (author / tag) | `SimilarBooksScreen` ✅ |
| **Sorting**: all 9 Openreads + 3 more | 12 criteria with direction ✅ |
| **Display types**: list, compact, grid, detailed grid | toggle + settings ✅ |
| Year filter, tag filter, favourites filter | ✅ |
| Bulk edit: format, author, delete | + location ➕ |
| **Statistics**: by status, challenge (books + pages), by month, year selector, averages, longest/shortest/fastest/slowest | ✅ (+ reading speed, top locations/authors ➕) |
| Challenge books **or** pages | pages-only goals ✅ |
| Theme, accent colour, Material You, AMOLED, 15 fonts | ✅ |
| Import: Openreads CSV/JSON, Goodreads, Bookwyrm, legacy `.backup` ZIP (v4/v5) | ✅ + StoryGraph, Bookstats ➕ |
| **Export/backup + restore** | full JSON backup with restore round trip, full CSV (Openreads columns first) ✅ |

## 2. OpenShelf extensions (Phase 1 + 2)

DNB + Google Books + Open Library pipeline, location hierarchy, batch scanner with staging shelf (with covers),
lending tracker (one active lending, history), reading timer/sessions, duplicate-safe re-import, schema v3 migrations.

## 3. Documented exceptions (not at parity)

- **Languages**: German and English only (Openreads shipped ~40 community translations).
- **Welcome / onboarding screen** and store links (rate/support/community): not applicable to this app.
- **Cover cropping** and the **DuckDuckGo image search**: replaced by gallery, camera and Open Library covers.
- **Legacy backup v3** (SQLite dump from 2022) is not importable; v4/v5 are.
- **Cloud backup**: backups are files (JSON/CSV); no cloud integration.
