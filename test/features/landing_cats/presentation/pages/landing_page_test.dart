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
import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/window_size.dart';

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
  Future<void> pumpLoaded(WidgetTester tester, {Size windowSize = phone}) =>
      tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase, fetchOnBuild: true),
        windowSize: windowSize,
      );

  group('LandingPage', () {
    testWidgets('does NOT fetch on its own when mounted', (tester) async {
      // The inverse of the test this replaces ('dispatches AllCatsEvent on
      // mount'). Re-adding the `initState` dispatch fails here, which is what
      // pins Phase 6's fix — every back navigation used to cost a request.
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
      final breeds = stubSuccess();

      await pumpLoaded(tester);
      await tester.pumpAndSettle();

      // The `semanticChildCount` is asserted rather than the number of rendered
      // cards: the list is lazy, and only some of them fit on screen. Counting
      // built widgets would tie the test to the viewport size.
      //
      // Phase 8 simplified this in two ways. The pump defaults to a phone, so
      // this is the one-column `ListView` branch and there is exactly one list to
      // find. And the filter by `scrollDirection` that used to be needed here is
      // gone with the horizontal `ListView` that `BreedCharacteristicWidget`
      // nested inside every card — five dots that always fit did not need a
      // scrollable, and it cost a `ScrollPosition` per card.
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.scrollDirection, Axis.vertical);
      expect(list.semanticChildCount, 3);
      expect(find.byType(CardCatWidget), findsWidgets);
      expect(find.text(breeds.first.name), findsOneWidget);
    });

    // Phase 8. The landing screen is the only adaptive surface in the app, and
    // these are the tests that say so. `pumpLoaded` defaults to a phone (see
    // `window_size.dart`), so a test that wants the grid asks for the window.
    group('adapts to the window', () {
      testWidgets('a phone renders a one-column ListView, not a grid', (
        tester,
      ) async {
        stubSuccess();

        await pumpLoaded(tester, windowSize: phone);
        await tester.pumpAndSettle();

        expect(find.byType(GridView), findsNothing);
        expect(
          tester.widget<ListView>(find.byType(ListView)).semanticChildCount,
          3,
        );
      });

      for (final (window, columns) in <(Size, int)>[
        (tabletPortrait, 2),
        (tabletLandscape, 3),
        (desktop, 4),
      ]) {
        testWidgets('a ${window.width.toInt()} px window lays out $columns '
            'columns', (tester) async {
          stubSuccess();

          await pumpLoaded(tester, windowSize: window);
          await tester.pumpAndSettle();

          expect(find.byType(ListView), findsNothing);
          final grid = tester.widget<GridView>(find.byType(GridView));
          final delegate =
              grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

          expect(delegate.crossAxisCount, columns);
          // Found by mutation. `landing_page.dart` first passed
          // `semanticChildCount: breeds.length` explicitly, with a comment
          // claiming `GridView.builder` does not infer it — deleting the
          // argument left this test green, and the SDK says why:
          // `scroll_view.dart:2067` is `semanticChildCount ?? itemCount`. The
          // argument was redundant and the comment was wrong, so both are gone.
          //
          // The assertion stays, retargeted: it no longer guards an explicit
          // argument, it guards that the grid was handed all three breeds
          // rather than a truncated list.
          expect(grid.semanticChildCount, 3);
        });
      }

      testWidgets('resizing from a phone to a desktop swaps list for grid', (
        tester,
      ) async {
        stubSuccess();

        await pumpLoaded(tester, windowSize: phone);
        await tester.pumpAndSettle();
        expect(find.byType(ListView), findsOneWidget);

        setWindowSize(tester, desktop);
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsNothing);
        expect(find.byType(GridView), findsOneWidget);
      });
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

  group('LandingPage in Spanish', () {
    // The test that proves the l10n is a lookup rather than ceremony.
    //
    // Every other widget test in the suite pins `Locale('en')` so it can assert
    // on copy, and the ARB values were copied character-for-character from the
    // literals they replaced — which means a widget that never stopped
    // hardcoding its English string passes all of them. Pumping the same page in
    // `es` is the only assertion that can tell the two apart.
    testWidgets('the empty view reads from the ARB, not from a literal', (
      tester,
    ) async {
      when(
        () => useCase.getAllCatsCall(),
      ).thenAnswer((_) async => const Ok(FreshBreeds(breeds: [])));

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase, fetchOnBuild: true),
        locale: const Locale('es'),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay razas de gato para mostrar.'), findsOneWidget);
      // Both halves matter: the second is what fails if the widget renders the
      // English literal, the first if it renders nothing at all.
      expect(find.text('No cat breeds to show.'), findsNothing);
    });

    testWidgets('the error view localizes the failure copy too', (
      tester,
    ) async {
      // `messageFor`'s right-hand sides were the last hardcoded strings in the
      // presentation layer (`TODO(phase 7)` in `landing_status_views.dart`).
      // Interpolation included: the status code has no `format:` in the ARB, so
      // 503 must not come out as "1,503" or as a localized decimal.
      stubFailure(const ServerFailure(statusCode: 503));

      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase, fetchOnBuild: true),
        locale: const Locale('es'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('El servicio de gatos falló (503). Inténtalo más tarde.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('LandingPage when the breeds are stale', () {
    testWidgets('shows the list AND a banner, not an error screen', (
      tester,
    ) async {
      // Phase 6's whole point, at the UI. The same `NetworkFailure` that renders
      // `CatsErrorView` with no cache renders the full list here.
      stubStale();

      await pumpLoaded(tester);
      await tester.pumpAndSettle();

      expect(find.byType(StaleBanner), findsOneWidget);
      expect(find.byType(CardCatWidget), findsWidgets);
      expect(find.byType(CatsErrorView), findsNothing);
      expect(find.byType(CatsLoadingView), findsNothing);
    });

    testWidgets('the banner explains why the list is old', (tester) async {
      stubStale(const ServerFailure(statusCode: 503));

      await pumpLoaded(tester);
      await tester.pumpAndSettle();

      // The typed failure reaches the copy here exactly as it does in the error
      // view — same `messageFor`, different container.
      expect(find.textContaining('503'), findsOneWidget);
    });

    testWidgets('Refresh re-dispatches the fetch', (tester) async {
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
