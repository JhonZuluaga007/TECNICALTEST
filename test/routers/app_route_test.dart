import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/pages/detail_cat_page.dart';
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
    ).thenAnswer((_) async => const Ok<List<CatBreedEntity>>([]));
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

    testWidgets(
      'initialLocation allows starting at /home without going through '
      'the splash',
      (tester) async {
        await tester.pumpRouter(
          bloc: tester.buildBloc(useCase),
          initialLocation: '/home',
        );
        await tester.pumpAndSettle();

        expect(find.byType(LandingPage), findsOneWidget);
        expect(find.byType(SplashCatBreeds), findsNothing);
      },
    );

    testWidgets('navigating to the detail with extra renders the breed', (
      tester,
    ) async {
      ignoreOverflowErrors();
      final breed = catBreedModel(name: 'Abyssinian');
      final bloc = tester.buildBloc(useCase);

      await tester.pumpRouter(bloc: bloc, initialLocation: '/home');
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LandingPage));
      GoRouter.of(context).goNamed('detail', extra: breed);
      await tester.pumpAndSettle();

      expect(find.byType(DetailCatPage), findsOneWidget);
      expect(
        tester.widget<DetailCatPage>(find.byType(DetailCatPage)).catBreedEntity,
        breed,
      );
    });

    testWidgets('a deep link to /home/detail with no extra redirects to /home '
        'without crashing', (tester) async {
      // Fails before Phase 2 with a red-screen `TypeError`: the builder did
      // `(state.extra!) as CatBreedEntity` and `extra` is not reconstructible from
      // the URL. Reachable from outside the app (Android app link, web URL) or on
      // process restoration.
      final router = AppRoute.router();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        BlocProvider.value(
          value: tester.buildBloc(useCase),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/home/detail');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DetailCatPage), findsNothing);
      expect(find.byType(LandingPage), findsOneWidget);
    });
  });
}
