import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';

/// The success-or-failure channel between the data layer and the bloc.
///
/// Phase 3 replaced `either_dart` with this. Three reasons:
///
/// 1. `Either.fold` takes two closures and the compiler cannot tell whether both
///    branches were handled. A `switch` over a `sealed` type can, and does.
/// 2. `either_dart` delegates `==` to its payload, so an `Either` holding a
///    `List` compares by **identity**. Phase 2 had to document that trap in every
///    test that touched the repository (`expect(result, Right(list))` passes or
///    fails for the wrong reason). It is gone with the package.
/// 3. One less dependency for something the language now expresses natively.
///
/// **One type parameter, not two.** The failure channel is always
/// [CatsFailure], so a second generic would only add noise to every signature.
///
/// Deliberately **not** `Equatable`: this is a transport wrapper, and giving it
/// value equality would reintroduce exactly the payload-identity trap described
/// above. Tests assert on the variant and then on its contents:
///
/// ```dart
/// expect(result, isA<Ok<List<CatBreedEntity>>>());
/// expect((result as Ok<List<CatBreedEntity>>).value, equals(breeds));
/// ```
sealed class CatsResult<T> {
  const CatsResult();
}

final class Ok<T> extends CatsResult<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends CatsResult<T> {
  const Err(this.failure);

  final CatsFailure failure;
}
