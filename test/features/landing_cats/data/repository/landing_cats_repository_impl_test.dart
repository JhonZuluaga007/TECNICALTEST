import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/repository/landing_cats_repository_impl.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

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
    test('returns Ok with the breeds on success', () async {
      final breeds = <CatBreedModel>[
        catBreedModel(),
        catBreedModel(id: 'aege', name: 'Aegean'),
      ];
      when(() => dataSource.getAllCats()).thenAnswer((_) async => breeds);

      final result = await repository.getAllCats();

      // Assert on the variant, then on the contents. `CatsResult` defines no `==`
      // on purpose: `either_dart` delegated its `==` to the payload, so
      // `expect(result, Right(breeds))` compared the LIST BY IDENTITY and passed
      // or failed for the wrong reason. That trap is gone with the package.
      expect(result, isA<Ok<List<CatBreedEntity>>>());
      expect((result as Ok<List<CatBreedEntity>>).value, equals(breeds));
      verify(() => dataSource.getAllCats()).called(1);
    });

    test('returns Err when the data source throws a CatsFailure', () async {
      const failure = ServerFailure(statusCode: 500);
      when(() => dataSource.getAllCats()).thenThrow(failure);

      final result = await repository.getAllCats();

      expect(result, isA<Err<List<CatBreedEntity>>>());
      expect((result as Err<List<CatBreedEntity>>).failure, failure);
    });

    test('forwards each failure variant unchanged', () async {
      for (final failure in const <CatsFailure>[
        NetworkFailure(),
        TimeoutFailure(),
        ServerFailure(statusCode: 401),
        UnexpectedResponseFailure(detail: 'bad shape'),
      ]) {
        when(() => dataSource.getAllCats()).thenThrow(failure);

        final result = await repository.getAllCats();

        expect(
          (result as Err<List<CatBreedEntity>>).failure,
          failure,
          reason: 'the repository must not flatten $failure',
        );
      }
    });

    test('converts an unanticipated error into Err(UnknownFailure)', () async {
      // Phase 3 behavior change. This REPLACES the Phase 2 characterization test
      // ('propagates an error that is not InvalidData'), which pinned the old
      // `on InvalidData`-only catch: anything else escaped the result channel, the
      // bloc's `fold` never ran, and the UI sat on its spinner forever.
      //
      // `getAllCats` is now a total function: nothing above the data layer has to
      // handle a raw exception.
      when(() => dataSource.getAllCats()).thenThrow(StateError('unexpected'));

      final result = await repository.getAllCats();

      expect(result, isA<Err<List<CatBreedEntity>>>());
      expect(
        (result as Err<List<CatBreedEntity>>).failure,
        isA<UnknownFailure>().having(
          (f) => f.detail,
          'detail',
          contains('unexpected'),
        ),
      );
    });

    test(
      'returns Ok with an empty list when the data source returns none',
      () async {
        when(() => dataSource.getAllCats()).thenAnswer((_) async => []);

        final result = await repository.getAllCats();

        expect((result as Ok<List<CatBreedEntity>>).value, isEmpty);
      },
    );
  });
}
