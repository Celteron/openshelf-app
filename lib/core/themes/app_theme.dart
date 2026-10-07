import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// Seed colour used until the user picks an accent colour.
const defaultAccentColor = Color(0xFF009688);

/// Builds the app theme from the user's appearance preferences.
///
/// * [accentColor] seeds the colour scheme (ARGB int, `null` = default).
/// * [dynamicScheme] is the platform's wallpaper-derived scheme; it is used
///   instead of the seed when [materialYou] is on and the platform has one.
/// * [amoled] turns the dark theme pure black (ignored for light).
/// * [fontFamily] is one of the bundled families (`null` = platform default).
ThemeData buildAppTheme({
  required Brightness brightness,
  int? accentColor,
  bool materialYou = false,
  ColorScheme? dynamicScheme,
  bool amoled = false,
  String? fontFamily,
}) {
  var scheme = materialYou && dynamicScheme != null
      ? dynamicScheme.harmonized()
      : ColorScheme.fromSeed(
          seedColor: accentColor == null
              ? defaultAccentColor
              : Color(accentColor),
          brightness: brightness,
        );

  final pureBlack = amoled && brightness == Brightness.dark;
  if (pureBlack) {
    scheme = scheme.copyWith(
      surface: Colors.black,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF101010),
      surfaceContainerHigh: const Color(0xFF161616),
      surfaceContainerHighest: const Color(0xFF1C1C1C),
    );
  }

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: pureBlack ? Colors.black : null,
  );
}
