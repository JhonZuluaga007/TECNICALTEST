import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tecnical_test_pragma/core/common_widgets/card/card_cat_widget.dart';
import 'package:tecnical_test_pragma/core/config/helpers/endpoints.dart';
import 'package:tecnical_test_pragma/core/design_system/cats_tokens.dart';
import 'package:tecnical_test_pragma/core/injector/injector.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/pages/detail_cat_page.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/pages/landing_page.dart';
import 'package:tecnical_test_pragma/features/splash/presentation/pages/splash_catbreeds.dart';
import 'package:tecnical_test_pragma/main.dart';

import 'helpers/fixture_reader.dart';
import 'helpers/in_memory_key_value_store.dart';
import 'helpers/window_size.dart';

/// The only test proving that DI + router + bloc + datasource + storage are wired
/// together, and therefore the one Phases 3 through 9 are most likely to break.
///
/// It is only possible because the `Injector` takes both seams — an `http.Client`
/// and a `Storage` — from its caller. Without them there is no way to boot the real
/// app without network access or a real disk.
void main() {
  tearDown(Injector.reset);

  /// Boots the real app against a fake network and a fake disk.
  ///
  /// Returns the URLs requested, in order, so a test can assert on how much the
  /// app asked for rather than only on what it showed.
  Future<List<String>> bootApp(
    WidgetTester tester, {
    InMemoryStorage? storage,
  }) async {
    final requestedUrls = <String>[];
    // Awaited as of Phase 5: `setup` resets the container first, which runs the
    // dispose callbacks, and get_it's `reset()` is asynchronous for that reason.
    await Injector.setup(
      // Phase 6: required, so that forgetting it in `main.dart` would be a compile
      // error rather than an app that silently stops persisting anything.
      storage: storage ?? InMemoryStorage(),
      httpClient: MockClient((request) async {
        requestedUrls.add(request.url.toString());
        if (request.url.toString() == Endpoints.urlAllCats) {
          // Phase 8 switched this from `breeds_3.json` to the real 67-breed
          // payload. With three breeds, "fewer image requests than breeds" was
          // arithmetic about the viewport — at a phone size all three ended up
          // built, cache extent included, and the claim became false without
          // anything regressing. With 67 it is unambiguous at every window size.
          return jsonResponse(fixture('breeds_full.json'));
        }
        return jsonResponse(fixture('image_ok.json'));
      }),
    );

    // Phase 8: pinned to a phone. `flutter_test`'s default 800x600 surface is a
    // `WindowSize.medium` window, where the landing renders a two-column grid
    // that fits all three cards — and the assertion below, "fewer image requests
    // than breeds in the payload", would then be measuring the viewport rather
    // than the laziness it is there to prove.
    setWindowSize(tester, phone);
    await tester.pumpWidget(const MyApp());
    // Phase 8: the note that used to be here explained that `ScreenUtilInit`
    // rendered `SizedBox.shrink()` on the first pump. That wrapper is gone; the
    // settle is still needed for the router and the initial fetch.
    await tester.pumpAndSettle();

    return requestedUrls;
  }

  testWidgets('splash -> landing with breeds -> detail', (tester) async {
    final requestedUrls = await bootApp(tester);

    expect(find.byType(SplashCatBreeds), findsOneWidget);

    // Phase 6: the breeds request already happened, during the splash. It used to
    // wait for `LandingPage.initState`, i.e. for the five seconds to elapse.
    expect(
      requestedUrls.where((url) => url == Endpoints.urlAllCats),
      hasLength(1),
      reason: 'the fetch starts at app launch, not when the list appears',
    );

    // The splash navigates after 5 s.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.byType(CardCatWidget), findsWidgets);
    expect(find.text('Abyssinian'), findsOneWidget);

    // Phase 4's fix, end to end through the real DI graph, router, bloc and
    // datasource — the one place it is observable rather than asserted on a unit.
    //
    // It used to be `hasLength(68)`: 1 breeds request + 1 image request per breed
    // in the payload, all of them resolved inside `getAllCats` before this screen
    // could paint at all.
    //
    // Now the breeds request is the only one that happens up front, and images are
    // requested by the cards the `ListView` actually builds. 67 breeds arrive and
    // a handful of requests go out — that difference IS the fix: it scales with
    // what is on screen, not with the payload.
    expect(requestedUrls.first, Endpoints.urlAllCats);

    final imageRequests = requestedUrls
        .where((url) => url.startsWith(Endpoints.urlForGetImageCat))
        .length;
    final builtCards = find.byType(CardCatWidget).evaluate().length;

    // Phase 8 relaxed this from an exact `imageRequests == builtCards`. That
    // equality was not the invariant it looked like: `ListView` has a 250 px
    // `cacheExtent`, so it builds a card or two past the viewport, and those
    // cards resolve their image and can then be recycled. "Currently built" is a
    // lower bound on "ever built", and the two coincided only because the old
    // 800x600 surface happened to make them.
    expect(
      imageRequests,
      greaterThanOrEqualTo(builtCards),
      reason: 'every card on screen resolved its own image',
    );
    expect(
      imageRequests,
      lessThan(10),
      reason:
          '67 breeds in the payload, a handful of requests — the point of the fix',
    );

    await tester.tap(find.text('More...').first);
    await tester.pumpAndSettle();

    expect(find.byType(DetailCatPage), findsOneWidget);
    // Phase 6: the page carries an id, and resolves the breed itself. The title
    // proves the resolution actually happened — the id alone would only prove the
    // route matched.
    expect(
      tester.widget<DetailCatPage>(find.byType(DetailCatPage)).breedId,
      'abys',
    );
    expect(find.text('Abyssinian'), findsWidgets);

    // And going back does not crash.
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
  });

  testWidgets('the detail and the trip back cost no extra breeds request', (
    tester,
  ) async {
    // Phase 6, end to end, and the clearest statement of what it bought.
    //
    // Two separate fixes have to hold for this to pass: the dispatch is no longer
    // in `LandingPage.initState` (so re-mounting the page on the way back does not
    // refetch), and `getBreedById` resolves against the repository's cache (so
    // opening the detail does not either). Either one regressing makes this 2 or 3.

    final requestedUrls = await bootApp(tester);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('More...').first);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      requestedUrls.where((url) => url == Endpoints.urlAllCats),
      hasLength(1),
      reason: 'one breeds request for the whole journey',
    );
  });

  testWidgets('a dark device with no stored preference boots dark', (
    tester,
  ) async {
    // Phase 7's new behaviour, end to end. Before it, `MaterialApp.router` was
    // passed no theme at all, so a device in dark mode got the light app — and
    // there was nothing to assert on, because `Theme.of` returned the Material
    // fallback either way.
    //
    // The three pieces have to line up for this to pass: `darkTheme` is provided,
    // `themeMode` comes from the cubit, and the cubit hydrates to
    // `ThemeMode.system` from an empty box. Any one of them missing turns this
    // light.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await bootApp(tester, storage: InMemoryStorage());

    // Read off a real widget's context rather than off the `MaterialApp`
    // arguments: what matters is the theme the screen is painted with, and
    // `themeMode` resolution happens between the two.
    final theme = Theme.of(tester.element(find.byType(SplashCatBreeds)));

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.brightness, Brightness.dark);
    // The extension has to survive the resolution too — `Theme.of(context).cats`
    // uses `!`, so a `darkTheme` built without it crashes the first rating meter.
    expect(theme.extension<CatsTokens>(), isNotNull);
  });

  testWidgets('the same device boots light when the platform is light', (
    tester,
  ) async {
    // The control. Without it the test above passes against an app hardcoded to
    // `AppTheme.dark()`, which is the same bug in the other direction.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await bootApp(tester, storage: InMemoryStorage());

    expect(
      Theme.of(tester.element(find.byType(SplashCatBreeds))).brightness,
      Brightness.light,
    );
  });

  testWidgets('a second launch on the same storage serves breeds from disk', (
    tester,
  ) async {
    // The cache surviving a process restart, which is the only place the whole
    // chain is exercised: repository -> local data source -> KeyValueStore ->
    // Storage, with the container wiring them.
    final storage = InMemoryStorage();

    await bootApp(tester, storage: storage);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Tear the app down and boot it again on the same box, as a relaunch would.
    await tester.pumpWidget(const SizedBox());
    final secondRun = await bootApp(tester, storage: storage);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(
      secondRun.where((url) => url == Endpoints.urlAllCats),
      isEmpty,
      reason: 'the cached list is inside its TTL, so nothing is asked for',
    );
    expect(find.text('Abyssinian'), findsOneWidget);
  });
}
