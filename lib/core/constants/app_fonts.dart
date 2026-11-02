/// The bundled font families (declared in `pubspec.yaml`), carried over from
/// Openreads. `null` as family means the platform default.
class AppFont {
  final String label;
  final String? family;
  const AppFont(this.label, this.family);
}

const appFonts = <AppFont>[
  AppFont('Standard', null),
  AppFont('Atkinson Hyperlegible', 'AtkinsonHyperlegible'),
  AppFont('Open Dyslexic', 'OpenDyslexic'),
  AppFont('Nunito', 'Nunito'),
  AppFont('Jost', 'Jost'),
  AppFont('Barlow', 'Barlow'),
  AppFont('Inter', 'Inter'),
  AppFont('Kanit', 'Kanit'),
  AppFont('Lato', 'Lato'),
  AppFont('Lora', 'Lora'),
  AppFont('Montserrat', 'Montserrat'),
  AppFont('Playfair Display', 'PlayfairDisplay'),
  AppFont('Poppins', 'Poppins'),
  AppFont('Raleway', 'Raleway'),
  AppFont('Sofia Sans', 'SofiaSans'),
  AppFont('Quicksand', 'Quicksand'),
];
