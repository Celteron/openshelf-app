import 'package:flutter/material.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/app_preferences.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/features/common/widgets/book_cover.dart';
import 'package:openreads/features/library/widgets/rating_display.dart';

/// One book in the list layouts. [compact] drops the rating and shrinks the
/// cover for dense lists.
class BookListTile extends StatelessWidget {
  final Book book;
  final bool compact;
  final bool selected;
  final RatingDisplay ratingDisplay;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  /// An extra line under the authors, e.g. a slipcase's volume count.
  final String? note;

  const BookListTile({
    super.key,
    required this.book,
    this.compact = false,
    this.selected = false,
    this.ratingDisplay = RatingDisplay.bar,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      book.authors.join(', '),
      if (compact && note != null) note,
    ].join(' · ');
    return ListTile(
      key: ValueKey('book-tile:${book.id}'),
      dense: compact,
      selected: selected,
      leading: BookCover(
        book: book,
        width: compact ? 28 : 40,
        height: compact ? 40 : 56,
        borderRadius: BorderRadius.circular(4),
      ),
      title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: compact
          ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (note case final text?)
                  Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (book.rating > 0)
                  RatingBadge(rating: book.rating, display: ratingDisplay),
              ],
            ),
      trailing:
          trailing ??
          (book.isFavorite && book.status != BookStatus.wishlist
              ? Icon(
                  Icons.favorite,
                  size: 18,
                  color: Theme.of(context).colorScheme.tertiary,
                )
              : null),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
