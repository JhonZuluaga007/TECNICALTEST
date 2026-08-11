import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/repository/landing_cats_repository.dart';

import '../datasource/landing_cats_data_source.dart';

class LandingCatsRepositoryImpl implements LandingCatsRepository {
  LandingCatsRepositoryImpl({required this.landingCatsDataSource});

  final LandingCatsDataSource landingCatsDataSource;

  @override
  Future<CatsResult<List<CatBreedEntity>>> getAllCats() async {
    try {
      return Ok(await landingCatsDataSource.getAllCats());
    } on CatsFailure catch (failure) {
      return Err(failure);
    } catch (error) {
      // The catch-all makes this a total function. It used to be `on InvalidData`
      // only, so any other error escaped the result channel entirely and the
      // bloc's `fold` never ran — the app just sat on its spinner. Phase 2 pinned
      // that with a characterization test; Phase 3 replaces it.
      //
      // Nothing above the data layer should ever have to handle a raw exception.
      return Err(UnknownFailure(detail: '$error'));
    }
  }
}
