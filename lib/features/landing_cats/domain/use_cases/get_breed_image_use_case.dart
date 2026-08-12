import 'package:tecnical_test_pragma/core/utils/cats_result.dart';

import '../repository/landing_cats_repository.dart';

/// Resolves a single breed's image URL.
///
/// Exists because Phase 4 stopped resolving all 65 URLs inside
/// `getAllCats`. One card, one call, on demand.
class GetBreedImageUseCase {
  GetBreedImageUseCase({required this.landingCatsRepository});

  final LandingCatsRepository landingCatsRepository;

  /// Returns `Ok('')` when the breed has no reference image rather than a
  /// failure: 2 of the 67 breeds genuinely have none, and "this breed has no
  /// photo" is not an error condition.
  Future<CatsResult<String>> call(String referenceImageId) =>
      landingCatsRepository.getBreedImageUrl(referenceImageId);
}
