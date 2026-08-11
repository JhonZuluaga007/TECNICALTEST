import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/config/helpers/errors/invalid_data.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/repository/landing_cats_repository_impl.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockLandingCatsDataSource dataSource;
  late LandingCatsRepositoryImpl repository;

  setUp(() {
    dataSource = MockLandingCatsDataSource();
    repository = LandingCatsRepositoryImpl(landingCatsDataSource: dataSource);
  });

  group('LandingCatsRepositoryImpl.getAllCats', () {
    test('returns Right with the breeds on success', () async {
      final breeds = [
        catBreedModel(),
        catBreedModel(id: 'aege', name: 'Aegean'),
      ];
      when(() => dataSource.getAllCats()).thenAnswer((_) async => breeds);

      final result = await repository.getAllCats();

      expect(result.isRight, isTrue);
      // `either_dart` delegates `==` to the payload, and a `List` payload
      // compares by IDENTITY. Never `expect(result, Right(breeds))`: it would
      // pass or fail for the wrong reason. Compare the contents instead.
      expect(result.right, equals(breeds));
      verify(() => dataSource.getAllCats()).called(1);
    });

    test('returns Left when the datasource throws InvalidData', () async {
      const failure = InvalidData(message: 'boom', statusCode: 500);
      when(() => dataSource.getAllCats()).thenThrow(failure);

      final result = await repository.getAllCats();

      expect(result.isLeft, isTrue);
      // Here the direct comparison is fine: the payload is a single Equatable
      // object, not a collection.
      expect(result.left, failure);
    });

    test('propagates an error that is not InvalidData', () async {
      // Characterization: `on InvalidData` catches only that class, so any other
      // error escapes the `Either` channel. Phase 3 changes this when it
      // introduces `CatsFailure`.
      when(() => dataSource.getAllCats()).thenThrow(StateError('unexpected'));

      await expectLater(repository.getAllCats(), throwsStateError);
    });

    test(
      'returns Right with an empty list when the datasource returns nothing',
      () async {
        when(() => dataSource.getAllCats()).thenAnswer((_) async => []);

        final result = await repository.getAllCats();

        expect(result.isRight, isTrue);
        expect(result.right, isEmpty);
      },
    );
  });
}
