import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_local_data_source.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/repository/landing_cats_repository_impl.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/breeds_snapshot.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/in_memory_key_value_store.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockLandingCatsDataSource dataSource;
  late InMemoryKeyValueStore store;
  late LandingCatsRepositoryImpl repository;

  /// A fixed clock, so cache expiry is a parameter of the test rather than of the
  /// wall clock.
  final now = DateTime.utc(2026, 8, 14, 12);

  /// Builds a repository whose cache believes it is [at].
  ///
  /// Passing a time later than the one an entry was written at is how a test makes
  /// that entry expired without waiting twelve hours.
  LandingCatsRepositoryImpl repositoryAt(DateTime at) =>
      LandingCatsRepositoryImpl(
        landingCatsDataSource: dataSource,
        localDataSource: LandingCatsLocalDataSource(
          store: store,
          clock: () => at,
        ),
      );

  setUp(() {
    dataSource = MockLandingCatsDataSource();
    store = InMemoryKeyValueStore();
    repository = repositoryAt(now);
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
      expect(result, isA<Ok<BreedsSnapshot>>());
      final snapshot = (result as Ok<BreedsSnapshot>).value;

      // Phase 6: a network answer is `fresh` by definition. The variant is not
      // decoration — it is what the bloc switches on to decide between the list
      // and the list-with-a-notice.
      expect(snapshot, isA<FreshBreeds>());

      // Phase 4: this used to read `equals(models)` and pass, because
      // `CatBreedModel extends CatBreedEntity` made `Ok(models)` type-check —
      // the repository returned the models themselves and the domain type was a
      // label. Now the conversion is real, so the models are NOT what comes back.
      expect(snapshot.breeds, equals([for (final m in models) m.toEntity()]));
      expect(snapshot.breeds, isNot(equals(models)));
      expect(snapshot.breeds.first, isA<CatBreedEntity>());
      expect(snapshot.breeds.first, isNot(isA<CatBreedModel>()));
      verify(() => dataSource.getAllCats()).called(1);
    });

    test(
      'returns Err when the data source throws and there is no cache',
      () async {
        const failure = ServerFailure(statusCode: 500);
        when(() => dataSource.getAllCats()).thenThrow(failure);

        final result = await repository.getAllCats();

        // `Err` means "nothing to show at all". With a cache present this same
        // input produces `Ok(StaleBreeds)` instead — see the cache group below.
        expect(result, isA<Err<BreedsSnapshot>>());
        expect((result as Err<BreedsSnapshot>).failure, failure);
      },
    );

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
          (result as Err<BreedsSnapshot>).failure,
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

      expect(result, isA<Err<BreedsSnapshot>>());
      expect(
        (result as Err<BreedsSnapshot>).failure,
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

        expect((result as Ok<BreedsSnapshot>).value.breeds, isEmpty);
      },
    );
  });

  group('LandingCatsRepositoryImpl.getAllCats and the cache', () {
    test('a fresh cache is served without touching the network', () async {
      // The assertion that matters is `verifyNever`, not the value: this is the
      // fix for "every return from the detail screen refetches". Asserting only
      // the breeds would pass just as well with the network being hit.
      when(
        () => dataSource.getAllCats(),
      ).thenAnswer((_) async => modelsFrom('breeds_3.json'));

      await repository.getAllCats();
      clearInteractions(dataSource);

      final second = await repository.getAllCats();

      verifyNever(() => dataSource.getAllCats());
      expect((second as Ok<BreedsSnapshot>).value, isA<FreshBreeds>());
      expect(second.value.breeds, hasLength(3));
    });

    test('a successful fetch writes the cache', () async {
      when(
        () => dataSource.getAllCats(),
      ).thenAnswer((_) async => modelsFrom('breeds_3.json'));

      await repository.getAllCats();

      // Read through a second data source rather than the repository's own, so
      // this asserts on what reached the store, not on an in-memory field.
      final cached = LandingCatsLocalDataSource(
        store: store,
        clock: () => now,
      ).readBreeds();

      expect(cached, isNotNull);
      expect(cached!.breeds, hasLength(3));
    });

    test('an expired cache is refreshed from the network', () async {
      when(
        () => dataSource.getAllCats(),
      ).thenAnswer((_) async => modelsFrom('breeds_3.json'));
      await repository.getAllCats();

      final later = repositoryAt(now.add(const Duration(hours: 13)));
      clearInteractions(dataSource);

      final result = await later.getAllCats();

      verify(() => dataSource.getAllCats()).called(1);
      expect((result as Ok<BreedsSnapshot>).value, isA<FreshBreeds>());
    });

    test(
      'an expired cache plus a failed refresh is served as stale, not as an error',
      () async {
        // The offline case, and the reason `BreedsSnapshot` and `CatsStale` exist
        // at all. Before Phase 6 this rendered an error screen while a complete
        // list of cat breeds sat unused on disk.
        when(
          () => dataSource.getAllCats(),
        ).thenAnswer((_) async => modelsFrom('breeds_3.json'));
        await repository.getAllCats();

        final later = repositoryAt(now.add(const Duration(hours: 13)));
        when(() => dataSource.getAllCats()).thenThrow(const NetworkFailure());

        final result = await later.getAllCats();

        expect(result, isA<Ok<BreedsSnapshot>>());
        final snapshot = (result as Ok<BreedsSnapshot>).value;
        expect(snapshot, isA<StaleBreeds>());
        expect(snapshot.breeds, hasLength(3));
        // The failure travels WITH the data, so the UI can say why it is stale.
        expect((snapshot as StaleBreeds).failure, const NetworkFailure());
      },
    );

    test('an unreadable cache behaves as no cache at all', () async {
      // The deploy hazard: a payload written by an older `CatBreedModel`. It must
      // degrade to a plain network fetch, never to a crash.
      await store.write(LandingCatsLocalDataSource.breedsKey, 'garbage');
      when(
        () => dataSource.getAllCats(),
      ).thenAnswer((_) async => modelsFrom('breeds_3.json'));

      final result = await repository.getAllCats();

      verify(() => dataSource.getAllCats()).called(1);
      expect((result as Ok<BreedsSnapshot>).value, isA<FreshBreeds>());
    });
  });

  group('LandingCatsRepositoryImpl.getBreedById', () {
    setUp(() {
      when(
        () => dataSource.getAllCats(),
      ).thenAnswer((_) async => modelsFrom('breeds_3.json'));
    });

    test('finds the breed by its id', () async {
      final result = await repository.getBreedById('abys');

      expect(result, isA<Ok<CatBreedEntity>>());
      expect((result as Ok<CatBreedEntity>).value.name, 'Abyssinian');
    });

    test(
      'an id that matches nothing is a NotFoundFailure carrying it',
      () async {
        final result = await repository.getBreedById('no-such-breed');

        expect(result, isA<Err<CatBreedEntity>>());
        expect(
          (result as Err<CatBreedEntity>).failure,
          const NotFoundFailure(id: 'no-such-breed'),
        );
      },
    );

    test('costs no request when the cache is fresh', () async {
      // What makes routing by id affordable: the detail screen resolves against
      // the list the landing screen already fetched.
      await repository.getAllCats();
      clearInteractions(dataSource);

      final result = await repository.getBreedById('abys');

      verifyNever(() => dataSource.getAllCats());
      expect(result, isA<Ok<CatBreedEntity>>());
    });

    test('resolves from a stale cache rather than refusing', () async {
      await repository.getAllCats();

      final later = repositoryAt(now.add(const Duration(hours: 13)));
      when(() => dataSource.getAllCats()).thenThrow(const NetworkFailure());

      final result = await later.getBreedById('abys');

      // Breed records do not change. Refusing to show one because the refresh
      // failed would repeat the mistake the error screen used to make.
      expect(result, isA<Ok<CatBreedEntity>>());
      expect((result as Ok<CatBreedEntity>).value.name, 'Abyssinian');
    });

    test('forwards the failure when there is nothing to search', () async {
      when(() => dataSource.getAllCats()).thenThrow(const TimeoutFailure());

      final result = await repository.getBreedById('abys');

      // Not a NotFoundFailure: we never got to look. Saying "that breed does not
      // exist" because the network timed out would be a lie.
      expect((result as Err<CatBreedEntity>).failure, const TimeoutFailure());
    });
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
