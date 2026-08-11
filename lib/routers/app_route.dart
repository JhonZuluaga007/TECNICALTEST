import 'package:go_router/go_router.dart';
import 'package:tecnical_test_pragma/routers/routes_imports.dart';

/// Phase 2: `globalGoRouter` and `getGoRouter()` were removed.
///
/// They were a mutable static singleton with no reset hook: in widget tests they
/// leaked routing state across cases, and because of the `??=` the `widget`
/// parameter (which existed only for tests) applied only on the FIRST call in the
/// life of the process. `main.dart` called `getGoRouter()` three times and only
/// worked thanks to that memoization.
class AppRoute {
  /// [initialLocation] lets a test start at `/home` without going through the
  /// splash timer.
  static GoRouter router({String initialLocation = splashPage}) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: splashPage,
        name: splashPage,
        builder: (context, state) => const SplashCatBreeds(),
        routes: [
          GoRoute(
            path: homePage,
            name: homePage,
            builder: (context, state) => const LandingPage(),
            routes: [
              GoRoute(
                path: detailPage,
                name: detailPage,
                // The breed travels in `extra`, which is not reconstructible
                // from the URL: a deep link to `/home/detail` (Android app link,
                // web URL) or process restoration arrived with
                // `state.extra == null` and `(state.extra!) as CatBreedEntity`
                // blew up with a red screen. This redirect turns it into a
                // handled navigation.
                //
                // Phase 6 removes the problem at the root: route by id
                // (`detail/:id`), reading from the cache.
                redirect: (context, state) =>
                    state.extra is CatBreedEntity ? null : '/$homePage',
                builder: (context, state) => DetailCatPage(
                  catBreedEntity: state.extra! as CatBreedEntity,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
