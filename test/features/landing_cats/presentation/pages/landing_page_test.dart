import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/common_widgets/card/card_cat_widget.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/pages/detail_cat_page.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/pages/landing_page.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/landing_status_views.dart';

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
    final breeds = breedsFrom('breeds_3.json').take(take).toList();
    when(
      () => useCase.getAllCatsCall(),
    ).thenAnswer((_) async => Ok<List<CatBreedEntity>>(breeds));
    return breeds;
  }

  void stubFailure([CatsFailure failure = const NetworkFailure()]) => when(
    () => useCase.getAllCatsCall(),
  ).thenAnswer((_) async => Err<List<CatBreedEntity>>(failure));

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

    testWidgets('shows the loading view while the request is in flight', (
      tester,
    ) async {
      final completer = Completer<CatsResult<List<CatBreedEntity>>>();
      when(() => useCase.getAllCatsCall()).thenAnswer((_) => completer.future);

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pump();

      expect(find.byType(CatsLoadingView), findsOneWidget);
      expect(find.byType(CardCatWidget), findsNothing);
      expect(find.byType(CatsErrorView), findsNothing);

      // Complete the completer so no pending work is left behind.
      completer.complete(const Ok<List<CatBreedEntity>>([]));
      await tester.pumpAndSettle();
    });

    testWidgets('an empty result shows the empty view, not a blank screen', (
      tester,
    ) async {
      // Phase 3 gave this case its own branch. It used to render an empty
      // `ListView`, which looked identical to a broken app. The list pattern
      // `CatsLoaded(breeds: [])` is what distinguishes it.
      when(
        () => useCase.getAllCatsCall(),
      ).thenAnswer((_) async => const Ok<List<CatBreedEntity>>([]));

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CatsEmptyView), findsOneWidget);
      expect(find.byType(CardCatWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed request shows the error view, not an endless spinner', (
      tester,
    ) async {
      // THE test of this phase. It replaces Phase 2's characterization test
      // ('on failure it keeps showing the spinner'), which pinned the old
      // behavior precisely so this diff would be visible: the UI did
      // `status is SubmissionSuccess ? list : spinner`, an `is` check with an
      // implicit `else`, and an API error left the user staring at an animation
      // forever with no way out.
      stubFailure(const ServerFailure(statusCode: 500));

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CatsErrorView), findsOneWidget);
      expect(find.byType(CatsLoadingView), findsNothing);
      expect(find.byType(CardCatWidget), findsNothing);
    });

    testWidgets('the error view shows the message for that specific failure', (
      tester,
    ) async {
      stubFailure(const ServerFailure(statusCode: 401));

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pumpAndSettle();

      // The typed failure travels all the way from the data layer to the copy.
      expect(find.textContaining('authenticate'), findsOneWidget);
    });

    testWidgets('tapping Retry re-dispatches AllCatsEvent', (tester) async {
      stubFailure();

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Twice: once from `initState`, once from the retry.
      verify(() => useCase.getAllCatsCall()).called(2);
    });

    testWidgets('a successful retry replaces the error view with the list', (
      tester,
    ) async {
      ignoreOverflowErrors();
      stubFailure();

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CatsErrorView), findsOneWidget);

      stubSuccess();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(CatsErrorView), findsNothing);
      expect(find.byType(CardCatWidget), findsWidgets);
    });

    testWidgets('the search icon is reachable while the error view is shown', (
      tester,
    ) async {
      // The app bar reads the breed list off a variant that only exists when
      // loaded, so it has to cope with not having one. Before Phase 3 the field
      // was always present, and this is the case that could have regressed into a
      // crash.
      stubFailure();

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
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
        breedsFrom('breeds_3.json').first,
      );
    });
  });
}
