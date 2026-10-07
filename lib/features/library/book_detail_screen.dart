import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/core/helpers/rating.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/features/lending/lending_cubit.dart';
import 'package:openreads/features/library/add_book_screen.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/features/library/widgets/rating_control.dart';
import 'package:openreads/features/library/widgets/verification_badge.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Book details: bibliographic data, rating/status editing, DNB verification
/// badge, and lending actions (spec §6.3).
class BookDetailScreen extends StatefulWidget {
  final int bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<LendingCubit>().watch(widget.bookId);
  }

  Future<void> _load() async {
    final book = await context.read<BookRepository>().getBook(widget.bookId);
    if (mounted) setState(() => _book = book);
  }

  Future<void> _openEdit(BuildContext context, Book book) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddBookScreen(book: book)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    if (book == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            onPressed: () => _openEdit(context, book),
            icon: const Icon(Icons.edit),
            tooltip: l10n.editBookTitle,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: VerificationBadge(book: book)),
          const SizedBox(height: 8),
          if (book.subtitle != null)
            Text(
              book.subtitle!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 8),
          Text(book.authors.join(', ')),
          const SizedBox(height: 16),
          _MetadataTable(book: book),
          const SizedBox(height: 24),
          Text(l10n.ratingLabel, style: Theme.of(context).textTheme.titleSmall),
          RatingControl(
            value: book.rating,
            onChanged: (v) async {
              await context.read<LibraryCubit>().setRating(
                book.id,
                normalizeRating(v),
              );
              await _load();
            },
          ),
          const SizedBox(height: 24),
          Text(l10n.statusLabel, style: Theme.of(context).textTheme.titleSmall),
          DropdownButton<BookStatus>(
            value: book.status,
            items: [
              for (final s in BookStatus.values)
                DropdownMenuItem(value: s, child: Text(s.name)),
            ],
            onChanged: (s) async {
              if (s == null) return;
              await context.read<LibraryCubit>().setStatus(book.id, s);
              await _load();
            },
          ),
          const SizedBox(height: 24),
          _LendingSection(bookId: book.id),
        ],
      ),
    );
  }
}

class _MetadataTable extends StatelessWidget {
  final Book book;
  const _MetadataTable({required this.book});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <(String, String?)>[
      (l10n.isbn13Label, book.isbn13),
      (l10n.isbn10Label, book.isbn10),
      (l10n.publisherLabel, book.publisher),
      (l10n.yearLabel, book.publishedYear?.toString()),
      (l10n.pagesLabel, book.pageCount?.toString()),
      (l10n.languageLabel, book.language),
      (l10n.formatLabel, book.format?.name),
      (l10n.seriesVolumeLabel, book.seriesVolume?.toString()),
    ];
    return Table(
      columnWidths: const {0: FixedColumnWidth(120)},
      children: [
        for (final (label, value) in rows)
          if (value != null && value.isNotEmpty)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(value),
                ),
              ],
            ),
      ],
    );
  }
}

class _LendingSection extends StatelessWidget {
  final int bookId;
  const _LendingSection({required this.bookId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<LendingCubit, LendingState>(
      builder: (context, state) {
        if (state is LendingActive) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(l10n.lentTo(state.lending.borrowerName)),
              trailing: TextButton(
                onPressed: () =>
                    context.read<LendingCubit>().markReturned(state.lending.id),
                child: Text(l10n.markReturned),
              ),
            ),
          );
        }
        return _LendForm(bookId: bookId);
      },
    );
  }
}

class _LendForm extends StatefulWidget {
  final int bookId;
  const _LendForm({required this.bookId});

  @override
  State<_LendForm> createState() => _LendFormState();
}

class _LendFormState extends State<_LendForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: l10n.borrowerNameHint),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isEmpty) return;
            context.read<LendingCubit>().lend(
              widget.bookId,
              borrowerName: _controller.text.trim(),
            );
            _controller.clear();
          },
          child: Text(l10n.lend),
        ),
      ],
    );
  }
}
