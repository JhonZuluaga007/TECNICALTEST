import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockLandingCatsRepository repository;
  late GetAllCatsUseCase useCase;

  setUp(() {
    repository = MockLandingCatsRepository();
    useCase = GetAllCatsUseCase(landingCatsRepository: repository);
  });

  group('GetAllCatsUseCase', () {
    test('forwards the repository Ok', () async {
      final breeds = [catBreedModel()];
      when(
        () => repository.getAllCats(),
      ).thenAnswer((_) async => Ok<List<CatBreedEntity>>(breeds));

      final result = await useCase.getAllCatsCall();

      expect((result as Ok<List<CatBreedEntity>>).value, equals(breeds));
      verify(() => repository.getAllCats()).called(1);
    });

    test('forwards the repository Err', () async {
      const failure = ServerFailure(statusCode: 500);
      when(
        () => repository.getAllCats(),
      ).thenAnswer((_) async => const Err<List<CatBreedEntity>>(failure));

      final result = await useCase.getAllCatsCall();

      expect((result as Err<List<CatBreedEntity>>).failure, failure);
      verify(() => repository.getAllCats()).called(1);
    });
  });
}
