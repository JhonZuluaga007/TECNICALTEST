import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';

/// Routes a result through an exhaustive `switch` with **no default clause**.
///
/// Declared at the top level so that the compile-time guarantee is part of the
/// library, not buried in a test body: if `CatsResult` stopped being `sealed`,
/// or a third variant appeared, this stops compiling. That is the property that
/// replaced `Either.fold`, whose two closures the compiler cannot check.
String describe(CatsResult<int> result) => switch (result) {
  Ok(:final value) => 'ok:$value',
  Err(:final failure) => 'err:${failure.runtimeType}',
};

void main() {
  group('CatsResult', () {
    test('Ok carries the value', () {
      const result = Ok<int>(42);

      expect(result, isA<CatsResult<int>>());
      expect(result.value, 42);
    });

    test('Err carries the failure', () {
      const result = Err<int>(ServerFailure(statusCode: 500));

      expect(result.failure, const ServerFailure(statusCode: 500));
    });

    test('an exhaustive switch routes to the right branch', () {
      expect(describe(const Ok(7)), 'ok:7');
      expect(describe(const Err(NetworkFailure())), 'err:NetworkFailure');
    });

    test('it holds a list without comparing it by identity', () {
      // The trap this type was created to remove: `either_dart` delegates `==`
      // to its payload, so `Right([1, 2]) != Right([1, 2])`. `CatsResult` has no
      // `==` at all, so there is no misleading comparison to write — tests assert
      // on the variant and then on the contents.
      const first = Ok<List<int>>([1, 2]);
      final second = Ok<List<int>>([1, 2]);

      expect(first.value, equals(second.value));
      expect(first.value, isNot(same(second.value)));
    });
  });
}
