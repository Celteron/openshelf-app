import 'package:http/http.dart' as http;
import 'package:openreads/data/metadata/http_config.dart';
import 'package:openreads/data/metadata/marc21_parser.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';

/// DNB SRU client. Queries the bibliographic catalogue with `num=<isbn>` and
/// parses the MARC21-XML response. Returns `null` (never throws) on
/// `numberOfRecords = 0`, `<diagnostic>` elements, HTTP errors, timeouts, or
/// malformed XML (Constitution Article IV.3).
class DnbClient implements MetadataSourceStrategy {
  static const _baseUrl = 'https://services.dnb.de/sru/dnb';

  final http.Client _client;
  final Marc21Parser _parser;
  final Duration _timeout;

  DnbClient({
    http.Client? client,
    Marc21Parser parser = const Marc21Parser(),
    Duration timeout = metadataRequestTimeout,
  }) : _client = client ?? http.Client(),
       _parser = parser,
       _timeout = timeout;

  @override
  MetadataSource get id => MetadataSource.dnb;

  @override
  Future<BookMetadata?> lookupByIsbn(String isbn13) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'version': '1.1',
        'operation': 'searchRetrieve',
        'query': 'num=$isbn13',
        'recordSchema': 'MARC21-xml',
        'maximumRecords': '10',
      },
    );

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': metadataUserAgent})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;

      final body = response.body;
      if (_hasZeroRecords(body) || _hasDiagnostic(body)) return null;

      return _parser.parse(body);
    } catch (_) {
      return null;
    }
  }

  bool _hasZeroRecords(String body) => RegExp(
    r'<[^>]*:?numberOfRecords>\s*0\s*</[^>]*:?numberOfRecords>',
  ).hasMatch(body);

  bool _hasDiagnostic(String body) =>
      body.contains('<diagnostic') || body.contains('<diag:diagnostic');
}
