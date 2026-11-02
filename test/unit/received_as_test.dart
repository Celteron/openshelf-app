import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/tables.dart';
import 'package:openreads/domain/models/enums.dart';

/// "Received as" is stored as a pinned integer code (spec 004 FR-R2-07/-10).
/// The codes are part of every database on a device: they must never change.
void main() {
  test('the stored codes are pinned', () {
    expect(
      {for (final r in ReceivedAs.values) r: r.code},
      {
        ReceivedAs.purchase: 0,
        ReceivedAs.gift: 1,
        ReceivedAs.loan: 2,
        ReceivedAs.reviewCopy: 3,
        ReceivedAs.other: 4,
      },
    );
  });

  test('every code round-trips; an unknown code reads as other', () {
    for (final r in ReceivedAs.values) {
      expect(ReceivedAs.fromCode(r.code), r);
    }
    expect(ReceivedAs.fromCode(99), ReceivedAs.other);
  });

  test('the converter maps codes both ways', () {
    const converter = ReceivedAsConverter();
    expect(converter.toSql(ReceivedAs.gift), 1);
    expect(converter.fromSql(3), ReceivedAs.reviewCopy);
  });
}
