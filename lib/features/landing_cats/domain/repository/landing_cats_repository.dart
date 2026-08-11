import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

abstract class LandingCatsRepository {
  /// Returns a [CatsResult] and never throws: see the catch-all in
  /// `LandingCatsRepositoryImpl`.
  Future<CatsResult<List<CatBreedEntity>>> getAllCats();
}
