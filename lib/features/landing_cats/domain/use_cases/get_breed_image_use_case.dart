import 'package:injectable/injectable.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';

import '../repository/landing_cats_repository.dart';

/// Resolves a single breed's image URL.
///
/// Exists because Phase 4 stopped resolving all 65 URLs inside
/// `getAllCats`. One card, one call, on demand.
/// A factory, for the same reason as `GetAllCatsUseCase`: no state of its own. The
/// cache it reaches lives in the repository, which IS a singleton.
@injectable
class GetBreedImageUseCase {
  GetBreedImageUseCase({required this.landingCatsRepository});

  final LandingCatsRepository landingCatsRepository;

  /// Returns `Ok('')` when the breed has no reference image rather than a
  /// failure: 2 of the 67 breeds genuinely have none, and "this breed has no
  /// photo" is not an error condition.
  Future<CatsResult<String>> call(String referenceImageId) =>
      landingCatsRepository.getBreedImageUrl(referenceImageId);
}
