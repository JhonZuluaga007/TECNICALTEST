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

    // 1 breeds request + 3 image requests, through the real datasource.
    expect(requestedUrls, hasLength(4));
    expect(requestedUrls.first, Endpoints.urlAllCats);

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
