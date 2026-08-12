import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';

/// Whether retrying [failure] could plausibly produce a different answer.
///
/// The distinction is the whole value of having typed failures. Before Phase 3
/// every cause collapsed into one interpolated string, so a retry policy could
/// only have been "retry everything" — which would multiply the user's wait by the
/// attempt count for errors that are guaranteed to repeat.
///
/// Retryable: no connection, a timeout, and 5xx — all transient by definition.
///
/// Not retryable: any 4xx (the request itself is wrong; a missing key will still
/// be missing), a malformed payload (it will parse identically next time), and
/// [UnknownFailure] (by definition we do not know it is safe to repeat).
bool isRetryable(CatsFailure failure) => switch (failure) {
  NetworkFailure() => true,
  TimeoutFailure() => true,
  ServerFailure(:final statusCode) => statusCode >= 500,
  UnexpectedResponseFailure() => false,
  UnknownFailure() => false,
};

/// Runs [action], retrying transient failures with a backoff.
///
/// One entry in [delays] per retry, so the default makes at most 3 attempts: the
/// first, then one 400 ms later, then one 1 s later. Exponential rather than fixed
/// because a server that just returned 503 is better served by backing off than by
/// being asked again immediately.
///
/// [delays] is a parameter rather than a computed schedule so tests can pass
/// `[Duration.zero, Duration.zero]` and assert the attempt count without spending
/// real wall-clock time — the same seam `LandingCatsDataSource.timeout` uses.
///
/// Anything that is not a [CatsFailure] propagates untouched: this is a retry
/// policy, not a catch-all. Turning unexpected errors into failures is the
/// repository's job.
Future<T> withRetry<T>(
  Future<T> Function() action, {
  List<Duration> delays = const [
    Duration(milliseconds: 400),
    Duration(seconds: 1),
  ],
}) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return await action();
    } on CatsFailure catch (failure) {
      if (attempt >= delays.length || !isRetryable(failure)) rethrow;
      await Future<void>.delayed(delays[attempt]);
    }
  }
}
