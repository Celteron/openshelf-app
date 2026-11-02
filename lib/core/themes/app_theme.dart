import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// Seed colour used until the user picks an accent colour: the petrol of the
/// logo (`doc/logo/`).
const defaultAccentColor = Color(0xFF0F766E);

/// Builds the app theme from the user's appearance preferences.
///
/// * [accentColor] seeds the colour scheme (ARGB int, `null` = the brand
///   scheme derived from the logo).
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
      : accentColor == null
      ? _brandScheme(brightness)
      : ColorScheme.fromSeed(
          seedColor: Color(accentColor),
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
    // The logo's glass look: flat, softly rounded surfaces with a faint edge
    // instead of shadows. Everything derives from the scheme, so a custom
    // accent or Material You keeps the same shapes.
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      // A borderless base hides focus and errors unless those states get
      // their own frame (InputDecorator does not derive them from `none`).
      border: _fieldBorder(BorderSide.none),
      enabledBorder: _fieldBorder(BorderSide.none),
      focusedBorder: _fieldBorder(BorderSide(color: scheme.primary, width: 2)),
      errorBorder: _fieldBorder(BorderSide(color: scheme.error)),
      focusedErrorBorder: _fieldBorder(
        BorderSide(color: scheme.error, width: 2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      // The M3 default (onSecondaryContainer) can vanish on a saturated
      // primaryContainer; its own "on" colour always contrasts.
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

// 12 dp keeps multi-line fields (description, notes) from turning into pills.
OutlineInputBorder _fieldBorder(BorderSide side) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: side,
);

/// The logo's colours: petrol kept true to the seed (`fidelity`), amber as the
/// accent (the ribbon), and in the dark petrol-tinted surfaces instead of the
/// generated near-greys.
ColorScheme _brandScheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: defaultAccentColor,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    tertiary: dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
    onTertiary: dark ? const Color(0xFF3B2300) : Colors.white,
    tertiaryContainer: dark ? const Color(0xFF6B3A06) : const Color(0xFFFEF3C7),
    onTertiaryContainer: dark
        ? const Color(0xFFFDE68A)
        : const Color(0xFF78350F),
  );
  if (!dark) return scheme;
  return scheme.copyWith(
    surface: const Color(0xFF0A171B),
    surfaceContainerLowest: const Color(0xFF0A171B),
    surfaceContainerLow: const Color(0xFF0F2126),
    surfaceContainer: const Color(0xFF12282E),
    surfaceContainerHigh: const Color(0xFF163037),
    surfaceContainerHighest: const Color(0xFF1A3840),
  );
}
