import 'package:openreads/data/database/app_database.dart';

/// A tag together with the number of books that carry it.
class TagWithCount {
  final Tag tag;
  final int bookCount;

  const TagWithCount(this.tag, this.bookCount);
}
