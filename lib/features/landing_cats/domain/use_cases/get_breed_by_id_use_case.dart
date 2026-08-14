import 'package:injectable/injectable.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

import '../repository/landing_cats_repository.dart';

/// Resolves a single breed by its API id.
///
/// New in Phase 6. It exists because the detail route stopped carrying a whole
/// `CatBreedEntity` in `go_router`'s `extra` — which was not reconstructible from
/// a URL, so a deep link arrived with `extra == null` and the page blew up — and
/// started carrying an id instead. Somebody has to turn that id back into a breed,
/// and doing it here means the detail screen works on a cold start rather than
/// only when the user walked there from the list.
///
/// A factory, for the same reason as the other two: no state of its own. The cache
/// it reaches lives in the repository, which IS a singleton.
@injectable
class GetBreedByIdUseCase {
  GetBreedByIdUseCase({required this.landingCatsRepository});

  final LandingCatsRepository landingCatsRepository;

  /// Returns `Err(NotFoundFailure)` for an id that matches nothing — a stale
  /// link, a typed URL — which the detail screen renders as a message rather than
  /// as a blank page.
  Future<CatsResult<CatBreedEntity>> call(String id) =>
      landingCatsRepository.getBreedById(id);
}
