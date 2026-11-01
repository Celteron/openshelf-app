import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/core/themes/app_theme.dart';
import 'package:openreads/domain/models/app_preferences.dart';
import 'package:openreads/features/library/widgets/rating_display.dart';

/// Stars follow the theme's accent (amber in the brand scheme) instead of a
/// fixed colour (spec 004 FR-R2-06).
void main() {
  for (final display in RatingDisplay.values) {
    testWidgets('${display.name} stars use the tertiary colour', (
      tester,
    ) async {
      final theme = buildAppTheme(brightness: Brightness.light);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(body: RatingBadge(rating: 3.5, display: display)),
        ),
      );

      final colours = tester
          .widgetList<Icon>(find.byType(Icon))
          .map((i) => i.color)
          .toSet();
      expect(colours, {theme.colorScheme.tertiary});
    });
  }
}
