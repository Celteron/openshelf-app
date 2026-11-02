# Interface Contracts — OpenShelf Phase 1

The public interfaces that cross the presentation → state → domain → data boundary.
These are Dart abstract interfaces; presentation code depends only on these (never on
`package:drift` or HTTP clients directly — Constitution Article II).

## 1. Repository interfaces (`lib/domain/repositories/`)

The domain layer's data-access contracts. Drift implementations live in
`lib/data/database/daos/` and are injected behind these abstractions.

```dart
abstract class BookRepository {
  Stream<List<Book>> watchBooks({String? query, BookStatus? status, int? locationId});
  Future<List<Book>> searchLocal(String query);              // <300ms (SC-002/FR-001)
  Future<Book?> getBook(int id);
  Future<int> insertBook(Book book);
  Future<void> updateBook(Book book);                        // sets updatedAt, tracks editedFields
  Future<void> bulkAssignLocation(List<int> bookIds, int? locationId); // single transaction (FR-009)
  Future<bool> isbnExists(String isbn13);                    // dedup (FR-014)
}

abstract class LocationRepository {
  Stream<List<LocationNode>> watchTree();                    // ordered room→shelf→compartment
  Future<int> createLocation({required String name, required LocationType type, int? parentId});
  Future<void> moveLocation(int id, int? newParentId, int sortOrder);
  Future<void> renameLocation(int id, String name);
  Future<void> deleteLocation(int id);                       // BLOCKED if children/books (FR-008)
}

abstract class SeriesRepository {
  Future<Series?> findByName(String name);                   // case-insensitive
  Future<Series> findOrCreate(String name);                  // FR-007
}

abstract class LendingRepository {
  Future<int> lend(int bookId, {required String borrowerName, DateTime? expectedReturn});
  Future<void> markReturned(int lendingId, DateTime returnedAt);   // US6
  Stream<Lending?> watchActiveLending(int bookId);           // drives the badge
}
```

**Rules**:
- All methods are offline-safe; no network I/O may occur behind these interfaces.
- `bulkAssignLocation` and import batch writes MUST run in a single transaction.

## 2. Metadata engine contracts (`lib/domain/services/` + `lib/data/metadata/`)

```dart
class BookMetadata {
  final String? isbn13, isbn10, title, subtitle, publisher, language, description;
  final List<String> authors;
  final int? publishedYear, pageCount;
  final BookFormat? format;
  final String? coverUrl;
  final String? seriesName;
  final double? seriesVolume;          // research: double, not num
}

abstract class MetadataSource {
  MetadataSource get id;               // dnb | googleBooks | openLibrary
  Future<BookMetadata?> lookupByIsbn(String isbn13);
}

abstract class MetadataAggregatorService {
  Future<AggregatedMetadata> enrich(BookMetadata base, {bool preserveUserEdits = true});
}
```

**Merge invariant** (Constitution Article III): DNB is authoritative; Google Books fills
only cover URL + description; Open Library fills only still-empty fields; user-edited
fields (in `editedFields`) are never overwritten.

### Remote HTTP contracts (consumed)

| Source | Endpoint | Response | Key mappings |
|--------|----------|----------|--------------|
| DNB SRU | `https://services.dnb.de/sru/dnb?version=1.1&operation=searchRetrieve&query=num={isbn}&recordSchema=MARC21-xml&maximumRecords=10` | MARC21 XML (ns `http://www.loc.gov/MARC21/slim`) | §4.4 tag map |
| Google Books | `https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}` | JSON | `items[0].volumeInfo.{imageLinks.thumbnail,description}` |
| Open Library | `https://openlibrary.org/api/books?bibkeys=ISBN:{isbn}&format=json&jscmd=data` | JSON | `ISBN:{isbn}.{title,authors,cover,publishers}` |

**Error contract**: every client returns `null` (never throws) on `numberOfRecords = 0`,
`<diagnostic>`, HTTP error, or malformed payload (spec §4.6, Article IV.3).

## 3. Importer contracts (`lib/data/importers/`)

```dart
enum ImportFileType { csv, json }

abstract class BookImporter {
  String get formatName;                 // "Openreads CSV", "Goodreads CSV", ...
  ImportFileType get supportedType;
  bool canParse(ImportFile file);        // header/shape detection
  Stream<ImportRow> parse(ImportFile file);  // row-by-row, lazy
}

class ImportRow { int rowNumber; BookMetadata? book; String? error; }

abstract class ImportService {
  Future<ImportResult> import(Stream<ImportRow> rows); // chunked 500/tx, rollback on critical
}
```

**Format contracts** (mapped via `ColumnMapper`; see spec §5.3):

| Importer | Type | Source columns |
|----------|------|----------------|
| OpenreadsCsvImporter / JsonImporter | csv/json | native Openreads status/rating |
| GoodreadsCsvImporter | csv | `Title`, `Author`, `Additional Authors`, `ISBN`, `ISBN13`, `My Rating` (1–5→0.5-step), `Exclusive Shelf`, `Number of Pages` |
| StoryGraphCsvImporter | csv | `Title`, `Authors`, `ISBN/UID`, `Rating` |
| BookstatsCsvImporter / JsonImporter | csv/json | legacy German columns → `ColumnMapper` (user-confirmed) |

**Invariants**: malformed rows are skipped and logged (row number + reason) without
aborting (FR-011); critical mid-import failure rolls back the current transaction with no
partial books persisted (FR-012); duplicate ISBNs are skipped and reported (FR-014).

## 4. Scanner state machine contract (`lib/features/scanner/`)

`ScannerCubit` states: `idle | scanning | staging | saving` (spec §6.2).

- `idle → scanning` on camera start.
- `scanning → staging` (accumulate) on each decoded ISBN (dedup vs. staged + owned).
- `staging → saving` on "save all"; `saving → idle` on success (staging cleared).
- Bulk location assignment applies to all staged books on save (US5.3).
