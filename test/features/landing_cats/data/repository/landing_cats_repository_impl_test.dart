import 'dart:async';

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
    test('maps the models to entities on success', () async {
      final models = <CatBreedModel>[
        catBreedModel(),
        catBreedModel(id: 'aege', name: 'Aegean'),
      ];
      when(() => dataSource.getAllCats()).thenAnswer((_) async => models);

      final result = await repository.getAllCats();

      // Assert on the variant, then on the contents. `CatsResult` defines no `==`
      // on purpose: `either_dart` delegated its `==` to the payload, so
      // `expect(result, Right(breeds))` compared the LIST BY IDENTITY and passed
      // or failed for the wrong reason. That trap is gone with the package.
      expect(result, isA<Ok<List<CatBreedEntity>>>());
      final breeds = (result as Ok<List<CatBreedEntity>>).value;

      // Phase 4: this used to read `equals(models)` and pass, because
      // `CatBreedModel extends CatBreedEntity` made `Ok(models)` type-check —
      // the repository returned the models themselves and the domain type was a
      // label. Now the conversion is real, so the models are NOT what comes back.
      expect(breeds, equals([for (final m in models) m.toEntity()]));
      expect(breeds, isNot(equals(models)));
      expect(breeds.first, isA<CatBreedEntity>());
      expect(breeds.first, isNot(isA<CatBreedModel>()));
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

  group('LandingCatsRepositoryImpl.getBreedImageUrl', () {
    test('returns the resolved url', () async {
      when(
        () => dataSource.getBreedImageUrl('0XYvRd7oD'),
      ).thenAnswer((_) async => 'https://cdn2.thecatapi.com/images/x.jpg');

      final result = await repository.getBreedImageUrl('0XYvRd7oD');

      expect(
        (result as Ok<String>).value,
        'https://cdn2.thecatapi.com/images/x.jpg',
      );
    });

    test('caches, so the second call makes no request', () async {
      // Phase 4 case #2. Without this, scrolling a list up and down re-requests
      // every image it re-builds — `ListView` disposes off-screen children, so the
      // cubit and its request are recreated each time a card comes back into view.
      when(
        () => dataSource.getBreedImageUrl('0XYvRd7oD'),
      ).thenAnswer((_) async => 'https://x/y.jpg');

      final first = await repository.getBreedImageUrl('0XYvRd7oD');
      final second = await repository.getBreedImageUrl('0XYvRd7oD');

      expect((first as Ok<String>).value, 'https://x/y.jpg');
      expect((second as Ok<String>).value, 'https://x/y.jpg');
      verify(() => dataSource.getBreedImageUrl('0XYvRd7oD')).called(1);
    });

    test('caches per id, not globally', () async {
      when(
        () => dataSource.getBreedImageUrl('a'),
      ).thenAnswer((_) async => 'https://x/a.jpg');
      when(
        () => dataSource.getBreedImageUrl('b'),
      ).thenAnswer((_) async => 'https://x/b.jpg');

      expect(
        ((await repository.getBreedImageUrl('a')) as Ok<String>).value,
        'https://x/a.jpg',
      );
      expect(
        ((await repository.getBreedImageUrl('b')) as Ok<String>).value,
        'https://x/b.jpg',
      );
    });

    test('de-duplicates concurrent requests for the same id', () async {
      // Phase 4 case #3, and the one the cache alone does NOT solve: the cache is
      // only populated after a response arrives, so four cards built in the same
      // frame would each fire their own request. The list can genuinely do this —
      // `ListView` builds every visible child in one pass.
      final completer = Completer<String>();
      when(
        () => dataSource.getBreedImageUrl('0XYvRd7oD'),
      ).thenAnswer((_) => completer.future);

      final first = repository.getBreedImageUrl('0XYvRd7oD');
      final second = repository.getBreedImageUrl('0XYvRd7oD');
      final third = repository.getBreedImageUrl('0XYvRd7oD');

      completer.complete('https://x/y.jpg');
      final results = await Future.wait([first, second, third]);

      verify(() => dataSource.getBreedImageUrl('0XYvRd7oD')).called(1);
      for (final result in results) {
        expect((result as Ok<String>).value, 'https://x/y.jpg');
      }
    });

    test('a failed resolution does not poison the id forever', () async {
      // The in-flight entry has to be cleared on failure too. Leaving a rejected
      // future parked there would make the error permanent for that id for the
      // lifetime of the app — and since the repository is a singleton, that is the
      // lifetime of the process.
      var attempts = 0;
      when(() => dataSource.getBreedImageUrl('0XYvRd7oD')).thenAnswer((
        _,
      ) async {
        attempts++;
        if (attempts == 1) throw const NetworkFailure();
        return 'https://x/y.jpg';
      });

      final failed = await repository.getBreedImageUrl('0XYvRd7oD');
      expect((failed as Err<String>).failure, const NetworkFailure());

      final retried = await repository.getBreedImageUrl('0XYvRd7oD');
      expect((retried as Ok<String>).value, 'https://x/y.jpg');
      expect(attempts, 2);
    });

    test('a failure is never cached as a url', () async {
      when(
        () => dataSource.getBreedImageUrl('0XYvRd7oD'),
      ).thenThrow(StateError('boom'));

      final result = await repository.getBreedImageUrl('0XYvRd7oD');

      expect(result, isA<Err<String>>());
      expect((result as Err<String>).failure, isA<UnknownFailure>());
    });

    test(
      'an empty url IS cached — the datasource already tolerated it',
      () async {
        // `getBreedImageUrl` returns `''` for a breed with no image rather than
        // failing, so `''` is a legitimate answer and re-asking would be pure waste:
        // 2 of the 67 breeds are in this state permanently.
        when(() => dataSource.getBreedImageUrl('')).thenAnswer((_) async => '');

        await repository.getBreedImageUrl('');
        await repository.getBreedImageUrl('');

        verify(() => dataSource.getBreedImageUrl('')).called(1);
      },
    );
  });
}
