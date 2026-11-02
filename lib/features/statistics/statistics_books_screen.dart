import 'package:flutter/material.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/features/library/book_detail_screen.dart';
import 'package:openreads/features/library/widgets/book_list_tile.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// The books behind one number of the statistics, e.g. a month or a status
/// (FR-R2-17); a book opens its detail view.
class StatisticsBooksScreen extends StatelessWidget {
  final String title;
  final List<Book> books;

  const StatisticsBooksScreen({
    super.key,
    required this.title,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: books.isEmpty
          ? Center(child: Text(l10n.noBooksYet))
          : ListView(
              children: [
                for (final book in books)
                  BookListTile(
                    book: book,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookDetailScreen(bookId: book.id),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
