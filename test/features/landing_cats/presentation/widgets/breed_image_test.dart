import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_image_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/breed_image.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockGetBreedImageUseCase useCase;

  setUp(() => useCase = MockGetBreedImageUseCase());

  Future<void> pumpImage(
    WidgetTester tester, {
    String referenceImageId = '0XYvRd7oD',
  }) => tester.pumpWidget(
    RepositoryProvider<GetBreedImageUseCase>.value(
      value: useCase,
      child: MaterialApp(
        home: Scaffold(body: BreedImage(referenceImageId: referenceImageId)),
      ),
    ),
  );

  group('BreedImage', () {
    testWidgets('shows a spinner while resolving', (tester) async {
      final completer = Completer<CatsResult<String>>();
      when(() => useCase(any())).thenAnswer((_) => completer.future);

      await pumpImage(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(const Ok(''));
      await tester.pumpAndSettle();
    });

    testWidgets('renders the network image once resolved', (tester) async {
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Ok('https://cdn2.thecatapi.com/x.jpg'));

      await pumpImage(tester);
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(
        find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage),
      );
      expect(
        (image.image as NetworkImage).url,
        'https://cdn2.thecatapi.com/x.jpg',
      );
    });

    testWidgets('falls back to the bundled asset when unavailable', (
      tester,
    ) async {
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await pumpImage(tester);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) => w is Image && w.image is AssetImage),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a breed with no reference image asks for nothing', (
      tester,
    ) async {
      // The lazy-resolution contract at its cheapest: no id, no work. Two of the
      // 67 breeds are permanently in this state.
      await pumpImage(tester, referenceImageId: '');
      await tester.pumpAndSettle();

      verifyNever(() => useCase(any()));
      expect(
        find.byWidgetPredicate((w) => w is Image && w.image is AssetImage),
        findsOneWidget,
      );
    });

    testWidgets('resolves exactly once per mount, not once per rebuild', (
      tester,
    ) async {
      // The failure mode this rules out is the classic `FutureBuilder` bug: a
      // future created in `build` re-fires on every rebuild. `BlocProvider.create`
      // runs once for the life of the widget, and with a list rebuilding on every
      // state change that difference is the whole request budget.
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Ok('https://cdn2.thecatapi.com/x.jpg'));

      await pumpImage(tester);
      await tester.pumpAndSettle();

      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => useCase('0XYvRd7oD')).called(1);
    });
  });

  group('BreedImage when the network image itself fails to load', () {
    /// Phase 9. This group covers the defect the deleted `NetworkImageWidget`
    /// carried: its `errorBuilder` branched on `stackTrace != null` and, when the
    /// stack trace was null, returned `Image.network(imageUrl)` — re-issuing the
    /// request that had just failed, from inside its own error handler, with no
    /// `errorBuilder` on the retry.
    ///
    /// The builder is invoked directly rather than by making a real load fail.
    /// Proving "the failed URL is not requested a second time" through
    /// `debugNetworkImageHttpClientProvider` would need `dart:io` in the test and
    /// a process-global override that fights the binding's own; calling the
    /// builder exercises the same branch deterministically in three lines.
    testWidgets('shows the asset instead of re-requesting the failed URL', (
      tester,
    ) async {
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Ok('https://cdn2.thecatapi.com/x.jpg'));

      await pumpImage(tester);
      await tester.pumpAndSettle();

      final finder = find.byWidgetPredicate(
        (w) => w is Image && w.image is NetworkImage,
      );
      final image = tester.widget<Image>(finder);

      // A null stack trace is the input that used to take the retry branch.
      final onError = image.errorBuilder!(
        tester.element(finder),
        Object(),
        null,
      );

      expect(onError, isA<Image>());
      expect((onError as Image).image, isA<AssetImage>());
      expect(onError.image, isNot(isA<NetworkImage>()));
    });

    testWidgets('honours the caller height in the failure fallback', (
      tester,
    ) async {
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Ok('https://cdn2.thecatapi.com/x.jpg'));

      await tester.pumpWidget(
        RepositoryProvider<GetBreedImageUseCase>.value(
          value: useCase,
          child: const MaterialApp(
            home: Scaffold(
              body: BreedImage(referenceImageId: '0XYvRd7oD', height: 80),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final finder = find.byWidgetPredicate(
        (w) => w is Image && w.image is NetworkImage,
      );
      final onError =
          tester.widget<Image>(finder).errorBuilder!(
                tester.element(finder),
                Object(),
                null,
              )
              as Image;

      // The old code hardcoded `height: 250` in the error branch, so a caller's
      // height was silently dropped exactly when the fallback appeared.
      expect(onError.height, 80);
    });

    testWidgets('defaults the fallback height when the caller gives none', (
      tester,
    ) async {
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await pumpImage(tester);
      await tester.pumpAndSettle();

      final asset = tester.widget<Image>(
        find.byWidgetPredicate((w) => w is Image && w.image is AssetImage),
      );
      expect(asset.height, 250);
    });
  });
}
