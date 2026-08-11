import 'package:bloc_test/bloc_test.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/config/helpers/errors/invalid_data.dart';
import 'package:tecnical_test_pragma/core/config/helpers/form_submission_status.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockGetAllCatsUseCase useCase;

  setUp(() => useCase = MockGetAllCatsUseCase());

  // States are asserted CONCRETELY, not with matchers. This works because
  // `LandingCatsState` is Equatable (and its `Iterable` props compare deeply) and
  // because `SubmissionFailed.props` uses `exception.toString()`.
  //
  // Note: `breeds` are `CatBreedModel`, never bare `CatBreedEntity` — Equatable
  // compares `runtimeType`.
  final breeds = breedsFrom('breeds_3.json', urlImage: 'https://x/y.jpg');

  void stubSuccess() => when(
    () => useCase.getAllCatsCall(),
  ).thenAnswer((_) async => Right<InvalidData, List<CatBreedEntity>>(breeds));

  void stubFailure([String message = 'boom']) =>
      when(() => useCase.getAllCatsCall()).thenAnswer(
        (_) async => Left<InvalidData, List<CatBreedEntity>>(
          InvalidData(message: message, statusCode: 500),
        ),
      );

  group('LandingCatsBloc', () {
    test('the initial state has empty lists, not null ones', () {
      final bloc = LandingCatsBloc(getAllCatsUseCase: useCase);
      addTearDown(bloc.close);

      expect(bloc.state, const LandingCatsState());
      expect(bloc.state.listAllCats, isEmpty);
      expect(bloc.state.namesAlreadySearched, isEmpty);
      expect(bloc.state.formSubmissionStatusService, const InitialFormStatus());
    });

    blocTest<LandingCatsBloc, LandingCatsState>(
      'AllCatsEvent emits [FormSubmitting, SubmissionSuccess + list]',
      setUp: stubSuccess,
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
      act: (bloc) => bloc.add(const AllCatsEvent()),
      expect: () => <LandingCatsState>[
        const LandingCatsState().copyWith(
          formSubmissionStatusService: const FormSubmitting(),
        ),
        const LandingCatsState().copyWith(
          formSubmissionStatusService: const SubmissionSuccess(),
          listAllCats: breeds,
        ),
      ],
      verify: (_) => verify(() => useCase.getAllCatsCall()).called(1),
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'AllCatsEvent emits [FormSubmitting, SubmissionFailed] on Left',
      setUp: () => stubFailure('service is down'),
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
      act: (bloc) => bloc.add(const AllCatsEvent()),
      expect: () => <LandingCatsState>[
        const LandingCatsState().copyWith(
          formSubmissionStatusService: const FormSubmitting(),
        ),
        const LandingCatsState().copyWith(
          formSubmissionStatusService: SubmissionFailed(
            exception: Exception('service is down'),
          ),
        ),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'on failure the list stays empty (no partial data)',
      setUp: stubFailure,
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
      act: (bloc) => bloc.add(const AllCatsEvent()),
      verify: (bloc) => expect(bloc.state.listAllCats, isEmpty),
    );
  });

  group('LandingCatsBloc search history', () {
    blocTest<LandingCatsBloc, LandingCatsState>(
      'adds a name to the history',
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
      act: (bloc) =>
          bloc.add(const AddNameAlreadySearchedEvent(name: 'siamese')),
      expect: () => <LandingCatsState>[
        const LandingCatsState().copyWith(namesAlreadySearched: ['siamese']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'the same name twice emits only once',
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
      act: (bloc) => bloc
        ..add(const AddNameAlreadySearchedEvent(name: 'siamese'))
        ..add(const AddNameAlreadySearchedEvent(name: 'siamese')),
      expect: () => <LandingCatsState>[
        const LandingCatsState().copyWith(namesAlreadySearched: ['siamese']),
      ],
    );

    blocTest<LandingCatsBloc, LandingCatsState>(
      'trims whitespace from the name',
      build: () => LandingCatsBloc(getAllCatsUseCase: useCase),
      act: (bloc) =>
          bloc.add(const AddNameAlreadySearchedEvent(name: '  siamese  ')),
      expect: () => <LandingCatsState>[
        const LandingCatsState().copyWith(namesAlreadySearched: ['siamese']),
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
        const LandingCatsState().copyWith(namesAlreadySearched: ['siamese']),
        const LandingCatsState().copyWith(
          namesAlreadySearched: ['siamese', 'aegean'],
        ),
      ],
    );

    test(
      'emits a NEW list and leaves the previous state list untouched',
      () async {
        // The bug this test pins: the search delegate did
        // `filterNamesSearched.add(query)` on the SAME list instance living in
        // `state.namesAlreadySearched`, then dispatched that instance back. With
        // Equatable on the state that would also make `emit` silently drop the
        // state, killing the feature without a single error.
        final bloc = LandingCatsBloc(getAllCatsUseCase: useCase);
        addTearDown(bloc.close);

        bloc.add(const AddNameAlreadySearchedEvent(name: 'siamese'));
        await bloc.stream.first;
        final firstHistory = bloc.state.namesAlreadySearched;

        bloc.add(const AddNameAlreadySearchedEvent(name: 'aegean'));
        await bloc.stream.first;

        expect(firstHistory, ['siamese'], reason: 'must not have been mutated');
        expect(bloc.state.namesAlreadySearched, ['siamese', 'aegean']);
        expect(
          bloc.state.namesAlreadySearched,
          isNot(same(firstHistory)),
          reason: 'must be a different instance',
        );
      },
    );

    test('the history list is unmodifiable', () async {
      final bloc = LandingCatsBloc(getAllCatsUseCase: useCase);
      addTearDown(bloc.close);

      bloc.add(const AddNameAlreadySearchedEvent(name: 'siamese'));
      await bloc.stream.first;

      // Any future attempt to mutate the state from a widget fails on the exact
      // offending line instead of silently.
      expect(
        () => bloc.state.namesAlreadySearched.add('other'),
        throwsUnsupportedError,
      );
    });
  });
}
