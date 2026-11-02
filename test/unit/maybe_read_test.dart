import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/core/helpers/maybe_read.dart';

class _Service {}

void main() {
  testWidgets('returns the provided object, or null when nobody provides it', (
    tester,
  ) async {
    final service = _Service();
    _Service? provided;
    _Other? missing;
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: service,
        child: Builder(
          builder: (context) {
            provided = context.maybeRead<_Service>();
            missing = context.maybeRead<_Other>();
            return const SizedBox();
          },
        ),
      ),
    );

    expect(provided, same(service));
    expect(missing, isNull);
  });

  testWidgets('other errors are not swallowed', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          // Not a missing provider: a factory that throws.
          return RepositoryProvider<_Service>(
            lazy: false,
            create: (_) => throw StateError('broken factory'),
            child: Builder(
              builder: (inner) {
                inner.maybeRead<_Service>();
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });
}

class _Other {}
