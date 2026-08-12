import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/retry.dart';

/// Delays of zero throughout: the schedule is injected precisely so the tests
/// assert attempt counts without spending real wall-clock time.
const noWait = [Duration.zero, Duration.zero];

void main() {
  group('isRetryable', () {
    test('transient causes are retryable', () {
      expect(isRetryable(const NetworkFailure()), isTrue);
      expect(isRetryable(const TimeoutFailure()), isTrue);
      expect(isRetryable(const ServerFailure(statusCode: 500)), isTrue);
      expect(isRetryable(const ServerFailure(statusCode: 503)), isTrue);
    });

    test('a 4xx is NOT retryable — the request itself is wrong', () {
      // Retrying these only multiplies the user's wait. A missing or invalid key
      // will be just as missing on the third attempt.
      expect(isRetryable(const ServerFailure(statusCode: 400)), isFalse);
      expect(isRetryable(const ServerFailure(statusCode: 401)), isFalse);
      expect(isRetryable(const ServerFailure(statusCode: 403)), isFalse);
      expect(isRetryable(const ServerFailure(statusCode: 404)), isFalse);
      expect(isRetryable(const ServerFailure(statusCode: 429)), isFalse);
    });

    test('a malformed payload is NOT retryable', () {
      // It will parse identically next time. This distinction is only possible
      // because Phase 3 made failures typed; with the old interpolated string the
      // policy could only have been "retry everything".
      expect(
        isRetryable(const UnexpectedResponseFailure(detail: 'not a list')),
        isFalse,
      );
      expect(isRetryable(const UnknownFailure(detail: 'boom')), isFalse);
    });
  });

  group('withRetry', () {
    test('a success on the first try makes exactly one attempt', () async {
      var attempts = 0;

      final result = await withRetry(() async {
        attempts++;
        return 'ok';
      }, delays: noWait);

      expect(result, 'ok');
      expect(attempts, 1);
    });

    test(
      'retries a transient failure and returns the eventual success',
      () async {
        var attempts = 0;

        final result = await withRetry(() async {
          attempts++;
          if (attempts < 3) throw const NetworkFailure();
          return 'ok';
        }, delays: noWait);

        expect(result, 'ok');
        expect(attempts, 3);
      },
    );

    test('gives up after the delay list is exhausted', () async {
      var attempts = 0;

      await expectLater(
        withRetry(() async {
          attempts++;
          throw const TimeoutFailure();
        }, delays: noWait),
        throwsA(const TimeoutFailure()),
      );

      // One initial attempt plus one per delay. The final failure propagates
      // unchanged, so the UI still gets the typed cause.
      expect(attempts, 3);
    });

    test('does not retry a non-retryable failure at all', () async {
      var attempts = 0;

      await expectLater(
        withRetry(() async {
          attempts++;
          throw const ServerFailure(statusCode: 401);
        }, delays: noWait),
        throwsA(const ServerFailure(statusCode: 401)),
      );

      expect(attempts, 1);
    });

    test('an empty delay list disables retrying', () async {
      var attempts = 0;

      await expectLater(
        withRetry(() async {
          attempts++;
          throw const NetworkFailure();
        }, delays: const []),
        throwsA(const NetworkFailure()),
      );

      expect(attempts, 1);
    });

    test('a non-CatsFailure error propagates without being retried', () async {
      // This is a retry policy, not a catch-all. Converting unexpected errors into
      // failures is the repository's job, and swallowing one here would hide it.
      var attempts = 0;

      await expectLater(
        withRetry(() async {
          attempts++;
          throw StateError('not a CatsFailure');
        }, delays: noWait),
        throwsStateError,
      );

      expect(attempts, 1);
    });

    test('waits between attempts', () async {
      // The delays are real `Future.delayed`s, not skipped. Asserted with fake
      // async so the test itself stays instant.
      await fakeAsync((elapsed) async {
        var attempts = 0;
        final future = withRetry(() async {
          attempts++;
          throw const NetworkFailure();
        }, delays: const [Duration(seconds: 2), Duration(seconds: 4)]);

        await expectLater(future, throwsA(const NetworkFailure()));
        expect(attempts, 3);
        expect(elapsed(), const Duration(seconds: 6));
      });
    });
  });
}

/// Minimal stand-in for `package:fake_async`, which is not a dependency.
///
/// Measures elapsed time by summing the delays actually awaited, which is what the
/// backoff assertion needs: that `withRetry` waits the schedule it was given
/// rather than firing straight through.
Future<void> fakeAsync(
  Future<void> Function(Duration Function() elapsed) body,
) async {
  final recorded = <Duration>[];
  await runZoned(
    () => body(() => recorded.fold(Duration.zero, (a, b) => a + b)),
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, f) {
        recorded.add(duration);
        // Run immediately: the point is to record the schedule, not to sleep it.
        return parent.createTimer(zone, Duration.zero, f);
      },
    ),
  );
}
