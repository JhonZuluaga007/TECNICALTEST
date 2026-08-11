import 'dart:async';

import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/common_widgets/card/card_cat_widget.dart';
import 'package:tecnical_test_pragma/core/config/helpers/errors/invalid_data.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/pages/detail_cat_page.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/pages/landing_page.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/ignore_overflow_errors.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late MockGetAllCatsUseCase useCase;

  // A real bloc with a mocked use case, on purpose: a `MockBloc` here would let
  // a broken bloc pass. What is under test is that the page consumes the real
  // state machine correctly.
  setUp(() => useCase = MockGetAllCatsUseCase());

  List<CatBreedEntity> stubSuccess({int take = 3}) {
    final breeds = breedsFrom(
      'breeds_3.json',
      urlImage: 'https://x/y.jpg',
    ).take(take).toList();
    when(
      () => useCase.getAllCatsCall(),
    ).thenAnswer((_) async => Right<InvalidData, List<CatBreedEntity>>(breeds));
    return breeds;
  }

  group('LandingPage', () {
    testWidgets('dispatches AllCatsEvent on mount', (tester) async {
      // `CardCatWidget` overflows with the test font (every glyph is a full
      // em), not in the real app. See the helper.
      ignoreOverflowErrors();
      stubSuccess();

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pumpAndSettle();

      verify(() => useCase.getAllCatsCall()).called(1);
    });

    testWidgets('renders one card per breed', (tester) async {
      // `CardCatWidget` overflows with the test font (every glyph is a full
      // em), not in the real app. See the helper.
      ignoreOverflowErrors();
      final breeds = stubSuccess();

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pumpAndSettle();

      // The `itemCount` is asserted rather than the number of rendered cards:
      // `ListView` is lazy and only 2 cards fit in the test surface (800x600).
      // Counting built widgets would tie the test to the viewport size, which is
      // exactly what Phase 8 is going to change.
      //
      // Filtered by orientation: every `CardCatWidget` nests a horizontal
      // `ListView` (the 5 circles in `BreedCharacteristicWidget`), so
      // `find.byType(ListView)` matches several. The vertical one is the
      // landing's.
      final verticalLists = tester
          .widgetList<ListView>(find.byType(ListView))
          .where((list) => list.scrollDirection == Axis.vertical);
      expect(verticalLists.single.semanticChildCount, 3);
      expect(find.byType(CardCatWidget), findsWidgets);
      expect(find.text(breeds.first.name), findsOneWidget);
    });

    testWidgets('shows the spinner while loading', (tester) async {
      final completer = Completer<Either<InvalidData, List<CatBreedEntity>>>();
      when(() => useCase.getAllCatsCall()).thenAnswer((_) => completer.future);

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CardCatWidget), findsNothing);

      // Complete the completer so no pending work is left behind.
      completer.complete(const Right<InvalidData, List<CatBreedEntity>>([]));
      await tester.pumpAndSettle();
    });

    testWidgets('an empty list renders no cards and does not throw', (
      tester,
    ) async {
      // Regression test for the four `state.listAllCats![index]` force-unwraps:
      // with non-nullable lists and a correct `itemCount`, the empty case is
      // harmless.
      when(() => useCase.getAllCatsCall()).thenAnswer(
        (_) async => const Right<InvalidData, List<CatBreedEntity>>([]),
      );

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CardCatWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on failure it keeps showing the spinner', (tester) async {
      // CHARACTERIZATION, not approval: there is no error branch anywhere today,
      // so an API failure leaves an infinite spinner. Phase 3 introduces the
      // exhaustive `switch` over sealed states that FORCES writing the error
      // view, and this test has to change there. It is pinned now so that diff is
      // visible.
      when(() => useCase.getAllCatsCall()).thenAnswer(
        (_) async => const Left<InvalidData, List<CatBreedEntity>>(
          InvalidData(message: 'boom', statusCode: 500),
        ),
      );

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CardCatWidget), findsNothing);
    });

    testWidgets('unmounting it disposes the ScrollController', (tester) async {
      // `CardCatWidget` overflows with the test font (every glyph is a full
      // em), not in the real app. See the helper.
      ignoreOverflowErrors();
      stubSuccess();

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pumpAndSettle();

      final controller = tester
          .widget<Scrollbar>(find.byType(Scrollbar))
          .controller!;

      await tester.pumpWidget(const SizedBox());

      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    testWidgets('tapping "More..." navigates to the detail with the breed', (
      tester,
    ) async {
      // `CardCatWidget` overflows with the test font (every glyph is a full
      // em), not in the real app. See the helper.
      ignoreOverflowErrors();
      stubSuccess();

      await tester.pumpRouter(
        bloc: tester.buildBloc(useCase),
        initialLocation: '/home',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('More...').first);
      await tester.pumpAndSettle();

      expect(find.byType(DetailCatPage), findsOneWidget);
      expect(
        tester.widget<DetailCatPage>(find.byType(DetailCatPage)).catBreedEntity,
        breedsFrom('breeds_3.json', urlImage: 'https://x/y.jpg').first,
      );
    });
  });
}
