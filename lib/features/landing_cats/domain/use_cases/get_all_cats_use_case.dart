import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

import '../repository/landing_cats_repository.dart';

class GetAllCatsUseCase {
  GetAllCatsUseCase({required this.landingCatsRepository});

  final LandingCatsRepository landingCatsRepository;

  Future<CatsResult<List<CatBreedEntity>>> getAllCatsCall() =>
      landingCatsRepository.getAllCats();
}
