import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tecnical_test_pragma/core/common_widgets/card/card_cat_widget.dart';
import 'package:tecnical_test_pragma/core/config/helpers/endpoints.dart';
import 'package:tecnical_test_pragma/core/injector/injector.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/pages/detail_cat_page.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/pages/landing_page.dart';
import 'package:tecnical_test_pragma/features/splash/presentation/pages/splash_catbreeds.dart';
import 'package:tecnical_test_pragma/main.dart';

import 'helpers/fixture_reader.dart';
import 'helpers/ignore_overflow_errors.dart';

/// The only test proving that DI + router + bloc + datasource are wired together,
/// and therefore the one Phases 3 through 9 are most likely to break.
///
/// It is only possible because the `Injector` registers `http.Client` as a
/// singleton and `setup()` accepts an injected one: without that seam there is no
/// way to boot the real app without network access.
void main() {
  tearDown(Injector.reset);

  testWidgets('splash -> landing with breeds -> detail', (tester) async {
    ignoreOverflowErrors();

    final requestedUrls = <String>[];
    Injector.setup(
      httpClient: MockClient((request) async {
        requestedUrls.add(request.url.toString());
        if (request.url.toString() == Endpoints.urlAllCats) {
          return jsonResponse(fixture('breeds_3.json'));
        }
        return jsonResponse(fixture('image_ok.json'));
      }),
    );

    await tester.pumpWidget(const MyApp());
    // `ScreenUtilInit` returns `SizedBox.shrink()` until a
    // `didChangeDependencies` and a `FutureBuilder` both resolve, so the first
    // pump renders nothing.
    await tester.pumpAndSettle();

    expect(find.byType(SplashCatBreeds), findsOneWidget);

    // The splash navigates after 5 s.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.byType(CardCatWidget), findsWidgets);
    expect(find.text('Abyssinian'), findsOneWidget);

    // Phase 4's fix, end to end through the real DI graph, router, bloc and
    // datasource — the one place it is observable rather than asserted on a unit.
    //
    // It used to be `hasLength(4)`: 1 breeds request + 1 image request per breed
    // in the payload, all of them resolved inside `getAllCats` before this screen
    // could paint at all. With the real 67-breed payload that is 66.
    //
    // Now the breeds request is the only one that happens up front, and images are
    // requested by the cards `ListView` actually builds. Only 2 of the 3 cards fit
    // in the 800x600 test surface, which is why the total is 3 and not 4 — and that
    // difference IS the fix: it scales with what is on screen, not with the payload.
    expect(requestedUrls.first, Endpoints.urlAllCats);
    expect(
      requestedUrls.where((url) => url == Endpoints.urlAllCats),
      hasLength(1),
      reason: 'exactly one request before first paint',
    );

    final imageRequests = requestedUrls
        .where((url) => url.startsWith(Endpoints.urlForGetImageCat))
        .length;
    final builtCards = find.byType(CardCatWidget).evaluate().length;

    expect(
      imageRequests,
      builtCards,
      reason: 'one image request per built card, and not one more',
    );
    expect(
      imageRequests,
      lessThan(3),
      reason:
          'fewer requests than breeds in the payload — the point of the fix',
    );

    await tester.tap(find.text('More...').first);
    await tester.pumpAndSettle();

    expect(find.byType(DetailCatPage), findsOneWidget);
    expect(
      tester
          .widget<DetailCatPage>(find.byType(DetailCatPage))
          .catBreedEntity
          .name,
      'Abyssinian',
    );

    // And going back does not crash.
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
  });
}
