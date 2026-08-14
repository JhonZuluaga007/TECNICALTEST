import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/breeds_snapshot.dart';
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
      final breeds = [catBreedEntity()];
      when(
        () => repository.getAllCats(),
      ).thenAnswer((_) async => Ok(FreshBreeds(breeds: breeds)));

      final result = await useCase.getAllCatsCall();

      expect((result as Ok<BreedsSnapshot>).value.breeds, equals(breeds));
      verify(() => repository.getAllCats()).called(1);
    });

    test('forwards a stale snapshot without flattening it', () async {
      // Phase 6. The use case must not "simplify" a stale snapshot into a plain
      // list or into an `Err`: freshness is the one thing only the data layer
      // knows, and dropping it here would silently delete the offline behaviour
      // the whole phase is about.
      final breeds = [catBreedEntity()];
      when(() => repository.getAllCats()).thenAnswer(
        (_) async =>
            Ok(StaleBreeds(breeds: breeds, failure: const NetworkFailure())),
      );

      final result = await useCase.getAllCatsCall();

      final snapshot = (result as Ok<BreedsSnapshot>).value;
      expect(snapshot, isA<StaleBreeds>());
      expect((snapshot as StaleBreeds).failure, const NetworkFailure());
      expect(snapshot.breeds, equals(breeds));
    });

    test('forwards the repository Err', () async {
      const failure = ServerFailure(statusCode: 500);
      when(
        () => repository.getAllCats(),
      ).thenAnswer((_) async => const Err<BreedsSnapshot>(failure));

      final result = await useCase.getAllCatsCall();

      expect((result as Err<BreedsSnapshot>).failure, failure);
      verify(() => repository.getAllCats()).called(1);
    });
  });
}
