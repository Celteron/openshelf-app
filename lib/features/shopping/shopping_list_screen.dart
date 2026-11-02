import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/scan_verdict.dart';
import 'package:openreads/domain/models/shopping_list.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/series_repository.dart';
import 'package:openreads/domain/services/series_gaps.dart';
import 'package:openreads/features/shopping/shopping_list_cubit.dart';
import 'package:openreads/features/statistics/stats_section_header.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// What is still to buy: the wishlist and the volumes missing from series.
/// Copying it as plain text lets the user send it to anyone, e.g. as a
/// birthday wish list, without the app sharing anything itself.
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ShoppingListCubit(
        context.read<BookRepository>(),
        context.read<SeriesRepository>(),
      )..load(),
      child: const _ShoppingView(),
    );
  }
}

class _ShoppingView extends StatelessWidget {
  const _ShoppingView();

  static String _text(AppLocalizations l10n, ShoppingList list) {
    String gap(SeriesStanding s) =>
        '• ${l10n.verdictSeriesMissing(s.name, s.missing.length, s.missing.join(', '))}';
    final sections = [
      if (list.wishlist.isNotEmpty)
        [
          l10n.shoppingWishlistHeading,
          for (final b in list.wishlist)
            '• ${b.title}${b.authors.isEmpty ? '' : ' – ${b.authors.join(', ')}'}',
        ],
      if (list.gaps.isNotEmpty)
        [l10n.shoppingGapsHeading, for (final s in list.gaps) gap(s)],
    ];
    return sections.map((s) => s.join('\n')).join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ShoppingListCubit, ShoppingState>(
      builder: (context, state) {
        final list = state is ShoppingLoaded ? state.list : null;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.shoppingTitle),
            actions: [
              if (list != null && !list.isEmpty)
                IconButton(
                  key: const ValueKey('shopping-copy'),
                  icon: const Icon(Icons.content_copy),
                  tooltip: l10n.shoppingCopy,
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(
                      ClipboardData(text: _text(l10n, list)),
                    );
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.shoppingCopied)),
                    );
                  },
                ),
            ],
          ),
          body: switch (state) {
            ShoppingLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ShoppingError() => Center(child: Text(l10n.errorLoadingLibrary)),
            ShoppingLoaded(:final list) => _Body(list: list),
          },
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final ShoppingList list;
  const _Body({required this.list});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget heading(String id, String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StatsSectionHeader(id, text),
    );
    return ListView(
      children: [
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.shoppingEmpty, textAlign: TextAlign.center),
          ),
        if (list.wishlist.isNotEmpty) ...[
          heading('shopping-wishlist', l10n.shoppingWishlistHeading),
          for (final b in list.wishlist)
            ListTile(
              title: Text(b.title),
              subtitle: b.authors.isEmpty ? null : Text(b.authors.join(', ')),
            ),
        ],
        if (list.gaps.isNotEmpty) ...[
          heading('shopping-gaps', l10n.shoppingGapsHeading),
          for (final s in list.gaps)
            ListTile(
              title: Text(
                l10n.verdictSeriesMissing(
                  s.name,
                  s.missing.length,
                  s.missing.join(', '),
                ),
              ),
            ),
        ],
        if (list.openSeries.isNotEmpty) ...[
          heading('shopping-open', l10n.shoppingOpenHeading),
          for (final s in list.openSeries)
            ListTile(
              key: ValueKey('shopping-open-${s.id}'),
              title: Text(s.name),
              subtitle: Text(l10n.shoppingSetLength),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _askLength(context, s),
            ),
        ],
      ],
    );
  }

  Future<void> _askLength(BuildContext context, SeriesStanding series) async {
    final cubit = context.read<ShoppingListCubit>();
    final total = await showDialog<int>(
      context: context,
      builder: (_) => _LengthDialog(name: series.name),
    );
    if (total != null) await cubit.setTotalVolumes(series.id, total);
  }
}

class _LengthDialog extends StatefulWidget {
  final String name;
  const _LengthDialog({required this.name});

  @override
  State<_LengthDialog> createState() => _LengthDialogState();
}

class _LengthDialogState extends State<_LengthDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = int.tryParse(_controller.text.trim());
    return AlertDialog(
      title: Text(widget.name),
      content: TextField(
        key: const ValueKey('shopping-length'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(labelText: l10n.shoppingLengthLabel),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: value == null || value <= 0 || value > maxSeriesVolumes
              ? null
              : () => Navigator.pop(context, value),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
