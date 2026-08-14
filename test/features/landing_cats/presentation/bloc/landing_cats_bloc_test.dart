import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/breeds_snapshot.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/in_memory_key_value_store.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockGetAllCatsUseCase useCase;
  late InMemoryStorage storage;

  setUp(() {
    useCase = MockGetAllCatsUseCase();
    // A fresh store per test. Phase 6 note: this is exactly what the global
    // `HydratedBloc.storage` would NOT give — `flutter_test_config.dart` runs once
    // per file, and the storage key is the runtime type, so a single shared store
    // would let one case's history leak into the next and make the
    // `searchHistory: []` expectations below depend on execution order.
    storage = InMemoryStorage();
  });

  /// The bloc under test. Takes an explicit [sharedStorage] only where a test is
  /// about persistence, i.e. where two blocs have to see one store.
  LandingCatsBloc buildBloc({Storage? sharedStorage}) => LandingCatsBloc(
    getAllCatsUseCase: useCase,
    storage: sharedStorage ?? storage,
  );

  // States are asserted CONCRETELY, not with matchers, which the sealed hierarchy
  // makes even more readable than Phase 2's `copyWith` chains.
  //
  // These are `CatBreedEntity`. Until Phase 4 the note here had to warn that they
  // were really `CatBreedModel` — the repository upcast without converting, so a
  // builder returning the bare entity would never match an equality assertion.
  // The repository maps explicitly now, so what the bloc sees is what the domain
  // declares.
  final breeds = breedsFrom('breeds_3.json');

  void stubSuccess() => when(
    () => useCase.getAllCatsCall(),
  ).thenAnswer((_) async => Ok(FreshBreeds(breeds: breeds)));

  void stubStale([CatsFailure failure = const NetworkFailure()]) => when(
    () => useCase.getAllCatsCall(),
  ).thenAnswer((_) async => Ok(StaleBreeds(breeds: breeds, failure: failure)));

  void stubFailure([CatsFailure failure = const NetworkFailure()]) => when(
    () => useCase.getAllCatsCall(),
  ).thenAnswer((_) async => Err<BreedsSnapshot>(failure));

  group('LandingCatsBloc fetching', () {
    test('starts on CatsInitial with an empty history', () {
      // With an empty store there is nothing to restore, so hydration falls back
      // to the initial state. The restore path has its own group below.
      final bloc = buildBloc();
      addTearDown(bloc.close);

      expect(bloc.state, const CatsInitial(searchHistory: []));
    });

    blocTest<LandingCatsBloc, LandingCatsState>(
      'AllCatsEvent emits [CatsLoading, CatsLoaded]',
      setUp: stubSuccess,
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AllCatsEvent()),
      expect: () => <LandingCatsState>[
        const CatsLoading(searchHistory: []),
        CatsLoaded(breeds: breeds, searchHistory: const []),
      ],
      verify: (_) => verify(() => useCase.getAllCatsCall()).called(1),
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'AllCatsEvent emits [CatsLoading, CatsError] on Err',
      setUp: () => stubFailure(const ServerFailure(statusCode: 401)),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AllCatsEvent()),
      expect: () => <LandingCatsState>[
        const CatsLoading(searchHistory: []),
        const CatsError(
          failure: ServerFailure(statusCode: 401),
          searchHistory: [],
        ),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'the failure reaches the state TYPED, not flattened into a message',
      // This is what makes a per-cause error message possible. The bloc used to
      // do `SubmissionFailed(exception: Exception(error.message))`, throwing away
      // the type on the way out of the domain.
      setUp: () => stubFailure(
        const UnexpectedResponseFailure(detail: 'Expected a JSON array'),
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AllCatsEvent()),
      verify: (bloc) {
        final state = bloc.state as CatsError;
        expect(state.failure, isA<UnexpectedResponseFailure>());
        expect(
          (state.failure as UnexpectedResponseFailure).detail,
          'Expected a JSON array',
        );
      },
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'a failed fetch leaves no breed list to read at all',
      // Not "the list is empty": with the sealed hierarchy there is no `breeds`
      // field on `CatsError`, so partial data on a failure is unrepresentable
      // rather than merely absent.
      setUp: stubFailure,
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AllCatsEvent()),
      verify: (bloc) => expect(bloc.state, isA<CatsError>()),
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'a stale snapshot emits CatsStale, with the breeds AND the failure',
      // Phase 6's new branch, and the offline behaviour in one assertion: the
      // same failure that used to produce an error screen now produces a list.
      setUp: () => stubStale(const TimeoutFailure()),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AllCatsEvent()),
      expect: () => <LandingCatsState>[
        const CatsLoading(searchHistory: []),
        CatsStale(
          breeds: breeds,
          failure: const TimeoutFailure(),
          searchHistory: const [],
        ),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'a stale snapshot is NOT an error state',
      // Stated separately because it is the regression that matters. Mapping
      // `StaleBreeds` to `CatsError` would leave every other test here green —
      // the failure is right, the loading is right — while deleting the feature.
      setUp: stubStale,
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AllCatsEvent()),
      verify: (bloc) {
        expect(bloc.state, isNot(isA<CatsError>()));
        expect((bloc.state as CatsStale).breeds, hasLength(3));
      },
    );
  });

  group('LandingCatsBloc persistence', () {
    test('the search history survives a new bloc on the same storage', () async {
      // Phase 6 in a single test: this is what "the history survives closing the
      // app" means, with the process restart standing in for the app restart.
      final shared = InMemoryStorage();

      final first = buildBloc(sharedStorage: shared);
      first.add(const AddNameAlreadySearchedEvent(name: 'siamese'));
      await first.stream.first;
      await first.close();

      final restored = buildBloc(sharedStorage: shared);
      addTearDown(restored.close);

      expect(restored.state.searchHistory, ['siamese']);
    });

    test('it restores into CatsInitial, so the breeds are refetched', () async {
      final shared = InMemoryStorage();

      final first = buildBloc(sharedStorage: shared);
      first.add(const AddNameAlreadySearchedEvent(name: 'siamese'));
      await first.stream.first;
      await first.close();

      final restored = buildBloc(sharedStorage: shared);
      addTearDown(restored.close);

      // Not `CatsLoaded`. A restored list would be a second cache with no expiry
      // policy, next to the one in the data layer that has a TTL; the app asks for
      // breeds on every start and the disk cache is what makes that cheap.
      expect(restored.state, isA<CatsInitial>());
    });

    test('the breeds are never written to storage', () async {
      // The cost side of the same decision. `HydratedMixin.onChange` writes on
      // EVERY state change, so persisting the state wholesale would serialise 67
      // breeds each time one search term was added.
      stubSuccess();
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const AllCatsEvent());
      await bloc.stream.firstWhere((state) => state is CatsLoaded);

      final written = storage.values.values.join();
      expect(written, isNot(contains('Abyssinian')));
      expect(written, isNot(contains('breeds')));
    });

    test('an empty history is written rather than skipped', () async {
      // `toJson` returns the history unconditionally rather than `null` for the
      // empty case. `null` tells hydrated_bloc to skip the write
      // (`HydratedMixin.onChange`), so an emptied history would silently come back
      // on the next launch — the previous value would still be sitting in the box.
      final bloc = buildBloc();
      addTearDown(bloc.close);

      expect(
        storage.values['LandingCatsBloc'],
        {'searchHistory': <String>[]},
        reason: 'an empty history must be written, not left to the old value',
      );
    });

    group('a corrupt stored state does not stop the app from starting', () {
      final corrupt = <String, Object?>{
        'a value that is not a list': {'searchHistory': 'siamese'},
        'a missing key': <String, Object?>{},
        'entries that are not strings': {
          'searchHistory': [1, 2, 3],
        },
      };

      corrupt.forEach((description, value) {
        test(description, () {
          final shared = InMemoryStorage();
          // The storage key hydrated_bloc uses is the bloc's runtime type.
          shared.values['LandingCatsBloc'] = value;

          final bloc = buildBloc(sharedStorage: shared);
          addTearDown(bloc.close);

          // Starting at all is the assertion. The alternative — a throw during
          // construction — is an app that cannot be launched after a bad deploy,
          // and the only fix a user has for that is reinstalling.
          expect(bloc.state, isA<CatsInitial>());
          expect(bloc.state.searchHistory, isEmpty);
        });
      });
    });

    test('a partially readable history keeps the entries it can', () async {
      final shared = InMemoryStorage();
      shared.values['LandingCatsBloc'] = {
        'searchHistory': ['siamese', 42, 'aegean'],
      };

      final bloc = buildBloc(sharedStorage: shared);
      addTearDown(bloc.close);

      // `whereType` rather than `cast`: `cast` is a lazy view that would throw on
      // the bad element later, somewhere else. Dropping it fails no worse and much
      // earlier.
      expect(bloc.state.searchHistory, ['siamese', 'aegean']);
    });

    test('the restored history is unmodifiable, like a fresh one', () async {
      final shared = InMemoryStorage();
      shared.values['LandingCatsBloc'] = {
        'searchHistory': ['siamese'],
      };

      final bloc = buildBloc(sharedStorage: shared);
      addTearDown(bloc.close);

      expect(
        () => bloc.state.searchHistory.add('other'),
        throwsUnsupportedError,
      );
    });
  });

  group('LandingCatsBloc search history', () {
    blocTest<LandingCatsBloc, LandingCatsState>(
      'adds a name to the history, keeping the current variant',
      build: () => buildBloc(),
      act: (bloc) =>
          bloc.add(const AddNameAlreadySearchedEvent(name: 'siamese')),
      expect: () => <LandingCatsState>[
        const CatsInitial(searchHistory: ['siamese']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'the same name twice emits only once',
      build: () => buildBloc(),
      act: (bloc) => bloc
        ..add(const AddNameAlreadySearchedEvent(name: 'siamese'))
        ..add(const AddNameAlreadySearchedEvent(name: 'siamese')),
      expect: () => <LandingCatsState>[
        const CatsInitial(searchHistory: ['siamese']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'trims whitespace from the name',
      build: () => buildBloc(),
      act: (bloc) =>
          bloc.add(const AddNameAlreadySearchedEvent(name: '  siamese  ')),
      expect: () => <LandingCatsState>[
        const CatsInitial(searchHistory: ['siamese']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'an empty or whitespace-only name emits nothing',
      build: () => buildBloc(),
      act: (bloc) => bloc
        ..add(const AddNameAlreadySearchedEvent(name: ''))
        ..add(const AddNameAlreadySearchedEvent(name: '   ')),
      expect: () => <LandingCatsState>[],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'accumulates distinct names in order',
      build: () => buildBloc(),
      act: (bloc) => bloc
        ..add(const AddNameAlreadySearchedEvent(name: 'siamese'))
        ..add(const AddNameAlreadySearchedEvent(name: 'aegean')),
      expect: () => <LandingCatsState>[
        const CatsInitial(searchHistory: ['siamese']),
        const CatsInitial(searchHistory: ['siamese', 'aegean']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'the history survives a whole fetch cycle',
      // Risk #1 of Phase 3: the history is orthogonal to the fetch lifecycle, and
      // `_onAllCats` builds a fresh variant on each `emit`, so dropping it in ANY
      // branch silently wipes the feature. Both emits of the fetch are asserted
      // here.
      setUp: stubSuccess,
      build: () => buildBloc(),
      act: (bloc) async {
        bloc.add(const AddNameAlreadySearchedEvent(name: 'siamese'));
        await bloc.stream.first;
        bloc.add(const AllCatsEvent());
      },
      expect: () => <LandingCatsState>[
        const CatsInitial(searchHistory: ['siamese']),
        const CatsLoading(searchHistory: ['siamese']),
        CatsLoaded(breeds: breeds, searchHistory: const ['siamese']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'the history survives a FAILED fetch too',
      setUp: stubFailure,
      build: () => buildBloc(),
      act: (bloc) async {
        bloc.add(const AddNameAlreadySearchedEvent(name: 'siamese'));
        await bloc.stream.first;
        bloc.add(const AllCatsEvent());
      },
      expect: () => <LandingCatsState>[
        const CatsInitial(searchHistory: ['siamese']),
        const CatsLoading(searchHistory: ['siamese']),
        const CatsError(failure: NetworkFailure(), searchHistory: ['siamese']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'adding a name while loaded emits, and keeps the breeds',
      // Two things at once, and both are silent failure modes.
      //
      // If `==` did not account for `searchHistory`, the third state below would
      // compare EQUAL to the second, `emit` would drop it, and the history would
      // die in the one state where the search screen is reachable at all.
      //
      // And it pins that `copyWith` on the sealed base **preserves the concrete
      // variant**: expecting `CatsLoaded` here is what fails if it ever returned
      // some other member of the union.
      setUp: stubSuccess,
      build: () => buildBloc(),
      act: (bloc) async {
        bloc.add(const AllCatsEvent());
        await bloc.stream.firstWhere((state) => state is CatsLoaded);
        bloc.add(const AddNameAlreadySearchedEvent(name: 'siamese'));
      },
      expect: () => <LandingCatsState>[
        const CatsLoading(searchHistory: []),
        CatsLoaded(breeds: breeds, searchHistory: const []),
        CatsLoaded(breeds: breeds, searchHistory: const ['siamese']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'adding a name while in error keeps the variant AND the failure',
      // The harder half of variant preservation. `CatsLoaded` carrying its breeds
      // through a `copyWith` is the obvious case; this is the one where the
      // preserved payload is something else entirely. Phase 3 had an explicit
      // branch reconstructing `CatsError(failure: failure, ...)`; Phase 4 deleted
      // that branch and relies on freezed, so the guarantee needs its own test.
      setUp: stubFailure,
      build: () => buildBloc(),
      act: (bloc) async {
        bloc.add(const AllCatsEvent());
        await bloc.stream.firstWhere((state) => state is CatsError);
        bloc.add(const AddNameAlreadySearchedEvent(name: 'siamese'));
      },
      expect: () => <LandingCatsState>[
        const CatsLoading(searchHistory: []),
        const CatsError(failure: NetworkFailure(), searchHistory: []),
        const CatsError(failure: NetworkFailure(), searchHistory: ['siamese']),
      ],
    );

    test('emits a NEW list and leaves the previous state list untouched', () async {
      // The bug this test pins: the search delegate did
      // `filterNamesSearched.add(query)` on the SAME list instance living in the
      // state, then dispatched that instance back. With value equality on the
      // state that would also make `emit` silently drop the update, killing the
      // feature without a single error.
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const AddNameAlreadySearchedEvent(name: 'siamese'));
      await bloc.stream.first;
      final firstHistory = bloc.state.searchHistory;

      bloc.add(const AddNameAlreadySearchedEvent(name: 'aegean'));
      await bloc.stream.first;

      expect(firstHistory, ['siamese'], reason: 'must not have been mutated');
      expect(bloc.state.searchHistory, ['siamese', 'aegean']);
      expect(
        bloc.state.searchHistory,
        isNot(same(firstHistory)),
        reason: 'must be a different instance',
      );
    });

    test('the history list is unmodifiable', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const AddNameAlreadySearchedEvent(name: 'siamese'));
      await bloc.stream.first;

      // Any future attempt to mutate the state from a widget fails on the exact
      // offending line instead of silently.
      expect(
        () => bloc.state.searchHistory.add('other'),
        throwsUnsupportedError,
      );
    });
  });
}
