import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/utils/map_with_concurrency.dart';

void main() {
  group('mapWithConcurrency', () {
    test('returns an empty list for empty input', () async {
      final result = await mapWithConcurrency<int, String>(
        const [],
        (i) async => '$i',
      );
      expect(result, isEmpty);
    });

    test(
      'preserves input order even when operations complete out of order',
      () async {
        // The last element resolves first and the first one last. If the
        // implementation appended with `add()` instead of writing by index, the
        // result would come out reversed.
        final completers = {for (var i = 0; i < 4; i++) i: Completer<String>()};

        final future = mapWithConcurrency<int, String>(
          const [0, 1, 2, 3],
          (i) => completers[i]!.future,
          concurrency: 4,
        );

        for (final i in [3, 1, 2, 0]) {
          completers[i]!.complete('valor-$i');
        }

        expect(await future, ['valor-0', 'valor-1', 'valor-2', 'valor-3']);
      },
    );

    test('never exceeds the in-flight operation limit', () async {
      var inFlight = 0;
      var maxInFlight = 0;

      final result = await mapWithConcurrency<int, int>(
        List.generate(40, (i) => i),
        (i) async {
          inFlight++;
          maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
          // Two microtask turns so the workers interleave.
          await Future<void>.delayed(Duration.zero);
          await Future<void>.delayed(Duration.zero);
          inFlight--;
          return i * 2;
        },
        concurrency: 6,
      );

      expect(maxInFlight, 6, reason: 'should saturate exactly the limit');
      expect(result, List.generate(40, (i) => i * 2));
    });

    test(
      'processes everything when concurrency exceeds the list size',
      () async {
        var maxInFlight = 0;
        var inFlight = 0;

        final result = await mapWithConcurrency<int, int>(const [1, 2], (
          i,
        ) async {
          inFlight++;
          maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
          await Future<void>.delayed(Duration.zero);
          inFlight--;
          return i;
        }, concurrency: 50);

        expect(result, [1, 2]);
        expect(maxInFlight, 2, reason: 'cannot have more in flight than items');
      },
    );

    test('a concurrency of 0 or negative is treated as 1', () async {
      final result = await mapWithConcurrency<int, int>(
        const [1, 2, 3],
        (i) async => i,
        concurrency: 0,
      );
      expect(result, [1, 2, 3]);
    });

    test('propagates an error from the operation', () async {
      expect(
        mapWithConcurrency<int, int>(const [
          1,
          2,
          3,
        ], (i) async => i == 2 ? throw StateError('boom') : i),
        throwsStateError,
      );
    });
  });
}
