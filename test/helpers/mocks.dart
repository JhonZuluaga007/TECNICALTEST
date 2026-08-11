import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_data_source.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/repository/landing_cats_repository.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';
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

class MockLandingCatsBloc extends MockBloc<LandingCatsEvent, LandingCatsState>
    implements LandingCatsBloc {}
