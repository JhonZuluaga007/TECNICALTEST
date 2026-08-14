import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/common_widgets/card/card_cat_widget.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/pages/detail_cat_page.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/breeds_snapshot.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
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
    ).thenAnswer((_) async => Ok(FreshBreeds(breeds: breeds)));
    return breeds;
  }

  List<CatBreedEntity> stubStale([
    CatsFailure failure = const NetworkFailure(),
  ]) {
    final breeds = breedsFrom('breeds_3.json');
    when(() => useCase.getAllCatsCall()).thenAnswer(
      (_) async => Ok(StaleBreeds(breeds: breeds, failure: failure)),
    );
    return breeds;
  }

  void stubFailure([CatsFailure failure = const NetworkFailure()]) => when(
    () => useCase.getAllCatsCall(),
  ).thenAnswer((_) async => Err<BreedsSnapshot>(failure));

  /// Mounts the page with a bloc that has already been told to fetch.
  ///
  /// Phase 6 note, and the reason this helper exists: the page no longer
  /// dispatches on mount. That dispatch lived in `initState`, where go_router
  /// re-created the page on every return from the detail screen and refetched the
  /// whole list; it now happens once, where `main.dart` builds the bloc. Tests say
  /// so explicitly, which is both closer to what the app does and harder to
  /// misread than a side effect of mounting.
  Future<void> pumpLoaded(WidgetTester tester) => tester.pumpAppWith(
    const LandingPage(),
    bloc: tester.buildBloc(useCase, fetchOnBuild: true),
  );

  group('LandingPage', () {
    testWidgets('does NOT fetch on its own when mounted', (tester) async {
      // The inverse of the test this replaces ('dispatches AllCatsEvent on
      // mount'). Re-adding the `initState` dispatch fails here, which is what
      // pins Phase 6's fix — every back navigation used to cost a request.
      ignoreOverflowErrors();
      stubSuccess();

      // Deliberately NOT `pumpLoaded`: the whole point is a bloc that was never
      // told to fetch.
      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase),
      );
      // `pump`, not `pumpAndSettle`: with no fetch the page stays on
      // `CatsInitial`, which renders a `CircularProgressIndicator` — an animation
      // that never settles. That is the correct behaviour here, so waiting for it
      // would hang.
      await tester.pump();

      verifyNever(() => useCase.getAllCatsCall());
      expect(find.byType(CatsLoadingView), findsOneWidget);
    });

    testWidgets('re-mounting the page does not refetch', (tester) async {
      // The bug itself, at the level where it happened: the same bloc, the page
      // mounted twice, exactly one request. Before Phase 6 this was two.
      ignoreOverflowErrors();
      stubSuccess();
      final bloc = tester.buildBloc(useCase, fetchOnBuild: true);

      await tester.pumpAppWith(const LandingPage(), bloc: bloc);
      await tester.pumpAndSettle();

      // Unmount and mount again, which is what a round trip to the detail screen
      // does to this widget.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAppWith(const LandingPage(), bloc: bloc);
      await tester.pumpAndSettle();

      verify(() => useCase.getAllCatsCall()).called(1);
      expect(find.byType(CardCatWidget), findsWidgets);
    });

    testWidgets('renders one card per breed', (tester) async {
      // `CardCatWidget` overflows with the test font (every glyph is a full
      // em), not in the real app. See the helper.
      ignoreOverflowErrors();
      final breeds = stubSuccess();

      await pumpLoaded(tester);
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
      // Phase 6 found this passing for the wrong reason: `CatsInitial` and
      // `CatsLoading` render the same `CatsLoadingView`, so a bloc that never
      // fetched at all looked identical to one mid-request. It asserted nothing.
      //
      // The fix is to name the state as well as the widget: the bloc must
      // genuinely be in `CatsLoading` while the completer is unresolved.
      final completer = Completer<CatsResult<BreedsSnapshot>>();
      when(() => useCase.getAllCatsCall()).thenAnswer((_) => completer.future);

      final bloc = tester.buildBloc(useCase, fetchOnBuild: true);
      await tester.pumpAppWith(const LandingPage(), bloc: bloc);
      await tester.pump();

      expect(bloc.state, isA<CatsLoading>());
      expect(find.byType(CatsLoadingView), findsOneWidget);
      expect(find.byType(CardCatWidget), findsNothing);
      expect(find.byType(CatsErrorView), findsNothing);

      // Complete the completer so no pending work is left behind.
      completer.complete(const Ok(FreshBreeds(breeds: [])));
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
      ).thenAnswer((_) async => const Ok(FreshBreeds(breeds: [])));

      await pumpLoaded(tester);
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

      await pumpLoaded(tester);
      await tester.pumpAndSettle();

      expect(find.byType(CatsErrorView), findsOneWidget);
      expect(find.byType(CatsLoadingView), findsNothing);
      expect(find.byType(CardCatWidget), findsNothing);
    });

    testWidgets('the error view shows the message for that specific failure', (
      tester,
    ) async {
      stubFailure(const ServerFailure(statusCode: 401));

      await pumpLoaded(tester);
      await tester.pumpAndSettle();

      // The typed failure travels all the way from the data layer to the copy.
      expect(find.textContaining('authenticate'), findsOneWidget);
    });

    testWidgets('tapping Retry re-dispatches AllCatsEvent', (tester) async {
      stubFailure();

      await pumpLoaded(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Twice: once from the bloc's creation, once from the retry. It used to say
      // "once from `initState`" — that dispatch is gone as of Phase 6.
      verify(() => useCase.getAllCatsCall()).called(2);
    });

    testWidgets('a successful retry replaces the error view with the list', (
      tester,
    ) async {
      ignoreOverflowErrors();
      stubFailure();

      await pumpLoaded(tester);
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
      //
      // Phase 6 found this passing for the wrong reason too: without a fetch the
      // page sat on `CatsInitial`, so it never reached the error state it claims
      // to test. The error view is now asserted before the tap.
      stubFailure();

      await pumpLoaded(tester);
      await tester.pumpAndSettle();
      expect(find.byType(CatsErrorView), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('unmounting it disposes the ScrollController', (tester) async {
      // `CardCatWidget` overflows with the test font (every glyph is a full
      // em), not in the real app. See the helper.
      ignoreOverflowErrors();
      stubSuccess();

      await pumpLoaded(tester);
      await tester.pumpAndSettle();

      final controller = tester
          .widget<Scrollbar>(find.byType(Scrollbar))
          .controller!;

      await tester.pumpWidget(const SizedBox());

      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    testWidgets('tapping "More..." navigates to the detail by id', (
      tester,
    ) async {
      // `CardCatWidget` overflows with the test font (every glyph is a full
      // em), not in the real app. See the helper.
      ignoreOverflowErrors();
      final breeds = stubSuccess();

      await tester.pumpRouter(
        bloc: tester.buildBloc(useCase, fetchOnBuild: true),
        initialLocation: '/home',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('More...').first);
      await tester.pumpAndSettle();

      expect(find.byType(DetailCatPage), findsOneWidget);
      // Phase 6: the page receives an id, not a whole entity. That is what makes
      // the route reconstructible from a URL — see `app_route_test.dart` for the
      // cold deep link this enables.
      expect(
        tester.widget<DetailCatPage>(find.byType(DetailCatPage)).breedId,
        breeds.first.id,
      );
    });
  });

  group('LandingPage when the breeds are stale', () {
    testWidgets('shows the list AND a banner, not an error screen', (
      tester,
    ) async {
      // Phase 6's whole point, at the UI. The same `NetworkFailure` that renders
      // `CatsErrorView` with no cache renders the full list here.
      ignoreOverflowErrors();
      stubStale();

      await pumpLoaded(tester);
      await tester.pumpAndSettle();

      expect(find.byType(StaleBanner), findsOneWidget);
      expect(find.byType(CardCatWidget), findsWidgets);
      expect(find.byType(CatsErrorView), findsNothing);
      expect(find.byType(CatsLoadingView), findsNothing);
    });

    testWidgets('the banner explains why the list is old', (tester) async {
      ignoreOverflowErrors();
      stubStale(const ServerFailure(statusCode: 503));

      await pumpLoaded(tester);
      await tester.pumpAndSettle();

      // The typed failure reaches the copy here exactly as it does in the error
      // view — same `messageFor`, different container.
      expect(find.textContaining('503'), findsOneWidget);
    });

    testWidgets('Refresh re-dispatches the fetch', (tester) async {
      ignoreOverflowErrors();
      stubStale();

      await pumpLoaded(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      verify(() => useCase.getAllCatsCall()).called(2);
    });

    testWidgets('the search screen still works offline', (tester) async {
      // The regression this guards: the app bar picks the breeds off the state,
      // and leaving `CatsStale` out of that pattern would show a full list with
      // an empty search — a silent failure, since nothing would throw.
      ignoreOverflowErrors();
      stubStale();

      await pumpLoaded(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Abyssinian');
      await tester.pumpAndSettle();

      // A result card, **not** `find.text('Abyssinian')`. That was the first
      // version of this assertion and it was a false green: `enterText` puts the
      // query into the search field, so the text is on screen whether or not the
      // delegate found anything, and dropping `CatsStale` from the app bar's
      // pattern left it passing. Counting cards is what actually distinguishes
      // "searched a list" from "searched nothing".
      expect(find.byType(CardCatWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
