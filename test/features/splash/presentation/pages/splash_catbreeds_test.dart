import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/config/helpers/errors/invalid_data.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/pages/landing_page.dart';
import 'package:tecnical_test_pragma/features/splash/presentation/pages/splash_catbreeds.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late MockGetAllCatsUseCase useCase;

  setUp(() {
    useCase = MockGetAllCatsUseCase();
    when(() => useCase.getAllCatsCall()).thenAnswer(
      (_) async => const Right<InvalidData, List<CatBreedEntity>>([]),
    );
  });

  group('SplashCatBreeds', () {
    testWidgets('renders the title', (tester) async {
      await tester.pumpRouter(bloc: tester.buildBloc(useCase));

      expect(find.byType(SplashCatBreeds), findsOneWidget);
      expect(find.text('Catbreeds'), findsOneWidget);
    });

    testWidgets('navigates to the landing after 5 seconds', (tester) async {
      await tester.pumpRouter(bloc: tester.buildBloc(useCase));

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byType(LandingPage), findsOneWidget);
      expect(find.byType(SplashCatBreeds), findsNothing);
    });

    testWidgets('unmounting it before the 5 s leaves no pending timer', (
      tester,
    ) async {
      // Fails before Phase 2 with:
      //   "A Timer is still pending even after the widget tree was disposed."
      //
      // The `Timer? timer` field was never assigned (the timer was returned inside
      // a discarded `Future<Timer>`), so there was no way to cancel it, and there
      // was no `dispose()` anywhere in the project.
      await tester.pumpRouter(bloc: tester.buildBloc(useCase));
      expect(find.byType(SplashCatBreeds), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());

      // flutter_test's binding checks for pending timers when the test ends.
    });

    testWidgets('unmounting it and advancing the clock does not navigate on a '
        'dead context', (tester) async {
      await tester.pumpRouter(bloc: tester.buildBloc(useCase));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 6));

      expect(tester.takeException(), isNull);
    });
  });
}
