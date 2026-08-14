import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/breeds_snapshot.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

abstract class LandingCatsRepository {
  /// Every breed, from the cache when it is fresh and from the network otherwise.
  ///
  /// Returns a [CatsResult] and never throws: see the catch-all in
  /// `LandingCatsRepositoryImpl`.
  ///
  /// Phase 6 changed the payload from a bare list to a [BreedsSnapshot], because
  /// "here are the breeds" stopped being the whole answer: an expired cache plus a
  /// failed refresh still produces a usable list, and the UI needs to know that is
  /// what it got. An `Err` now means there is nothing to show at all.
  Future<CatsResult<BreedsSnapshot>> getAllCats();

  /// One breed by its API id.
  ///
  /// Added in Phase 6, when the detail screen started receiving an id from the URL
  /// instead of a whole entity through `go_router`'s `extra`. Implementations
  /// resolve it against the same cache-then-network path as [getAllCats], so a
  /// deep link works on a cold start.
  ///
  /// An id that matches nothing is a `CatsFailure.notFound`, not an empty success:
  /// there is no breed to render, and it is not a transport error either.
  Future<CatsResult<CatBreedEntity>> getBreedById(String id);

  /// Resolves one breed's image URL, caching the result.
  ///
  /// Added in Phase 4, when `getAllCats` stopped resolving all 65 up front.
  /// Implementations must be safe to call repeatedly and concurrently for the
  /// same id — a scrolling list will do exactly that.
  Future<CatsResult<String>> getBreedImageUrl(String referenceImageId);
}
