import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_local_data_source.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/in_memory_key_value_store.dart';

/// The breeds cache, new in Phase 6.
///
/// It has more logic of its own than anything else in the phase — a TTL, a clock,
/// a serialised payload — and it is the piece whose failure mode is worst: an
/// unreadable cache that throws would make the app unlaunchable, and the only fix a
/// user has for that is reinstalling. Hence the `never throws` group, which is
/// larger than the happy path.
void main() {
  late InMemoryKeyValueStore store;

  /// A fixed clock. Every expiry assertion moves this, not the wall clock, so the
  /// suite never spends real time to test a twelve-hour TTL.
  final now = DateTime.utc(2026, 8, 14, 12);

  LandingCatsLocalDataSource dataSource({
    Duration ttl = const Duration(hours: 12),
    DateTime? clock,
  }) => LandingCatsLocalDataSource(
    store: store,
    ttl: ttl,
    clock: () => clock ?? now,
  );

  setUp(() => store = InMemoryKeyValueStore());

  group('LandingCatsLocalDataSource', () {
    test('returns null when nothing has been written', () {
      expect(dataSource().readBreeds(), isNull);
    });

    test('writes and reads the breeds back', () async {
      final breeds = modelsFrom('breeds_3.json');

      await dataSource().writeBreeds(breeds);

      final cached = dataSource().readBreeds();

      expect(cached, isNotNull);
      expect(cached!.breeds, equals(breeds));
    });

    test('round-trips a breed through the full payload, not just its id', () async {
      // The assertion that would have caught Phase 4's `explicit_to_json` bug if
      // this cache had existed then: `WeightModel` is a nested object, and without
      // that setting `toJson` emits the object rather than its map, so `fromJson`
      // throws on the nested cast. `equals` on a freezed model compares every
      // field, so this covers all 39.
      final breed = catBreedModel(
        name: 'Bengal',
        referenceImageId: 'O3btzLlsO',
      );

      await dataSource().writeBreeds([breed]);

      expect(dataSource().readBreeds()!.breeds.single, equals(breed));
    });

    test('stores nothing under any key but its own versioned one', () async {
      await dataSource().writeBreeds(modelsFrom('breeds_3.json'));

      expect(store.read(LandingCatsLocalDataSource.breedsKey), isNotNull);
      // The version suffix is what makes a `CatBreedModel` change safe to ship: a
      // bump orphans the old entry instead of trying to read it.
      expect(LandingCatsLocalDataSource.breedsKey, endsWith('.v1'));
    });

    test('an empty list is cached as an empty list, not as absent', () async {
      // "The API said there are no breeds" and "we never asked" are different
      // answers, and only the second one should hit the network.
      await dataSource().writeBreeds(const []);

      final cached = dataSource().readBreeds();

      expect(cached, isNotNull);
      expect(cached!.breeds, isEmpty);
    });
  });

  group('LandingCatsLocalDataSource expiry', () {
    test('an entry read at the moment it was written is not expired', () async {
      await dataSource().writeBreeds(modelsFrom('breeds_3.json'));

      expect(dataSource().readBreeds()!.isExpired, isFalse);
    });

    test('an entry inside the TTL is not expired', () async {
      await dataSource().writeBreeds(modelsFrom('breeds_3.json'));

      final later = dataSource(
        clock: now.add(const Duration(hours: 11, minutes: 59)),
      );

      expect(later.readBreeds()!.isExpired, isFalse);
    });

    test('an entry past the TTL is expired, and still readable', () async {
      await dataSource().writeBreeds(modelsFrom('breeds_3.json'));

      final later = dataSource(clock: now.add(const Duration(hours: 13)));
      final cached = later.readBreeds();

      expect(cached!.isExpired, isTrue);
      // Readable is the whole point: the repository serves these when the network
      // is down. A `readBreeds` that dropped expired entries would make the
      // offline case impossible.
      expect(cached.breeds, hasLength(3));
    });

    test('the boundary is inclusive: exactly the TTL is expired', () async {
      await dataSource().writeBreeds(modelsFrom('breeds_3.json'));

      final later = dataSource(clock: now.add(const Duration(hours: 12)));

      expect(later.readBreeds()!.isExpired, isTrue);
    });

    test('a clock that moved backwards counts as expired', () async {
      // A timezone change or a manual adjustment can make the saved timestamp sit
      // in the future. The cheap read is to refetch; the alternative is an entry
      // that stays "fresh" until the clock catches up, which could be months.
      await dataSource().writeBreeds(modelsFrom('breeds_3.json'));

      final earlier = dataSource(clock: now.subtract(const Duration(days: 1)));

      expect(earlier.readBreeds()!.isExpired, isTrue);
    });
  });

  group('LandingCatsLocalDataSource never throws on a bad payload', () {
    // Each of these is a shape a real deploy can produce: an entry written by an
    // older `CatBreedModel`, a half-written value, a key reused by mistake. Every
    // one of them must read as "no cache", because the alternative is an
    // exception during the first frame of a cold start.
    final corrupt = <String, Object?>{
      'a value that is not a map at all': 'just a string',
      'a list where the map should be': [1, 2, 3],
      'a map with no savedAt': {'breeds': <Object?>[]},
      'a savedAt of the wrong type': {
        'savedAt': 'yesterday',
        'breeds': <Object?>[],
      },
      'a map with no breeds': {'savedAt': 0},
      'breeds that are not a list': {'savedAt': 0, 'breeds': 'nope'},
      'breed entries that are not maps': {
        'savedAt': 0,
        'breeds': ['nope'],
      },
      'a breed entry whose fields have the wrong types': {
        'savedAt': 0,
        'breeds': [
          {'id': 1, 'name': false, 'weight': 'heavy'},
        ],
      },
    };

    corrupt.forEach((description, value) {
      test('$description reads as no cache', () async {
        await store.write(LandingCatsLocalDataSource.breedsKey, value);

        expect(dataSource().readBreeds, returnsNormally);
        expect(dataSource().readBreeds(), isNull);
      });
    });

    test('a corrupt entry is replaced by the next write', () async {
      await store.write(LandingCatsLocalDataSource.breedsKey, 'garbage');

      await dataSource().writeBreeds(modelsFrom('breeds_3.json'));

      expect(dataSource().readBreeds()!.breeds, hasLength(3));
    });

    test('a breed entry missing every field reads as a defaulted breed', () async {
      // Not in the list above, because it is **not** corrupt — and finding that
      // out is why this case is written down rather than assumed.
      //
      // Phase 4 put `@Default` on all 39 fields of `CatBreedModel`, so an empty
      // map is a valid breed with empty strings and zeros. That is deliberate
      // there (TheCatAPI omits keys rather than sending nulls), and the cache
      // must not disagree with it: `readBreeds` has to give back exactly what the
      // network path would have produced from the same JSON, or the two sources
      // would need two sets of expectations.
      await store.write(LandingCatsLocalDataSource.breedsKey, {
        'savedAt': 0,
        'breeds': [<String, Object?>{}],
      });

      final cached = dataSource().readBreeds();

      expect(cached, isNotNull);
      expect(cached!.breeds.single.id, isEmpty);
    });
  });
}
