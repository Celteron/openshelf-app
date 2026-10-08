import 'package:flutter/material.dart';

/// A 0.5-step rating control (0.0–5.0): five stars where the left half of a
/// star selects the half value and the right half the full value.
///
/// The whole bar (300×56 dp) is one touch target, like a slider: a tap sets
/// the value under the finger, and a drag previews it and sets it on release,
/// so the 30 dp half-star zones do not have to be hit precisely (Constitution
/// V.3). For screen readers each half has a label, and the bar offers
/// increase/decrease actions.
class RatingControl extends StatefulWidget {
  static const _starWidth = 60.0;
  static const _height = 56.0;

  final double value;
  final ValueChanged<double>? onChanged;

  const RatingControl({super.key, required this.value, this.onChanged});

  @override
  State<RatingControl> createState() => _RatingControlState();
}

class _RatingControlState extends State<RatingControl> {
  /// The value under a finger that is still dragging; not saved yet.
  double? _preview;

  static const _half = RatingControl._starWidth / 2;

  /// The rating at horizontal position [dx], in 0.5 steps within 0.5–5.
  double _valueAt(double dx) =>
      ((dx / _half).ceil() * 0.5).clamp(0.5, 5.0).toDouble();

  void _commit(double rating) {
    setState(() => _preview = null);
    widget.onChanged?.call(rating);
  }

  @override
  Widget build(BuildContext context) {
    final change = widget.onChanged;
    final shown = _preview ?? widget.value;
    return Semantics(
      label: 'Rating',
      value: widget.value.toStringAsFixed(1),
      onIncrease: change == null || widget.value >= 5
          ? null
          : () => change(widget.value + 0.5),
      onDecrease: change == null || widget.value <= 0
          ? null
          : () => change(widget.value - 0.5),
      increasedValue: (widget.value + 0.5).clamp(0, 5).toStringAsFixed(1),
      decreasedValue: (widget.value - 0.5).clamp(0, 5).toStringAsFixed(1),
      // A list gives its children tight widths; keep the bar at its own size so
      // the touch zones line up with the stars.
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: 1,
        heightFactor: 1,
        child: GestureDetector(
          key: const ValueKey('rating-bar'),
          behavior: HitTestBehavior.opaque,
          onTapUp: change == null
              ? null
              : (d) => _commit(_valueAt(d.localPosition.dx)),
          onHorizontalDragStart: change == null
              ? null
              : (d) => setState(() => _preview = _valueAt(d.localPosition.dx)),
          onHorizontalDragUpdate: change == null
              ? null
              : (d) => setState(() => _preview = _valueAt(d.localPosition.dx)),
          onHorizontalDragEnd: change == null
              ? null
              : (_) {
                  final rating = _preview;
                  if (rating != null) _commit(rating);
                },
          onHorizontalDragCancel: () => setState(() => _preview = null),
          child: SizedBox(
            width: RatingControl._starWidth * 5,
            height: RatingControl._height,
            child: Stack(
              children: [
                Row(
                  children: [
                    for (var star = 0; star < 5; star++)
                      SizedBox(
                        width: RatingControl._starWidth,
                        child: Center(child: _icon(shown, star)),
                      ),
                  ],
                ),
                // One labelled zone per half star for screen readers.
                Row(
                  children: [
                    for (var half = 1; half <= 10; half++)
                      Expanded(
                        child: Semantics(
                          label: '${(half / 2).toStringAsFixed(1)} stars',
                          button: change != null,
                          onTap: change == null ? null : () => change(half / 2),
                          child: const SizedBox.expand(),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconData(double value, int star) => value >= star + 1
      ? Icons.star
      : value >= star + 0.5
      ? Icons.star_half
      : Icons.star_border;

  Icon _icon(double value, int star) =>
      Icon(_iconData(value, star), color: Colors.amber, size: 36);
}
