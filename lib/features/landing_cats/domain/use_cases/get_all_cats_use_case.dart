import 'package:injectable/injectable.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

import '../repository/landing_cats_repository.dart';

/// A factory, not a singleton: it is a stateless wrapper over the repository, so
/// sharing one instance buys nothing.
@injectable
class GetAllCatsUseCase {
  GetAllCatsUseCase({required this.landingCatsRepository});

  final LandingCatsRepository landingCatsRepository;

  Future<CatsResult<List<CatBreedEntity>>> getAllCatsCall() =>
      landingCatsRepository.getAllCats();
}
