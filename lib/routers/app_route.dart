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
              // Phase 6: `detail/:id`, where the breed used to travel in `extra`.
              //
              // `extra` is not reconstructible from a URL, so a deep link to
              // `/home/detail` (an Android app link, a web URL) or a process
              // restoration arrived with `state.extra == null` and
              // `(state.extra!) as CatBreedEntity` blew up with a red screen.
              // There used to be a `redirect` here sending those to the home
              // screen — a way of not crashing, not a way of working.
              //
              // **That redirect is gone**, and there is nothing in its place: an
              // id in the path is all the screen needs, so `/home/detail/abys`
              // now opens the breed on a cold start. `DetailCatPage` resolves it
              // against the repository, which reads the disk cache first.
              GoRoute(
                path: '$detailPage/:id',
                name: detailPage,
                builder: (context, state) =>
                    DetailCatPage(breedId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
