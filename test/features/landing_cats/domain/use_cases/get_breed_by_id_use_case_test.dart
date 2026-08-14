import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_by_id_use_case.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockLandingCatsRepository repository;
  late GetBreedByIdUseCase useCase;

  setUp(() {
    repository = MockLandingCatsRepository();
    useCase = GetBreedByIdUseCase(landingCatsRepository: repository);
  });

  group('GetBreedByIdUseCase', () {
    test('forwards the id to the repository and the breed back', () async {
      final breed = catBreedEntity(name: 'Bengal');
      when(
        () => repository.getBreedById('beng'),
      ).thenAnswer((_) async => Ok(breed));

      final result = await useCase('beng');

      expect((result as Ok<CatBreedEntity>).value, breed);
      verify(() => repository.getBreedById('beng')).called(1);
    });

    test('forwards a NotFoundFailure unchanged', () async {
      when(() => repository.getBreedById('nope')).thenAnswer(
        (_) async => const Err<CatBreedEntity>(NotFoundFailure(id: 'nope')),
      );

      final result = await useCase('nope');

      expect(
        (result as Err<CatBreedEntity>).failure,
        const NotFoundFailure(id: 'nope'),
      );
    });
  });
}
