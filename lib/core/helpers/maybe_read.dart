import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reading an optional dependency from the widget tree.
///
/// Some widgets work without a cubit or service (they hide, or fall back to
/// defaults), notably in widget tests that provide only what they need. These
/// helpers answer `null` when no provider of `T` is above the widget. Unlike
/// a bare `catch (_)` they let every other error through, e.g. a provider
/// whose factory throws.
extension MaybeRead on BuildContext {
  T? maybeRead<T>() {
    try {
      return read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// Like [maybeRead], and rebuilds the widget when the object changes.
  T? maybeWatch<T>() {
    try {
      return watch<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
