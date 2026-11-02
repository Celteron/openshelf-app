# Data Model — OpenShelf Phase 1

Phase 1 output. Source of truth for entities, fields, relationships, enums, validation,
and state transitions. The authoritative Drift table definitions are in
`lib/data/database/tables.dart` (spec §3.2); this document adds semantics, validation
rules, and transitions that drive the repository/domain layer.

## 1. Enumerations

| Enum | Values | Notes |
|------|--------|-------|
| `BookStatus` | `unread`, `reading`, `read`, `dnf`, `wishlist`, `reReading` | default `unread` |
| `BookFormat` | `hardcover`, `paperback`, `ebook`, `audiobook` | nullable |
| `LocationType` | `room`, `shelf`, `compartment` | hierarchy depth = level in tree |
| `MetadataSource` | `dnb`, `googleBooks`, `openLibrary`, `manual` | nullable; drives verification badge |
| `ImportFileType` | `csv`, `json` | importer capability |

`BookStatus` and `BookFormat` are retained from the inherited Openreads model; new enums
`LocationType`, `MetadataSource`, `ImportFileType` are introduced in Phase 1.

## 2. Entities

### 2.1 Book

The bibliographic + ownership record.

| Field | Type | Null | Default | Rules |
|-------|------|------|---------|-------|
| `id` | int (PK, autoincrement) | no | — | |
| `isbn13` | text | yes (unique) | — | canonical key; 13 digits; drives dedup |
| `isbn10` | text | yes | — | 10-digit companion; indexed |
| `title` | text | no | — | required (manual entry) |
| `subtitle` | text | yes | — | |
| `authors` | List\<String> (JSON) | no | `[]` | `100$a` → `[0]`, `700$a` → `[1..]` |
| `publisher` | text | yes | — | `264$b`/`260$b` |
| `publishedYear` | int | yes | — | leading `YYYY` parsed from `264$c` |
| `pageCount` | int | yes | — | leading int from `300$a` |
| `format` | BookFormat | yes | — | |
| `language` | text | yes | — | ISO 639-2 from `008` pos 35–37 |
| `status` | BookStatus | no | `unread` | |
| `rating` | real | no | `0.0` | 0.0–5.0 in 0.5 steps |
| `locationId` | int (FK→Locations) | yes | — | `ON DELETE SET NULL` |
| `seriesId` | int (FK→Series) | yes | — | `ON DELETE SET NULL` |
| `seriesVolume` | real | yes | — | from `490$v`/`830$v` |
| `description` | text | yes | — | Google Books fills if empty |
| `coverUrl` | text | yes | — | remote URL |
| `coverLocalPath` | text | yes | — | local file path (cache) |
| `metadataSource` | MetadataSource | yes | — | `dnb` + unmodified ⇒ badge |
| `editedFields` | List\<String> (JSON) | no | `[]` | user-edited field names |
| `createdAt` | datetime | no | now | |
| `updatedAt` | datetime | no | now | bumped on any write |

**Indices**: `idx_books_isbn10`, `idx_books_location`, `idx_books_status`,
`idx_books_series`; `isbn13` unique constraint acts as its own index.

**Validation**:
- `title` non-empty for manual entries; remote entries may not supply title (skipped).
- `rating` ∈ {0.0, 0.5, …, 5.0}; round to nearest 0.5 on write.
- `isbn13` exactly 13 digits; `isbn10` exactly 10; ISBN-10 auto-converted to ISBN-13 on
  normalization (research §3).
- `publishedYear` plausible range (e.g. 1000–2100) or null.

**State transitions**: `status` follows `unread → reading → read` (with `dnf`,
`wishlist`, `reReading` as side states). `metadataSource` + `editedFields` jointly define
the badge: `dnb` and empty overlap with DNB fields ⇒ "DNB-verifiziert", otherwise
"bearbeitet" (spec §6.3).

### 2.2 Location

A node in the Room → Shelf → Compartment tree (self-referential).

| Field | Type | Null | Default | Rules |
|-------|------|------|---------|-------|
| `id` | int (PK, autoincrement) | no | — | |
| `name` | text | no | — | required |
| `type` | LocationType | no | — | room/shelf/compartment |
| `parentId` | int (FK→Locations, self) | yes | — | null ⇒ root (room) |
| `sortOrder` | int | no | 0 | sibling ordering |

**Validation / invariants**:
- A room has no parent; a shelf's parent must be a room; a compartment's parent must be a
  shelf (type-constrained depth of 3). The repository enforces this on create/move.
- `name` non-empty; sibling names need not be unique (uniqueness is by `(parentId, name)`
  enforced in the repository, not a DB constraint).
- **Deletion guard** (FR-008): deleting a location that still has children or assigned
  books is BLOCKED — the user must move/empty it first. No silent orphaning.

### 2.3 Series

A named sequence with optional planned volume count.

| Field | Type | Null | Default | Rules |
|-------|------|------|---------|-------|
| `id` | int (PK, autoincrement) | no | — | |
| `name` | text (unique) | no | — | case-insensitive dedup |
| `totalPlannedVolumes` | int | yes | — | |

**Transitions**: created/linked automatically from MARC21 `490`/`830` on scan
(FR-007, spec §4.4); `830` is authoritative and overrides `490` when both present.
Linking a book to a series does not modify the series itself.

### 2.4 Lending

A borrow event linked to one book.

| Field | Type | Null | Default | Rules |
|-------|------|------|---------|-------|
| `id` | int (PK, autoincrement) | no | — | |
| `bookId` | int (FK→Books) | no | — | `ON DELETE CASCADE` |
| `borrowerName` | text | no | — | required |
| `lentAt` | datetime | no | — | |
| `expectedReturn` | datetime | yes | — | |
| `returnedAt` | datetime | yes | — | set ⇒ returned |

**Index**: `idx_lending_book`.

**State transitions**:
```
lent (returnedAt == null) ──"Als zurückgegeben markieren"──▶ returned (returnedAt set)
```
A book's "lent" state is derived from its latest `Lending` row with `returnedAt == null`.
Marking returned sets `returnedAt`; the badge clears (US6). History is preserved.

## 3. Relationships

```text
Locations ──<parentId──┐ (self, 3-level tree)
     │
     └──< Books.locationId   (1..* , SET NULL on delete)

Series ────< Books.seriesId  (1..* , SET NULL on delete)

Books ──────< Lending.bookId (1..* , CASCADE on delete)
```

- A `Book` references at most one `Location` and at most one `Series`.
- A `Location` may have many child `Location`s and many `Book`s.
- A `Series` may have many `Book`s.
- A `Book` may have many `Lending` rows (history).

## 4. Domain (non-persisted) models

These are the strongly typed contracts crossing the repository boundary (see
`contracts/`), distinct from the Drift row classes.

- `BookMetadata` — transport object from a metadata source (spec §4.2).
- `AggregatedMetadata` — merge result incl. source attribution per field.
- `ImportFile`, `ImportRow`, `RowError`, `ImportResult` — importer pipeline.
- `LocationNode` — tree view model (id, name, type, children, bookCount).
- `Lending` — already persisted; no separate domain twin needed.

## 5. Validation summary (traceability)

| Rule | Requirement |
|------|-------------|
| ISBN-10 → ISBN-13 normalization | Edge cases §2; FR-014 |
| Prefer 13-digit `020$a` | Edge cases §2 |
| Rating 0.5-step persistence | US1.3 |
| Location deletion guard (children/books) | FR-008; US3 |
| Block duplicate ISBN scan/import | FR-014; US5.2 |
| Rollback on critical import failure | FR-012; US4.3 |
| `editedFields` preserve on refresh | FR-005; US2.3 |
