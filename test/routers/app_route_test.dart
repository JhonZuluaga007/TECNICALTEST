import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/pages/detail_cat_page.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/breeds_snapshot.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/pages/landing_page.dart';
import 'package:tecnical_test_pragma/features/splash/presentation/pages/splash_catbreeds.dart';
import 'package:tecnical_test_pragma/routers/app_route.dart';

import '../helpers/builders.dart';
import '../helpers/ignore_overflow_errors.dart';
import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

void main() {
  late MockGetAllCatsUseCase useCase;

  setUp(() {
    useCase = MockGetAllCatsUseCase();
    when(
      () => useCase.getAllCatsCall(),
    ).thenAnswer((_) async => const Ok(FreshBreeds(breeds: [])));
  });

  group('AppRoute.router', () {
    test('each call returns a new instance', () {
      // There used to be a `static GoRouter? globalGoRouter` with `??=`: the same
      // router was reused for the whole process, leaking routing state across
      // tests. This assertion is what unblocks every other navigation test.
      final first = AppRoute.router();
      addTearDown(first.dispose);
      final second = AppRoute.router();
      addTearDown(second.dispose);

      expect(first, isNot(same(second)));
    });

    testWidgets('starts at the splash by default', (tester) async {
      await tester.pumpRouter(bloc: tester.buildBloc(useCase));

      expect(find.byType(SplashCatBreeds), findsOneWidget);
    });

    testWidgets('initialLocation allows starting at /home without going through '
        'the splash', (tester) async {
      // `fetchOnBuild` mirrors `main.dart`. Without it the landing page sits on
      // `CatsInitial`, whose spinner never settles.
      await tester.pumpRouter(
        bloc: tester.buildBloc(useCase, fetchOnBuild: true),
        initialLocation: '/home',
      );
      await tester.pumpAndSettle();

      expect(find.byType(LandingPage), findsOneWidget);
      expect(find.byType(SplashCatBreeds), findsNothing);
    });

    testWidgets('navigating to the detail by name carries the id', (
      tester,
    ) async {
      ignoreOverflowErrors();
      final bloc = tester.buildBloc(useCase, fetchOnBuild: true);

      await tester.pumpRouter(bloc: bloc, initialLocation: '/home');
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LandingPage));
      // Phase 6: `pathParameters`, where this used to be `extra: breed`. The
      // difference is the entire point — this destination can be written down.
      GoRouter.of(context).goNamed('detail', pathParameters: {'id': 'abys'});
      await tester.pumpAndSettle();

      expect(find.byType(DetailCatPage), findsOneWidget);
      expect(
        tester.widget<DetailCatPage>(find.byType(DetailCatPage)).breedId,
        'abys',
      );
    });

    testWidgets('a cold deep link to /home/detail/<id> opens the breed', (
      tester,
    ) async {
      // **This test replaces the one Phase 6 deleted**, and the swap is the
      // clearest statement of what changed.
      //
      // The old one was called "a deep link to /home/detail with no extra
      // redirects to /home without crashing". It pinned a workaround: the builder
      // did `(state.extra!) as CatBreedEntity`, `extra` is not reconstructible
      // from a URL, so an app link or a process restoration red-screened — and
      // Phase 2 added a `redirect` sending those to the home screen. Not crashing
      // was the best that route could do.
      //
      // Now the id is in the path, so the deep link **works**: no landing screen
      // visited, no bloc state consulted, the breed on screen.
      ignoreOverflowErrors();
      final breed = catBreedEntity(id: 'abys', name: 'Abyssinian');
      final breedByIdUseCase = MockGetBreedByIdUseCase();
      when(() => breedByIdUseCase('abys')).thenAnswer((_) async => Ok(breed));

      await tester.pumpRouter(
        bloc: tester.buildBloc(useCase),
        initialLocation: '/home/detail/abys',
        breedByIdUseCase: breedByIdUseCase,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DetailCatPage), findsOneWidget);
      expect(find.text('Abyssinian'), findsOneWidget);
      expect(find.byType(LandingPage), findsNothing);
    });

    testWidgets('a deep link with an unknown id explains itself', (
      tester,
    ) async {
      // The failure mode routing by id introduces, and it is a much better one
      // than the red screen it replaces: a message the user can read.
      final breedByIdUseCase = MockGetBreedByIdUseCase();
      when(() => breedByIdUseCase('nope')).thenAnswer(
        (_) async => const Err<CatBreedEntity>(NotFoundFailure(id: 'nope')),
      );

      await tester.pumpRouter(
        bloc: tester.buildBloc(useCase),
        initialLocation: '/home/detail/nope',
        breedByIdUseCase: breedByIdUseCase,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('could not find'), findsOneWidget);
    });
  });
}
