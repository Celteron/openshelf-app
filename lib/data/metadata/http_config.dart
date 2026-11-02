/// Shared HTTP configuration for the metadata clients.
library;

/// A polite, identifiable User-Agent. DNB and other APIs may throttle or
/// reject requests without one.
const String metadataUserAgent =
    'OpenShelf/1.0 (+https://github.com/openshelf)';

/// Default per-request timeout. A hung socket must never block the serialized
/// lookup queue indefinitely.
const Duration metadataRequestTimeout = Duration(seconds: 10);
