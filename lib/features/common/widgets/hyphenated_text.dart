import 'package:flutter/material.dart';
import 'package:openreads/core/helpers/hyphenation.dart';

/// A [Text] for labels in narrow places that breaks long German words at
/// their syllables, with a hyphen, instead of at an arbitrary letter.
///
/// Only words from the hyphenation list are broken (see `hyphenation.dart`);
/// everything else lays out exactly like a plain [Text]. Screen readers get
/// the original text, not the broken lines.
class HyphenatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const HyphenatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    Text plain(String content) => Text(
      content,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite) return plain(text);
        final effective = DefaultTextStyle.of(context).style.merge(style);
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        double measure(String s) {
          final painter = TextPainter(
            text: TextSpan(text: s, style: effective),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }

        final lines = breakIntoLines(text, constraints.maxWidth, measure);
        if (lines.length == 1 && lines.single == text) return plain(text);
        return Semantics(
          label: text,
          excludeSemantics: true,
          child: plain(lines.join('\n')),
        );
      },
    );
  }
}
