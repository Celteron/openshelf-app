import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/features/library/book_detail_screen.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/features/library/widgets/book_list_tile.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// The books behind one number of the statistics, e.g. a month or a status
/// (FR-R2-17); a book opens its detail view.
class StatisticsBooksScreen extends StatelessWidget {
  final String title;
  final List<Book> books;

  /// Switches to the library tab; with it the screen offers "show in
  /// library", which opens the library filtered to [books].
  final VoidCallback? onShowInLibrary;

  const StatisticsBooksScreen({
    super.key,
    required this.title,
    required this.books,
    this.onShowInLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onShowInLibrary case final show? when books.isNotEmpty)
            IconButton(
              key: const ValueKey('show-in-library'),
              tooltip: l10n.showInLibrary,
              icon: const Icon(Icons.library_books_outlined),
              onPressed: () {
                context.read<LibraryCubit>().showOnly({
                  for (final b in books) b.id,
                });
                Navigator.of(context).popUntil((route) => route.isFirst);
                show();
              },
            ),
        ],
      ),
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
