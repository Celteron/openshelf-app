import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';
import 'package:openreads/domain/services/metadata_lookup_queue.dart';

class _CountingSource implements MetadataSourceStrategy {
  final List<DateTime> callTimes = [];

  @override
  MetadataSource get id => MetadataSource.dnb;

  @override
  Future<BookMetadata?> lookupByIsbn(String isbn13) async {
    callTimes.add(DateTime.now());
    return BookMetadata(title: 'Titel', isbn13: isbn13);
  }
}

class _FlakyAggregator extends MetadataAggregatorService {
  _FlakyAggregator.withFailures(int initialFailures)
    : failures = initialFailures,
      super(const []);

  int failures;
  int calls = 0;

  @override
  Future<AggregatedMetadata> enrich(
    BookMetadata base, {
    Set<String> editedFields = const {},
  }) async {
    calls++;
    if (failures > 0) {
      failures--;
      throw Exception('transient failure');
    }
    return const AggregatedMetadata(metadata: BookMetadata(title: 'Titel'));
  }
}

void main() {
  test('throttles lookups to the configured minimum interval', () async {
    final source = _CountingSource();
    final queue = MetadataLookupQueue(
      MetadataAggregatorService([source]),
      minInterval: const Duration(milliseconds: 80),
    );

    final futures = [
      for (var i = 0; i < 3; i++)
        queue.enqueue(BookMetadata(isbn13: '978000000000$i')),
    ];
    await Future.wait(futures);

    expect(source.callTimes, hasLength(3));
    for (var i = 1; i < source.callTimes.length; i++) {
      final gap = source.callTimes[i].difference(source.callTimes[i - 1]);
      expect(gap.inMilliseconds, greaterThanOrEqualTo(70));
    }
  });

  test('retries transient failures before succeeding', () async {
    final aggregator = _FlakyAggregator.withFailures(2);
    final queue = MetadataLookupQueue(
      aggregator,
      minInterval: Duration.zero,
      maxAttempts: 3,
      baseRetryDelay: const Duration(milliseconds: 10),
    );

    final result = await queue.enqueue(
      const BookMetadata(isbn13: '9780000000000'),
    );

    expect(result.metadata.title, 'Titel');
    expect(aggregator.calls, 3);
  });

  test('gives up after max attempts', () async {
    final aggregator = _FlakyAggregator.withFailures(99);
    final queue = MetadataLookupQueue(
      aggregator,
      minInterval: Duration.zero,
      maxAttempts: 2,
      baseRetryDelay: const Duration(milliseconds: 10),
    );

    await expectLater(
      queue.enqueue(const BookMetadata(isbn13: '9780000000000')),
      throwsA(anything),
    );
    expect(aggregator.calls, 2);
  });
}
