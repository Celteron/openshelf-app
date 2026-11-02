import 'package:flutter/material.dart';

/// Title of a group of statistics (FR-R2-15).
class StatsSectionHeader extends StatelessWidget {
  final String id;
  final String title;
  const StatsSectionHeader(this.id, this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey(id),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
