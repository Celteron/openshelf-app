import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openreads/data/metadata/dnb_client.dart';

void main() {
  DnbClient clientWith(String body, {int status = 200}) {
    return DnbClient(
      client: MockClient((request) async {
        return http.Response(body, status);
      }),
    );
  }

  test('returns null when numberOfRecords is 0', () async {
    const body = '''
<zs:searchRetrieveResponse xmlns:zs="http://www.loc.gov/zing/srw/">
  <zs:numberOfRecords>0</zs:numberOfRecords>
</zs:searchRetrieveResponse>''';
    final client = clientWith(body);
    expect(await client.lookupByIsbn('9780000000000'), isNull);
  });

  test('returns null on a diagnostic element', () async {
    const body = '''
<zs:searchRetrieveResponse xmlns:zs="http://www.loc.gov/zing/srw/">
  <zs:numberOfRecords>0</zs:numberOfRecords>
  <zs:diagnostics>
    <diag:diagnostic xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/">
      <diag:message>Unsupported index</diag:message>
    </diag:diagnostic>
  </zs:diagnostics>
</zs:searchRetrieveResponse>''';
    final client = clientWith(body);
    expect(await client.lookupByIsbn('abc'), isNull);
  });

  test('returns null on malformed XML', () async {
    final client = clientWith('<record><datafield');
    expect(await client.lookupByIsbn('9780000000000'), isNull);
  });

  test('returns null on HTTP error', () async {
    final client = clientWith('Server error', status: 500);
    expect(await client.lookupByIsbn('9780000000000'), isNull);
  });

  test('parses a valid record', () async {
    const body = '''
<zs:searchRetrieveResponse xmlns:zs="http://www.loc.gov/zing/srw/">
  <zs:numberOfRecords>1</zs:numberOfRecords>
  <zs:records><zs:record><zs:recordData>
    <record xmlns="http://www.loc.gov/MARC21/slim">
      <datafield tag="245" ind1="1" ind2="0">
        <subfield code="a">Titel</subfield>
      </datafield>
    </record>
  </zs:recordData></zs:record></zs:records>
</zs:searchRetrieveResponse>''';
    final client = clientWith(body);
    final result = await client.lookupByIsbn('9780000000000');
    expect(result, isNotNull);
    expect(result!.title, 'Titel');
  });
}
