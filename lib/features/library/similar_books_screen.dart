import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/features/library/book_detail_screen.dart';
import 'package:openreads/features/library/widgets/book_list_tile.dart';
import 'package:openreads/l10n/app_localizations.dart';
import 'package:rxdart/rxdart.dart';

/// The books of the library that share an author or a tag with the book the
/// user came from (Openreads "similar books").
class SimilarBooksScreen extends StatelessWidget {
  final String? author;
  final Tag? tag;

  const SimilarBooksScreen.byAuthor(String this.author, {super.key})
    : tag = null;
  const SimilarBooksScreen.byTag(Tag this.tag, {super.key}) : author = null;

  Stream<List<Book>> _books(BuildContext context) {
    final books = context.read<BookRepository>().watchBooks();
    final tag = this.tag;
    if (tag != null) {
      return Rx.combineLatest2<List<Book>, Set<int>, List<Book>>(
        books,
        context.read<TagRepository>().watchBookIdsWithAllTags({tag.id}),
        (all, ids) => [
          for (final b in all)
            if (ids.contains(b.id)) b,
        ],
      );
    }
    final wanted = author!.trim().toLowerCase();
    return books.map(
      (all) => [
        for (final b in all)
          if (b.authors.any((a) => a.trim().toLowerCase() == wanted)) b,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tag != null ? tag!.name : author!),
        actions: [
          Icon(tag != null ? Icons.sell_outlined : Icons.person_outline),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<Book>>(
        stream: _books(context),
        builder: (context, snapshot) {
          final books = snapshot.data;
          if (books == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (books.isEmpty) return Center(child: Text(l10n.noBooksYet));
          return ListView(
            key: const ValueKey('similar-books'),
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
          );
        },
      ),
    );
  }
}
