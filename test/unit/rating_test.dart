import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/core/helpers/rating.dart';

void main() {
  test('normalizeRating returns 0.0 for null', () {
    expect(normalizeRating(null), 0.0);
  });

  test('normalizeRating preserves exact 0.5 steps', () {
    expect(normalizeRating(0.0), 0.0);
    expect(normalizeRating(3.5), 3.5);
    expect(normalizeRating(5.0), 5.0);
  });

  test('normalizeRating rounds to nearest 0.5', () {
    expect(normalizeRating(3.7), 3.5);
    expect(normalizeRating(3.8), 4.0);
    expect(normalizeRating(2.2), 2.0);
    expect(normalizeRating(2.3), 2.5);
  });

  test('normalizeRating clamps to 0.0–5.0', () {
    expect(normalizeRating(-1.0), 0.0);
    expect(normalizeRating(6.0), 5.0);
    expect(normalizeRating(99), 5.0);
  });
}
