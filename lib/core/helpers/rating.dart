/// Rating normalization: ratings are stored in the range 0.0–5.0 in 0.5 steps
/// (spec §3.2, US1.3).
library;

/// Clamps [value] to 0.0–5.0 and rounds to the nearest 0.5 step.
double normalizeRating(num? value) {
  if (value == null) return 0.0;
  var v = value.toDouble();
  if (v < 0.0) v = 0.0;
  if (v > 5.0) v = 5.0;
  return (v * 2).roundToDouble() / 2.0;
}
