import 'package:either_dart/either.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

import '../../../../core/config/helpers/errors/invalid_data.dart';

abstract class LandingCatsRepository {
  Future<Either<InvalidData, List<CatBreedEntity>>> getAllCats();
}
