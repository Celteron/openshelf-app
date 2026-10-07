import 'package:flutter/material.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/app_preferences.dart';
import 'package:openreads/domain/models/library_sort.dart';
import 'package:openreads/features/common/widgets/book_cover.dart';
import 'package:openreads/features/library/widgets/rating_display.dart';

/// One book in the grid layouts: the cover with a favourite/selection overlay.
/// With [detailed] the title, author, rating and reading progress sit below.
class BookGridTile extends StatelessWidget {
  final Book book;
  final bool detailed;
  final bool selected;
  final RatingDisplay ratingDisplay;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BookGridTile({
    super.key,
    required this.book,
    this.detailed = false,
    this.selected = false,
    this.ratingDisplay = RatingDisplay.bar,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = readingProgress(book);
    return Semantics(
      selected: selected,
      label: book.title,
      child: InkWell(
        key: ValueKey('book-tile:${book.id}'),
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BookCover(
                    book: book,
                    borderRadius: BorderRadius.circular(8),
                    iconSize: 40,
                  ),
                  if (!detailed)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.82),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ),
                  if (book.isFavorite)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.favorite,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  if (selected)
                    Positioned.fill(
                      child: DecoratedBox(
                        key: const ValueKey('grid-selected'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: scheme.primary.withValues(alpha: 0.35),
                          border: Border.all(color: scheme.primary, width: 2),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (detailed) ...[
              const SizedBox(height: 4),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                book.authors.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (book.rating > 0)
                RatingBadge(
                  rating: book.rating,
                  display: ratingDisplay,
                  size: 12,
                ),
              if (progress > 0 && progress < 1)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(
                    key: const ValueKey('grid-progress'),
                    value: progress,
                    minHeight: 3,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
