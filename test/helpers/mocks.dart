import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_data_source.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/repository/landing_cats_repository.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_image_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';

/// All of these use `implements`, not `extends`, so the concrete constructors'
/// required parameters are irrelevant.
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

class MockLandingCatsBloc extends MockBloc<LandingCatsEvent, LandingCatsState>
    implements LandingCatsBloc {}
