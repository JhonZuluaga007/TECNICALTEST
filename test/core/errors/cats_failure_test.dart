import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';

/// Replaces `invalid_data_test.dart`, deleted with `InvalidData` in Phase 3.
void main() {
  group('CatsFailure', () {
    test('is an Exception, because the data source throws it', () {
      expect(const NetworkFailure(), isA<Exception>());
      expect(const ServerFailure(statusCode: 500), isA<Exception>());
    });

    test('two instances of the same variant are equal', () {
      expect(const NetworkFailure(), const NetworkFailure());
      expect(const TimeoutFailure(), const TimeoutFailure());
      expect(
        const ServerFailure(statusCode: 500),
        const ServerFailure(statusCode: 500),
      );
      expect(
        const UnknownFailure(detail: 'boom'),
        const UnknownFailure(detail: 'boom'),
      );
    });

    test('different variants are never equal', () {
      expect(const NetworkFailure(), isNot(const TimeoutFailure()));
      // Same shape (a single `detail` field), different meaning. They stay
      // distinct because `Equatable.operator ==` compares `runtimeType`.
      expect(
        const UnknownFailure(detail: 'x'),
        isNot(const UnexpectedResponseFailure(detail: 'x')),
      );
    });

    test('variants carrying data compare by that data', () {
      expect(
        const ServerFailure(statusCode: 500),
        isNot(const ServerFailure(statusCode: 404)),
      );
      expect(
        const UnexpectedResponseFailure(detail: 'not a list'),
        isNot(const UnexpectedResponseFailure(detail: 'not a map')),
      );
    });

    test('hashCode is consistent with ==', () {
      expect(
        const ServerFailure(statusCode: 500).hashCode,
        const ServerFailure(statusCode: 500).hashCode,
      );
    });

    test('an exhaustive switch needs no default clause', () {
      // The assertion is partly that this function COMPILES: a `switch`
      // expression over a non-sealed type without a default is an error. That
      // compile-time guarantee is the whole reason the hierarchy is sealed, and
      // it is what forces the UI to have an error branch.
      String kind(CatsFailure failure) => switch (failure) {
        NetworkFailure() => 'network',
        TimeoutFailure() => 'timeout',
        ServerFailure(:final statusCode) => 'server:$statusCode',
        UnexpectedResponseFailure() => 'unexpected',
        UnknownFailure() => 'unknown',
      };

      expect(kind(const NetworkFailure()), 'network');
      expect(kind(const TimeoutFailure()), 'timeout');
      expect(kind(const ServerFailure(statusCode: 401)), 'server:401');
      expect(kind(const UnexpectedResponseFailure(detail: 'x')), 'unexpected');
      expect(kind(const UnknownFailure(detail: 'x')), 'unknown');
    });
  });
}
