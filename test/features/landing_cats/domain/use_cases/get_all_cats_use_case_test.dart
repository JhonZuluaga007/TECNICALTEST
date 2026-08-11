import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/config/helpers/errors/invalid_data.dart';
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
    test('forwards the repository Right', () async {
      final breeds = [catBreedModel()];
      when(() => repository.getAllCats()).thenAnswer(
        (_) async => Right<InvalidData, List<CatBreedEntity>>(breeds),
      );

      final result = await useCase.getAllCatsCall();

      expect(result.isRight, isTrue);
      expect(result.right, equals(breeds));
      verify(() => repository.getAllCats()).called(1);
    });

    test('forwards the repository Left', () async {
      const failure = InvalidData(message: 'boom', statusCode: 500);
      when(() => repository.getAllCats()).thenAnswer(
        (_) async => const Left<InvalidData, List<CatBreedEntity>>(failure),
      );

      final result = await useCase.getAllCatsCall();

      expect(result.isLeft, isTrue);
      expect(result.left, failure);
      verify(() => repository.getAllCats()).called(1);
    });
  });
}
