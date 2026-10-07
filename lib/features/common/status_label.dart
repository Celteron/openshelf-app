import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Localized display name of a [BookStatus] (FR-P2-10).
String statusLabel(AppLocalizations l10n, BookStatus status) {
  return switch (status) {
    BookStatus.unread => l10n.statusUnread,
    BookStatus.reading => l10n.statusReading,
    BookStatus.read => l10n.statusRead,
    BookStatus.dnf => l10n.statusDnf,
    BookStatus.wishlist => l10n.statusWishlist,
    BookStatus.reReading => l10n.statusReReading,
  };
}
