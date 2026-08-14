import 'package:injectable/injectable.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/breeds_snapshot.dart';

import '../repository/landing_cats_repository.dart';

/// A factory, not a singleton: it is a stateless wrapper over the repository, so
/// sharing one instance buys nothing.
@injectable
class GetAllCatsUseCase {
  GetAllCatsUseCase({required this.landingCatsRepository});

  final LandingCatsRepository landingCatsRepository;

  /// Forwards the [BreedsSnapshot] unchanged rather than unwrapping it to a bare
  /// list. Unwrapping would drop the freshness, which is the one thing only the
  /// data layer knows and the only thing the bloc needs it for.
  Future<CatsResult<BreedsSnapshot>> getAllCatsCall() =>
      landingCatsRepository.getAllCats();
}
