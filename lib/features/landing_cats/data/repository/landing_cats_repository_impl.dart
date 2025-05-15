import 'package:either_dart/either.dart';
import 'package:tecnical_test_pragma/core/config/helpers/errors/invalid_data.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/repository/landing_cats_repository.dart';

import '../datasource/landing_cats_data_source.dart';

class LandingCatsRepositoryImpl implements LandingCatsRepository {
  final LandingCatsDataSource landingCatsDataSource;
  LandingCatsRepositoryImpl({
    required this.landingCatsDataSource,
  });

  @override
  Future<Either<InvalidData, List<CatBreedEntity>>> getAllCats() async {
    try {
      final List<CatBreedEntity> reponseAllEvents =
          await landingCatsDataSource.getAllCats();
      return Right(reponseAllEvents);
    } on InvalidData catch (invalidData) {
      return Left(invalidData);
    }
  }
}
