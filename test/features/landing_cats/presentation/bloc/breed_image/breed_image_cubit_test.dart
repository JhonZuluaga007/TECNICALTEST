import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/breed_image/breed_image_cubit.dart';

import '../../../../../helpers/mocks.dart';

void main() {
  late MockGetBreedImageUseCase useCase;

  setUp(() => useCase = MockGetBreedImageUseCase());

  void stub(CatsResult<String> result) =>
      when(() => useCase(any())).thenAnswer((_) async => result);

  group('BreedImageCubit', () {
    test('starts loading, so a card never flashes a placeholder first', () {
      final cubit = BreedImageCubit(getBreedImageUseCase: useCase);
      addTearDown(cubit.close);

      expect(cubit.state, const ImageLoading());
    });

    blocTest<BreedImageCubit, BreedImageState>(
      'a resolved url emits ImageReady',
      setUp: () => stub(const Ok('https://cdn2.thecatapi.com/images/x.jpg')),
      build: () => BreedImageCubit(getBreedImageUseCase: useCase),
      act: (cubit) => cubit.resolve('0XYvRd7oD'),
      expect: () => const <BreedImageState>[
        ImageReady(url: 'https://cdn2.thecatapi.com/images/x.jpg'),
      ],
      verify: (_) => verify(() => useCase('0XYvRd7oD')).called(1),
    );

    blocTest<BreedImageCubit, BreedImageState>(
      'an empty id emits ImageUnavailable without asking anyone',
      // 2 of the 67 breeds have no `reference_image_id`. Short-circuiting here as
      // well as in the datasource means a card with no image costs nothing at all —
      // no use case call, no future, no request.
      build: () => BreedImageCubit(getBreedImageUseCase: useCase),
      act: (cubit) => cubit.resolve(''),
      expect: () => const <BreedImageState>[ImageUnavailable()],
      verify: (_) => verifyNever(() => useCase(any())),
    );

    blocTest<BreedImageCubit, BreedImageState>(
      'an empty url emits ImageUnavailable, not a broken Image.network',
      // The datasource returns `''` rather than failing for a 404, a missing `url`
      // key or a malformed body. Without this branch that `''` would reach
      // `Image.network('')`, which throws and lands in an `errorBuilder` — the
      // placeholder either way, but by accident instead of by design.
      setUp: () => stub(const Ok('')),
      build: () => BreedImageCubit(getBreedImageUseCase: useCase),
      act: (cubit) => cubit.resolve('0XYvRd7oD'),
      expect: () => const <BreedImageState>[ImageUnavailable()],
    );

    blocTest<BreedImageCubit, BreedImageState>(
      'a failure emits ImageUnavailable',
      // One broken image must not be able to take down the screen. Before Phase 4
      // image resolution happened inside `getAllCats`, so this failure mode was
      // the datasource's to swallow; now it is a state.
      setUp: () => stub(const Err(NetworkFailure())),
      build: () => BreedImageCubit(getBreedImageUseCase: useCase),
      act: (cubit) => cubit.resolve('0XYvRd7oD'),
      expect: () => const <BreedImageState>[ImageUnavailable()],
    );

    test('does not emit after being closed mid-flight', () async {
      // Not defensive noise: a card scrolled out of view is disposed while its
      // request is still in flight, and `emit` on a closed cubit throws. The work
      // is not wasted either — the repository caches the url, so scrolling back
      // finds it resolved.
      final completer = Completer<CatsResult<String>>();
      when(() => useCase(any())).thenAnswer((_) => completer.future);

      final cubit = BreedImageCubit(getBreedImageUseCase: useCase);
      final pending = cubit.resolve('0XYvRd7oD');

      await cubit.close();
      completer.complete(const Ok('https://x/y.jpg'));

      await expectLater(pending, completes);
    });
  });
}
