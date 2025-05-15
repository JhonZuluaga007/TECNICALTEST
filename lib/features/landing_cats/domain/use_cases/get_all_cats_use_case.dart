import 'package:either_dart/either.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

import '../../../../core/config/helpers/errors/invalid_data.dart';
import '../repository/landing_cats_repository.dart';

class GetAllCatsUseCase {
  final LandingCatsRepository landingCatsRepository;
  GetAllCatsUseCase({
    required this.landingCatsRepository,
  });

  Future<Either<InvalidData, List<CatBreedEntity>>> getAllCatsCall() async {
    return await landingCatsRepository.getAllCats();
  }
}
