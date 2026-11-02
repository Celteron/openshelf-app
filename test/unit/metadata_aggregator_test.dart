import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';

class _FakeSource implements MetadataSourceStrategy {
  @override
  final MetadataSource id;

  final BookMetadata result;

  _FakeSource(this.id, this.result);

  @override
  Future<BookMetadata?> lookupByIsbn(String isbn13) async => result;
}

void main() {
  final dnb = _FakeSource(
    MetadataSource.dnb,
    const BookMetadata(
      title: 'DNB Titel',
      authors: ['DNB Autor'],
      publisher: 'DNB Verlag',
    ),
  );

  final google = _FakeSource(
    MetadataSource.googleBooks,
    const BookMetadata(coverUrl: 'https://cover', description: 'Beschreibung'),
  );

  final openLibrary = _FakeSource(
    MetadataSource.openLibrary,
    const BookMetadata(
      title: 'OL Titel',
      authors: ['OL Autor'],
      publisher: 'OL Verlag',
      coverUrl: 'https://ol-cover',
      pageCount: 300,
    ),
  );

  test('fills DNB fields, then Google cover/description only', () async {
    final service = MetadataAggregatorService([dnb, google, openLibrary]);
    final result = await service.enrich(
      const BookMetadata(isbn13: '9783442719255'),
    );

    expect(result.primarySource, MetadataSource.dnb);
    expect(result.metadata.title, 'DNB Titel');
    expect(result.metadata.coverUrl, 'https://cover');
    expect(result.metadata.description, 'Beschreibung');
    // Open Library must NOT override DNB title or Google cover.
    expect(result.metadata.publisher, 'DNB Verlag');
  });

  test('Open Library fills fields still empty after DNB + Google', () async {
    final service = MetadataAggregatorService([dnb, google, openLibrary]);
    final result = await service.enrich(
      const BookMetadata(isbn13: '9783442719255'),
    );

    // pageCount is not provided by DNB or Google, so Open Library fills it.
    expect(result.metadata.pageCount, 300);
  });

  test('never overwrites a user-edited field', () async {
    final service = MetadataAggregatorService([dnb, google, openLibrary]);
    final result = await service.enrich(
      const BookMetadata(isbn13: '9783442719255', title: 'Mein Titel'),
      editedFields: const {'title'},
    );

    expect(result.metadata.title, 'Mein Titel');
    // Non-edited fields still fill from DNB.
    expect(result.metadata.publisher, 'DNB Verlag');
  });

  test('returns base unchanged when there is no ISBN', () async {
    final service = MetadataAggregatorService([dnb]);
    final result = await service.enrich(const BookMetadata());

    expect(result.metadata.title, isNull);
    expect(result.primarySource, isNull);
  });

  group('DNB cover fallback', () {
    final dnbOnly = _FakeSource(
      MetadataSource.dnb,
      const BookMetadata(title: 'Nur DNB', authors: ['A']),
    );
    final googleBlocked = _NullSource(MetadataSource.googleBooks);

    test('is used when no source delivers a cover (e.g. Google 429)', () async {
      final service = MetadataAggregatorService([dnbOnly, googleBlocked]);
      final result = await service.enrich(
        const BookMetadata(isbn13: '9783833874239'),
      );

      expect(
        result.metadata.coverUrl,
        'https://portal.dnb.de/opac/mvb/cover?isbn=9783833874239',
      );
    });

    test('never replaces a cover a source did deliver', () async {
      final service = MetadataAggregatorService([dnbOnly, google]);
      final result = await service.enrich(
        const BookMetadata(isbn13: '9783833874239'),
      );

      expect(result.metadata.coverUrl, 'https://cover');
    });

    test('is not invented for an ISBN no source knows', () async {
      final service = MetadataAggregatorService([
        _NullSource(MetadataSource.dnb),
        googleBlocked,
      ]);
      final result = await service.enrich(
        const BookMetadata(isbn13: '9783833874239'),
      );

      expect(result.metadata.coverUrl, isNull);
    });

    test('respects a cover the user removed by hand', () async {
      final service = MetadataAggregatorService([dnbOnly, googleBlocked]);
      final result = await service.enrich(
        const BookMetadata(isbn13: '9783833874239'),
        editedFields: const {'coverUrl'},
      );

      expect(result.metadata.coverUrl, isNull);
    });
  });
}

class _NullSource implements MetadataSourceStrategy {
  @override
  final MetadataSource id;

  _NullSource(this.id);

  @override
  Future<BookMetadata?> lookupByIsbn(String isbn13) async => null;
}
