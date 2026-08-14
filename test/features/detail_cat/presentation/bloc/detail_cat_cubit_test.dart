import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/bloc/detail_cat_cubit.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockGetBreedByIdUseCase useCase;

  final breed = catBreedEntity(id: 'abys', name: 'Abyssinian');

  setUp(() => useCase = MockGetBreedByIdUseCase());

  DetailCatCubit buildCubit() => DetailCatCubit(getBreedByIdUseCase: useCase);

  group('DetailCatCubit', () {
    test('starts on DetailLoading', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state, const DetailLoading());
    });

    blocTest<DetailCatCubit, DetailCatState>(
      'emits DetailReady with the breed it found',
      setUp: () =>
          when(() => useCase('abys')).thenAnswer((_) async => Ok(breed)),
      build: buildCubit,
      act: (cubit) => cubit.load('abys'),
      expect: () => [DetailReady(breed: breed)],
    );

    blocTest<DetailCatCubit, DetailCatState>(
      'emits DetailFailed carrying the typed failure',
      // Typed, not flattened: the screen shows different copy for "no such breed"
      // than for "no connection", and this is where that distinction survives.
      setUp: () => when(() => useCase('nope')).thenAnswer(
        (_) async => const Err<CatBreedEntity>(NotFoundFailure(id: 'nope')),
      ),
      build: buildCubit,
      act: (cubit) => cubit.load('nope'),
      expect: () => [const DetailFailed(failure: NotFoundFailure(id: 'nope'))],
    );

    blocTest<DetailCatCubit, DetailCatState>(
      'a network failure is not reported as a missing breed',
      setUp: () => when(
        () => useCase('abys'),
      ).thenAnswer((_) async => const Err<CatBreedEntity>(NetworkFailure())),
      build: buildCubit,
      act: (cubit) => cubit.load('abys'),
      expect: () => [const DetailFailed(failure: NetworkFailure())],
    );

    blocTest<DetailCatCubit, DetailCatState>(
      'loading twice re-runs the lookup, which is what Retry needs',
      setUp: () =>
          when(() => useCase('abys')).thenAnswer((_) async => Ok(breed)),
      build: buildCubit,
      act: (cubit) async {
        await cubit.load('abys');
        await cubit.load('abys');
      },
      verify: (_) => verify(() => useCase('abys')).called(2),
    );

    test('closing while the lookup is in flight does not throw', () async {
      // Cubits are disposed when the user presses back, and emitting on a closed
      // one throws. Same guard, and same reason, as `BreedImageCubit`.
      when(() => useCase('abys')).thenAnswer((_) async => Ok(breed));

      final cubit = buildCubit();
      final pending = cubit.load('abys');
      await cubit.close();

      await expectLater(pending, completes);
    });
  });
}
