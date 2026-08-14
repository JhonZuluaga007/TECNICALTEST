import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tecnical_test_pragma/core/injector/injector.dart';
import 'package:tecnical_test_pragma/core/storage/key_value_store.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_data_source.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_local_data_source.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/repository/landing_cats_repository_impl.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/repository/landing_cats_repository.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_by_id_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_image_use_case.dart';

import '../helpers/in_memory_key_value_store.dart';

/// A registration mistake is a runtime-only crash that no other kind of test
/// catches. Cheap and high value.
///
/// Phase 2 wrote this file saying these assertions were the contract Phase 5 would
/// have to preserve. They were, with three mechanical changes: `setup()` is awaited,
/// the unregistered-type error is get_it's `StateError` instead of `KiwiError`, and
/// the `kiwi` import is gone. The groups below the first one cover what get_it and
/// injectable made possible and kiwi could not do at all.
///
/// A note on why `injectable` earns its place, which no test here can express:
/// **deleting an annotation stops `build_runner` from producing a usable graph.**
/// With kiwi, a forgotten registration compiled fine and failed on the screen that
/// needed it.
void main() {
  tearDown(Injector.reset);

  group('Injector', () {
    test('resolves the whole graph without throwing', () async {
      await Injector.setup(storage: InMemoryStorage());

      expect(Injector.resolve<http.Client>(), isNotNull);
      expect(Injector.resolve<LandingCatsDataSource>(), isNotNull);
      expect(Injector.resolve<LandingCatsRepository>(), isNotNull);
      expect(Injector.resolve<GetAllCatsUseCase>(), isNotNull);
      expect(Injector.resolve<GetBreedImageUseCase>(), isNotNull);
      // Phase 6 additions.
      expect(Injector.resolve<Storage>(), isNotNull);
      expect(Injector.resolve<KeyValueStore>(), isNotNull);
      expect(Injector.resolve<LandingCatsLocalDataSource>(), isNotNull);
      expect(Injector.resolve<GetBreedByIdUseCase>(), isNotNull);
    });

    test('binds the repository abstraction to its implementation', () async {
      await Injector.setup(storage: InMemoryStorage());

      expect(
        Injector.resolve<LandingCatsRepository>(),
        isA<LandingCatsRepositoryImpl>(),
      );
    });

    test('singletons are shared and use cases are not', () async {
      await Injector.setup(storage: InMemoryStorage());

      // One connection pool for the whole app.
      expect(
        Injector.resolve<http.Client>(),
        same(Injector.resolve<http.Client>()),
      );

      // The repository is a singleton because Phase 4 made it a **correctness**
      // requirement, not a nicety: it holds the resolved image-URL cache and the
      // in-flight request map. As a factory, every resolve would hand out a fresh
      // empty cache and nothing would ever be cached or de-duplicated.
      // `landing_cats_repository_impl_test.dart` pins the behaviour that depends on
      // it, so swapping the annotation breaks both files.
      expect(
        Injector.resolve<LandingCatsRepository>(),
        same(Injector.resolve<LandingCatsRepository>()),
      );
      expect(
        Injector.resolve<LandingCatsDataSource>(),
        same(Injector.resolve<LandingCatsDataSource>()),
      );

      // Use cases stay factories: stateless wrappers over the repository, so
      // sharing them buys nothing.
      expect(
        Injector.resolve<GetAllCatsUseCase>(),
        isNot(same(Injector.resolve<GetAllCatsUseCase>())),
      );
      expect(
        Injector.resolve<GetBreedImageUseCase>(),
        isNot(same(Injector.resolve<GetBreedImageUseCase>())),
      );
    });

    test('setup() is idempotent', () async {
      // `getIt` is a process-wide singleton and registering a type twice throws, so
      // without the `reset()` that `setup()` performs, a second boot in the same
      // isolate crashes — which is exactly what happens once more than one test file
      // touches it. kiwi needed the same guard, via `container.clear()`.
      await Injector.setup(storage: InMemoryStorage());

      await expectLater(Injector.setup(storage: InMemoryStorage()), completes);
      expect(Injector.resolve<GetAllCatsUseCase>(), isNotNull);
    });

    test('reset() leaves the container empty', () async {
      await Injector.setup(storage: InMemoryStorage());
      await Injector.reset();

      expect(
        () => Injector.resolve<GetAllCatsUseCase>(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Injector http client seam', () {
    test('the injected client is what the container hands out', () async {
      final client = _RecordingClient();

      await Injector.setup(storage: InMemoryStorage(), httpClient: client);

      expect(Injector.resolve<http.Client>(), same(client));
    });

    test(
      'the injected client reaches the datasource, not just the container',
      () async {
        // The assertion that actually makes `app_test.dart` possible. Resolving
        // `http.Client` and getting the mock back proves the registration was
        // replaced; it does not prove the *datasource* was built with it, which is
        // what the end-to-end test depends on. Nothing pinned that until now.
        final client = _RecordingClient();

        await Injector.setup(storage: InMemoryStorage(), httpClient: client);
        final dataSource = Injector.resolve<LandingCatsDataSource>();

        // `_client` is private, so this goes through observable behaviour: any
        // request the datasource makes has to land on the injected client.
        await dataSource.getBreedImageUrl('0XYvRd7oD');

        expect(client.requests, hasLength(1));
      },
    );

    test('the datasource keeps its production defaults', () async {
      // The reason `LandingCatsDataSource` is registered in a module instead of
      // being annotated on the class: `timeout` and `retryDelays` are test seams,
      // and injectable would have tried to resolve a `Duration` and a
      // `List<Duration>` from the container. Naming only `client` keeps these.
      await Injector.setup(
        storage: InMemoryStorage(),
        httpClient: _RecordingClient(),
      );

      final dataSource = Injector.resolve<LandingCatsDataSource>();

      expect(dataSource.timeout, const Duration(seconds: 10));
      expect(dataSource.retryDelays, hasLength(2));
    });
  });

  group('Injector disposal', () {
    test('reset() closes the http client', () async {
      // The leak kiwi could not fix: it has no dispose hook, so the app's
      // `http.Client` was never closed — not in production, and not between test
      // files. This test is the concrete thing the migration bought, and it is why
      // `setup` and `reset` are asynchronous at all.
      final client = _RecordingClient();
      await Injector.setup(storage: InMemoryStorage(), httpClient: client);
      expect(client.closed, isFalse);

      await Injector.reset();

      expect(client.closed, isTrue);
    });

    test('a second setup() closes the client from the first', () async {
      // The same guarantee on the path tests actually take: every test file calls
      // `setup()` again rather than resetting explicitly.
      final first = _RecordingClient();
      await Injector.setup(storage: InMemoryStorage(), httpClient: first);

      await Injector.setup(
        storage: InMemoryStorage(),
        httpClient: _RecordingClient(),
      );

      expect(first.closed, isTrue);
    });

    test('the module wires the dispose callback, not just the override', () async {
      // Reading the generated config, because this wiring has no runtime handle:
      // the module's registration builds a **real** `http.Client`, which exposes
      // nothing to assert on, and every other disposal test here goes through
      // `setup(httpClient:)` — a different registration.
      //
      // Verified by mutation: dropping `dispose:` from the module left the whole
      // suite green until this assertion existed, so the app could have gone back to
      // kiwi's leak without a single test noticing.
      final config = File(
        'lib/core/injector/injector.config.dart',
      ).readAsStringSync();

      expect(
        config,
        contains('closeHttpClient'),
        reason:
            'the generated Client registration must carry the dispose callback',
      );
      expect(
        config,
        contains('lazySingleton<_i519.Client>'),
        reason: 'and it must stay lazy — see the laziness group',
      );
    });

    test('closeHttpClient closes the client it is given', () async {
      // The callback itself, tested directly, because it is what the **module's**
      // registration uses too — and that path builds a real `http.Client`, which
      // exposes nothing to assert on. Between this and the generated
      // `dispose: closeHttpClient` in `injector.config.dart`, both registrations are
      // covered.
      //
      // It is public for a mechanical reason worth knowing: the generated config is
      // a separate library, so a private `_closeHttpClient` would not compile.
      final client = _RecordingClient();

      await closeHttpClient(client);

      expect(client.closed, isTrue);
    });
  });

  group('Injector laziness', () {
    test('nothing in the graph touches the client during init()', () async {
      // `setup(httpClient:)` overrides the client AFTER the generated `init()` runs,
      // which is only safe while no consumer has captured the real one.
      //
      // An honest note on scope, because the obvious reading of this test is wrong.
      // Verified by mutation: making the **client itself** `@Singleton` leaves this
      // green, and harmlessly so — `init()` builds a real client, then `unregister`
      // closes it and the override still lands. The case that actually breaks is a
      // `@Singleton` **consumer**: it would be built during `init()` holding the real
      // client, and no override could reach it afterwards. The test that catches that
      // is `the injected client reaches the datasource` above, and mutation confirms
      // it does.
      final client = _RecordingClient();

      await Injector.setup(storage: InMemoryStorage(), httpClient: client);

      expect(
        client.requests,
        isEmpty,
        reason: 'nothing in the graph should have used the client yet',
      );

      // And the override did land: the first resolve gets the injected one.
      expect(Injector.resolve<http.Client>(), same(client));
    });
  });

  group('Injector graph and behaviour together', () {
    test('the repository resolved twice shares its image cache', () async {
      // This is the test that couples the container to the behaviour that depends on
      // it, and it did not exist until the verification pass went looking.
      //
      // Phase 4's cache tests build `LandingCatsRepositoryImpl` directly, so flipping
      // its annotation from `@LazySingleton` to `@Injectable` leaves every one of
      // them green — the caching code is fine, it is just handed a fresh instance per
      // resolve, and nothing noticed. Going through `Injector.resolve` twice is what
      // makes the registration observable: one request for two resolves, or the cache
      // is per-instance and therefore useless.
      final client = _RecordingClient();
      await Injector.setup(storage: InMemoryStorage(), httpClient: client);

      await Injector.resolve<LandingCatsRepository>().getBreedImageUrl('abc');
      await Injector.resolve<LandingCatsRepository>().getBreedImageUrl('abc');

      expect(
        client.requests,
        hasLength(1),
        reason: 'a factory registration would make this 2',
      );
    });
  });

  group('Injector storage', () {
    test('the injected storage is what the container hands out', () async {
      final storage = InMemoryStorage();

      await Injector.setup(storage: storage);

      expect(Injector.resolve<Storage>(), same(storage));
    });

    test('the KeyValueStore reads and writes the same box', () async {
      // The adapter is three forwarding methods, and this is the assertion that
      // they forward to the storage the app was given rather than to some other
      // instance. Without it the cache would write into a store nothing reads.
      final storage = InMemoryStorage();
      await Injector.setup(storage: storage);

      await Injector.resolve<KeyValueStore>().write('k', 'v');

      expect(storage.values['k'], 'v');
      expect(Injector.resolve<KeyValueStore>().read('k'), 'v');
    });

    test('the cache reaches the store, not just the container', () async {
      // The storage equivalent of `the injected client reaches the datasource`.
      // Resolving a `KeyValueStore` and getting the right object back does not
      // prove the **local data source** was built with it, which is what every
      // caching test depends on.
      final storage = InMemoryStorage();
      await Injector.setup(storage: storage);

      await Injector.resolve<LandingCatsLocalDataSource>().writeBreeds(
        const [],
      );

      expect(storage.values[LandingCatsLocalDataSource.breedsKey], isNotNull);
    });

    test('the local data source keeps its production defaults', () async {
      // Why it is registered in a module rather than annotated on the class:
      // `ttl` and `clock` are test seams, and injectable would try to resolve a
      // `Duration` and a `DateTime Function()` from the container.
      await Injector.setup(storage: InMemoryStorage());

      expect(
        Injector.resolve<LandingCatsLocalDataSource>().ttl,
        const Duration(hours: 12),
      );
    });

    test('reset() closes the storage', () async {
      // Hive holds a file handle open, so this is not merely tidy. Same guarantee
      // as `reset() closes the http client`, and the same reason `setup` and
      // `reset` are asynchronous at all.
      final storage = InMemoryStorage();
      await Injector.setup(storage: storage);
      expect(storage.closed, isFalse);

      await Injector.reset();

      expect(storage.closed, isTrue);
    });

    test('closeStorage closes the storage it is given', () async {
      final storage = InMemoryStorage();

      await closeStorage(storage);

      expect(storage.closed, isTrue);
    });

    test('the generated config demands every binding', () async {
      // Read from the source, because there is no runtime handle on a build-time
      // setting — the same technique used above for the client's dispose.
      //
      // Phase 5 sold injectable on "a missing binding is a build failure instead
      // of a runtime error". Phase 6 measured that and it was **not true by
      // default**: `throwOnMissingDependencies` is `false`, so an unregistered
      // type is a printed warning and the generated `gh<T>()` throws later, on the
      // screen that needed it — precisely the kiwi behaviour the migration was
      // meant to leave behind.
      final source = File('lib/core/injector/injector.dart').readAsStringSync();

      expect(
        source,
        contains('throwOnMissingDependencies: true'),
        reason: "without it, Phase 5's central claim is false",
      );
      // And the one deliberate exception is declared rather than tolerated: the
      // store comes from `setup`, outside the generated graph.
      expect(source, contains('ignoreUnregisteredTypes: [KeyValueStore]'));
    });
  });
}

/// An `http.Client` that records what it was asked to do.
///
/// Extends `BaseClient` rather than mocking, so `close()` and `send()` are the real
/// override points. `MockClient` from `package:http/testing.dart` cannot be used
/// here: these tests are about the container's lifecycle, and `MockClient` does not
/// expose whether it was closed.
class _RecordingClient extends http.BaseClient {
  final List<Uri> requests = [];
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request.url);
    return http.StreamedResponse(
      const Stream<List<int>>.empty(),
      200,
      request: request,
    );
  }

  @override
  void close() {
    closed = true;
    super.close();
  }
}
