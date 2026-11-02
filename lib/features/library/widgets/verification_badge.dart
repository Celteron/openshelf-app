import 'package:flutter/material.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Shows the DNB verification badge: "DNB-verifiziert" when the book's
/// metadata comes from DNB and has not been hand-edited, otherwise
/// "bearbeitet" (spec §6.3).
class VerificationBadge extends StatelessWidget {
  final Book book;

  const VerificationBadge({super.key, required this.book});

  bool get _isVerified =>
      book.metadataSource == MetadataSource.dnb && book.editedFields.isEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final verified = _isVerified;
    // A pure status label: the edit icon it used to carry made it look like
    // a button although it does nothing when tapped.
    return Chip(
      avatar: verified
          ? Icon(
              Icons.verified,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      label: Text(verified ? l10n.dnbVerified : l10n.edited),
      visualDensity: VisualDensity.compact,
    );
  }
}
