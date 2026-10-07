import 'package:flutter/material.dart';
import 'package:openreads/core/helpers/rating.dart';
import 'package:openreads/domain/models/app_preferences.dart';
import 'package:openreads/features/library/widgets/rating_control.dart';

/// Read-only rating in the user's preferred style: a row of small stars
/// ([RatingDisplay.bar]) or the plain number ([RatingDisplay.number]).
/// Renders nothing for an unrated book.
class RatingBadge extends StatelessWidget {
  final double rating;
  final RatingDisplay display;
  final double size;
  const RatingBadge({
    super.key,
    required this.rating,
    this.display = RatingDisplay.bar,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    if (display == RatingDisplay.number) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: size, color: Colors.amber),
          const SizedBox(width: 2),
          Text(formatRating(rating), style: TextStyle(fontSize: size - 1)),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            rating >= i + 1
                ? Icons.star
                : rating >= i + 0.5
                ? Icons.star_half
                : Icons.star_border,
            size: size,
            color: Colors.amber,
          ),
      ],
    );
  }
}

/// `4.0` → `4`, `3.5` → `3.5`.
String formatRating(double rating) => rating == rating.roundToDouble()
    ? rating.toInt().toString()
    : rating.toStringAsFixed(1);

/// Editable rating in the user's preferred style: the tappable star bar, or a
/// numeric stepper (− value +) moving in 0.5 steps.
class RatingEditor extends StatelessWidget {
  final double value;
  final RatingDisplay display;
  final ValueChanged<double> onChanged;
  const RatingEditor({
    super.key,
    required this.value,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (display == RatingDisplay.bar) {
      return RatingControl(value: value, onChanged: onChanged);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('rating-minus'),
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value <= 0
              ? null
              : () => onChanged(normalizeRating(value - 0.5)),
        ),
        SizedBox(
          width: 72,
          child: Text(
            '${formatRating(value)} / 5',
            key: const ValueKey('rating-number'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          key: const ValueKey('rating-plus'),
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value >= 5
              ? null
              : () => onChanged(normalizeRating(value + 0.5)),
        ),
      ],
    );
  }
}
