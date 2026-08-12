import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

abstract class LandingCatsRepository {
  /// Returns a [CatsResult] and never throws: see the catch-all in
  /// `LandingCatsRepositoryImpl`.
  Future<CatsResult<List<CatBreedEntity>>> getAllCats();

  /// Resolves one breed's image URL, caching the result.
  ///
  /// Added in Phase 4, when `getAllCats` stopped resolving all 65 up front.
  /// Implementations must be safe to call repeatedly and concurrently for the
  /// same id — a scrolling list will do exactly that.
  Future<CatsResult<String>> getBreedImageUrl(String referenceImageId);
}
