import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_data_source.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/repository/landing_cats_repository.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_by_id_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_image_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';

/// All of these use `implements`, not `extends`, so the concrete constructors'
/// required parameters are irrelevant.
///
/// **A cost of that worth knowing**, noticed in Phase 6: `implements` also means
/// these absorb new methods silently. Adding `getBreedById` to
/// `LandingCatsRepository` broke nothing here — mocktail generated a stub for it,
/// and a test that forgets to configure one fails at *runtime*, not at compile
/// time. The compiler stops guarding the interface at exactly this line.
///
/// A deliberate omission: there is no `http.Client` mock. At the HTTP boundary we
/// use `MockClient` from `package:http/testing.dart`, which runs the real
/// `BaseClient.get -> send` path and therefore genuinely exercises `Uri`
/// construction, headers and charset decoding. A `Mock implements http.Client`
/// would stub `BaseClient` out entirely: we would be testing the stub.
class MockLandingCatsDataSource extends Mock implements LandingCatsDataSource {}

class MockLandingCatsRepository extends Mock implements LandingCatsRepository {}

class MockGetAllCatsUseCase extends Mock implements GetAllCatsUseCase {}

class MockGetBreedImageUseCase extends Mock implements GetBreedImageUseCase {}

class MockGetBreedByIdUseCase extends Mock implements GetBreedByIdUseCase {}

/// A `GetBreedImageUseCase` that answers immediately, without stubbing.
///
/// Every widget test that paints a card now paints a `BreedImage`, which resolves
/// through this use case. Most of those tests care about the card's text, not its
/// photo, so they get this fake by default from `pumpAppWith` — and the default
/// [url] is empty, which renders the placeholder asset and touches no network.
class FakeGetBreedImageUseCase extends Fake implements GetBreedImageUseCase {
  FakeGetBreedImageUseCase({this.url = ''});

  final String url;

  /// Ids this fake was asked to resolve, in order. Lets a test assert that images
  /// are requested lazily — that is, only for the cards actually built.
  final List<String> requested = [];

  @override
  Future<CatsResult<String>> call(String referenceImageId) async {
    requested.add(referenceImageId);
    return Ok(url);
  }
}

/// A `GetBreedByIdUseCase` that answers immediately, without stubbing.
///
/// The counterpart to [FakeGetBreedImageUseCase], and it exists for a reason worth
/// recording: `pumpAppWith` first defaulted to a bare `MockGetBreedByIdUseCase`,
/// and an unstubbed mocktail method returns `null`, which surfaced as
/// `type 'Null' is not a subtype of type 'Future<CatsResult<CatBreedEntity>>'`
/// **inside a widget build** — a stack trace pointing at provider internals rather
/// than at the missing stub. That is the concrete cost of the `implements` mocks
/// noted at the top of this file.
///
/// The default answer is [NotFoundFailure], which renders the error view: visible,
/// harmless, and honest for a test that never said which breed it wanted.
class FakeGetBreedByIdUseCase extends Fake implements GetBreedByIdUseCase {
  FakeGetBreedByIdUseCase({this.breed});

  /// Answered for any id when set.
  final CatBreedEntity? breed;

  /// Ids this fake was asked to resolve, in order.
  final List<String> requested = [];

  @override
  Future<CatsResult<CatBreedEntity>> call(String id) async {
    requested.add(id);
    final breed = this.breed;
    return breed == null ? Err(NotFoundFailure(id: id)) : Ok(breed);
  }
}

class MockLandingCatsBloc extends MockBloc<LandingCatsEvent, LandingCatsState>
    implements LandingCatsBloc {}
