/// Domain-level enumerations shared by the data layer, domain services, and
/// the presentation layer.
///
/// These are persisted by Drift via `textEnum<T>()`, which stores each value's
/// `.name` string in a TEXT column.
library;

enum BookStatus { unread, reading, read, dnf, wishlist, reReading }

enum BookFormat { hardcover, paperback, ebook, audiobook }

enum LocationType { room, shelf, compartment }

enum MetadataSource { dnb, googleBooks, openLibrary, manual }
