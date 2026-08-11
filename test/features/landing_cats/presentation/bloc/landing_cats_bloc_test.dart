import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockGetAllCatsUseCase useCase;

  setUp(() => useCase = MockGetAllCatsUseCase());

  // States are asserted CONCRETELY, not with matchers, which the sealed hierarchy
  // makes even more readable than Phase 2's `copyWith` chains.
  //
  // Note: `breeds` are `CatBreedModel`, never bare `CatBreedEntity` — Equatable
  // compares `runtimeType`.
  final breeds = breedsFrom('breeds_3.json', urlImage: 'https://x/y.jpg');

  void stubSuccess() => when(
    () => useCase.getAllCatsCall(),
  ).thenAnswer((_) async => Ok<List<CatBreedEntity>>(breeds));

  void stubFailure([CatsFailure failure = const NetworkFailure()]) => when(
    () => useCase.getAllCatsCall(),
  ).thenAnswer((_) async => Err<List<CatBreedEntity>>(failure));

  group('LandingCatsBloc fetching', () {
    test('starts on CatsInitial with an empty history', () {
      final bloc = LandingCatsBloc(getAllCatsUseCase: useCase);
      addTearDown(bloc.close);

      expect(bloc.state, const CatsInitial(searchHistory: []));
    });

    blocTest<LandingCatsBloc, LandingCatsState>(
      'AllCatsEvent emits [CatsLoading, CatsLoaded]',
      setUp: stubSuccess,
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
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
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
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
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
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
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
      act: (bloc) => bloc.add(const AllCatsEvent()),
      verify: (bloc) => expect(bloc.state, isA<CatsError>()),
    );
  });

  group('LandingCatsBloc search history', () {
    blocTest<LandingCatsBloc, LandingCatsState>(
      'adds a name to the history, keeping the current variant',
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
      act: (bloc) =>
          bloc.add(const AddNameAlreadySearchedEvent(name: 'siamese')),
      expect: () => <LandingCatsState>[
        const CatsInitial(searchHistory: ['siamese']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'the same name twice emits only once',
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
      act: (bloc) => bloc
        ..add(const AddNameAlreadySearchedEvent(name: 'siamese'))
        ..add(const AddNameAlreadySearchedEvent(name: 'siamese')),
      expect: () => <LandingCatsState>[
        const CatsInitial(searchHistory: ['siamese']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'trims whitespace from the name',
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
      act: (bloc) =>
          bloc.add(const AddNameAlreadySearchedEvent(name: '  siamese  ')),
      expect: () => <LandingCatsState>[
        const CatsInitial(searchHistory: ['siamese']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'an empty or whitespace-only name emits nothing',
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
      act: (bloc) => bloc
        ..add(const AddNameAlreadySearchedEvent(name: ''))
        ..add(const AddNameAlreadySearchedEvent(name: '   ')),
      expect: () => <LandingCatsState>[],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'accumulates distinct names in order',
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
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
      // Risk #1 of Phase 3. `copyWith` used to carry the history across
      // transitions for free; every `emit` now builds a fresh variant and has to
      // pass it along. Dropping it in ANY branch silently wipes the feature, so
      // both emits of the fetch are asserted here.
      setUp: stubSuccess,
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
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
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
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
      // The most likely silent failure in this whole diff: if `CatsLoaded.props`
      // listed only `[breeds]`, the third state below would compare EQUAL to the
      // second, `emit` would drop it, and the search history would die in the one
      // state where the search screen is reachable at all.
      setUp: stubSuccess,
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
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

    test('emits a NEW list and leaves the previous state list untouched', () async {
      // The bug this test pins: the search delegate did
      // `filterNamesSearched.add(query)` on the SAME list instance living in the
      // state, then dispatched that instance back. With value equality on the
      // state that would also make `emit` silently drop the update, killing the
      // feature without a single error.
      final bloc = LandingCatsBloc(getAllCatsUseCase: useCase);
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
      final bloc = LandingCatsBloc(getAllCatsUseCase: useCase);
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
