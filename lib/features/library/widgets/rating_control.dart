import 'package:flutter/material.dart';

/// A 0.5-step rating control (0.0–5.0) with 48×48 dp tappable star halves and
/// screen-reader semantics (spec §3.2, Constitution Article V.3).
class RatingControl extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;

  const RatingControl({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rating',
      value: value.toStringAsFixed(1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (star) {
          final base = star.toDouble();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _halfStar(context, base, base + 0.5),
              _halfStar(context, base + 0.5, base + 1.0),
            ],
          );
        }),
      ),
    );
  }

  Widget _halfStar(BuildContext context, double low, double high) {
    final filled = value >= high;
    final half = !filled && value >= low;
    return Semantics(
      label: '${high.toStringAsFixed(1)} stars',
      button: onChanged != null,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(high),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            filled ? Icons.star : (half ? Icons.star_half : Icons.star_border),
            color: Colors.amber,
          ),
        ),
      ),
    );
  }
}
