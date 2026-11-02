import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';

/// Serializes metadata lookups through a throttled, retrying queue worker.
///
/// The continuous scanner decodes ISBNs faster than the remote sources should
/// be hit; without throttling, a burst of scans would flood the DNB SRU API and
/// risk an IP ban. This queue guarantees at most one in-flight lookup and
/// enforces a minimum interval between dispatches (default: 500 ms ≈ 2 req/s),
/// with exponential back-off retries on transient failures.
class MetadataLookupQueue {
  final MetadataAggregatorService _aggregator;
  final Duration _minInterval;
  final int _maxAttempts;
  final Duration _baseRetryDelay;

  Future<void> _tail = Future<void>.value();

  MetadataLookupQueue(
    this._aggregator, {
    Duration minInterval = const Duration(milliseconds: 500),
    int maxAttempts = 3,
    Duration baseRetryDelay = const Duration(milliseconds: 750),
  }) : _minInterval = minInterval,
       _maxAttempts = maxAttempts,
       _baseRetryDelay = baseRetryDelay;

  /// Enqueues a lookup. Returns a [Future] that completes with the merged
  /// metadata, or the error thrown after all retries are exhausted.
  Future<AggregatedMetadata> enqueue(
    BookMetadata base, {
    Set<String> editedFields = const {},
  }) {
    final result = _tail.then((_) => _run(base, editedFields));
    // Keep the queue alive regardless of individual lookup failures.
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<AggregatedMetadata> _run(
    BookMetadata base,
    Set<String> editedFields,
  ) async {
    await _throttle();

    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await _aggregator.enrich(base, editedFields: editedFields);
      } catch (e) {
        lastError = e;
        if (attempt < _maxAttempts) {
          await Future<void>.delayed(_baseRetryDelay * attempt);
        }
      }
    }
    throw lastError!;
  }

  Future<void> _throttle() async {
    final elapsed = DateTime.now().difference(_lastDispatch);
    if (elapsed < _minInterval) {
      await Future<void>.delayed(_minInterval - elapsed);
    }
    _lastDispatch = DateTime.now();
  }

  DateTime _lastDispatch = DateTime.fromMillisecondsSinceEpoch(0);
}
