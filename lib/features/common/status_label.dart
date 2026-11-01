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

/// Localized name of a [ReceivedAs] value (spec 004 FR-R2-07).
String receivedAsLabel(AppLocalizations l10n, ReceivedAs value) {
  return switch (value) {
    ReceivedAs.purchase => l10n.receivedAsPurchase,
    ReceivedAs.gift => l10n.receivedAsGift,
    ReceivedAs.loan => l10n.receivedAsLoan,
    ReceivedAs.reviewCopy => l10n.receivedAsReviewCopy,
    ReceivedAs.other => l10n.receivedAsOther,
  };
}

/// Localized name of a [BookFormat].
String formatLabel(AppLocalizations l10n, BookFormat format) {
  return switch (format) {
    BookFormat.hardcover => l10n.formatHardcover,
    BookFormat.paperback => l10n.formatPaperback,
    BookFormat.ebook => l10n.formatEbook,
    BookFormat.audiobook => l10n.formatAudiobook,
  };
}
