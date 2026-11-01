import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/shelf_partition.dart';

Book _book(int id, {int? parentId, BookStatus status = BookStatus.unread}) =>
    Book(
      id: id,
      title: 'B$id',
      authors: const ['A'],
      status: status,
      rating: 0,
      parentId: parentId,
      editedFields: const [],
      currentPage: 0,
      isFavorite: false,
      coverNotFound: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  group('ShelfPartition (ADR-0003)', () {
    final single = _book(1);
    final slipcase = _book(2);
    final volume1 = _book(3, parentId: 2);
    final volume2 = _book(4, parentId: 2);
    final shelf = ShelfPartition.of([single, slipcase, volume1, volume2]);

    test('readable are single books and volumes, never the slipcase', () {
      expect(shelf.readable.map((b) => b.id), [1, 3, 4]);
    });

    test('physical are single books and slipcases, never a volume', () {
      expect(shelf.physical.map((b) => b.id), [1, 2]);
    });

    test('knows the volumes of each slipcase in order', () {
      expect(shelf.volumesOf(2).map((b) => b.id), [3, 4]);
      expect(shelf.volumesOf(1), isEmpty);
      expect(shelf.isSlipcase(2), isTrue);
      expect(shelf.isSlipcase(1), isFalse);
    });

    test('a volume is shelved as its slipcase', () {
      expect(shelf.shelvedAs(volume1), slipcase);
      expect(shelf.shelvedAs(single), single);
    });

    test('a volume whose slipcase is not in the list stands alone', () {
      // E.g. the slipcase is in the trash: the volume must not vanish.
      final orphan = _book(5, parentId: 99);
      final partition = ShelfPartition.of([orphan]);

      expect(partition.readable, [orphan]);
      expect(partition.physical, [orphan]);
    });
  });

  group('slipcaseStatus', () {
    BookStatus of(List<BookStatus> statuses) => slipcaseStatus(statuses);
    const u = BookStatus.unread,
        r = BookStatus.read,
        reading = BookStatus.reading,
        re = BookStatus.reReading,
        dnf = BookStatus.dnf,
        w = BookStatus.wishlist;

    test('a volume being read makes the slipcase "reading"', () {
      expect(of([u, reading, r]), reading);
      expect(of([r, re]), reading);
    });

    test('all finished with at least one read is "read"', () {
      expect(of([r, r]), r);
      expect(of([r, dnf]), r);
    });

    test('all abandoned is "dnf", all wished is "wishlist"', () {
      expect(of([dnf, dnf]), dnf);
      expect(of([w, w]), w);
    });

    test('read and unread volumes mixed count as "reading"', () {
      expect(of([r, u, u]), reading);
      expect(of([r, w]), reading);
    });

    test('otherwise unread', () {
      expect(of([u, u]), u);
      expect(of([u, dnf]), u);
      expect(of([u, w]), u);
      expect(of([]), u);
    });
  });
}
