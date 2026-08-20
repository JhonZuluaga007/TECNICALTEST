import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/common_widgets/breed_characteristic_widget.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/pages/detail_cat_page.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/landing_status_views.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/window_size.dart';

void main() {
  late MockGetBreedByIdUseCase useCase;

  final breed = catBreedEntity(
    id: 'abys',
    name: 'Abyssinian',
    origin: 'Egypt',
    lifeSpan: '14 - 15',
    description: 'Easy to care for and a joy to have.',
    intelligence: 5,
    adaptability: 4,
  );

  setUp(() => useCase = MockGetBreedByIdUseCase());

  void stubFound() =>
      when(() => useCase('abys')).thenAnswer((_) async => Ok(breed));

  void stubFailure(CatsFailure failure) => when(
    () => useCase('abys'),
  ).thenAnswer((_) async => Err<CatBreedEntity>(failure));

  /// Mounts the page and settles the lookup.
  ///
  /// Phase 6 changed the shape of every test in this file. The page used to be
  /// handed a fully-built `CatBreedEntity` through the route, so it had nothing to
  /// load and nothing that could fail; it now receives an id and resolves it. The
  /// assertions below are unchanged — what changed is that they need a pump.
  Future<void> pumpDetail(
    WidgetTester tester, {
    Size windowSize = phone,
  }) async {
    await tester.pumpAppWith(
      const DetailCatPage(breedId: 'abys'),
      breedByIdUseCase: useCase,
      windowSize: windowSize,
    );
    await tester.pumpAndSettle();
  }

  group('DetailCatPage', () {
    setUp(stubFound);

    testWidgets('renders the name, description, country and life span', (
      tester,
    ) async {
      await pumpDetail(tester);

      expect(find.text('Abyssinian'), findsOneWidget);
      expect(find.text('Easy to care for and a joy to have.'), findsOneWidget);
      expect(find.text('Country: Egypt'), findsOneWidget);
      expect(find.text('LifeSpan: 14 - 15 years'), findsOneWidget);
    });

    testWidgets('renders intelligence and adaptability with their values', (
      tester,
    ) async {
      await pumpDetail(tester);

      final characteristics = tester
          .widgetList<BreedCharacteristicWidget>(
            find.byType(BreedCharacteristicWidget),
          )
          .toList();

      expect(characteristics, hasLength(2));
      expect(characteristics[0].nameCharacteristic, 'Intelligence:');
      expect(characteristics[0].value, 5);
      expect(characteristics[1].nameCharacteristic, 'Adaptability:');
      expect(characteristics[1].value, 4);
    });

    testWidgets('the country textAlign reaches the Text', (tester) async {
      // Before Phase 2 `TextWidget` did not forward `textAlign`, so this
      // `TextAlign.start` was a no-op. Phase 7 deleted `TextWidget` — the
      // wrapper half of this test went with it, and what is left is the
      // assertion that always mattered: the `Text` actually carries the
      // alignment.
      await pumpDetail(tester);

      final countryText = tester.widget<Text>(find.text('Country: Egypt'));
      expect(countryText.textAlign, TextAlign.start);
    });

    testWidgets('unmounting it disposes the ScrollController', (tester) async {
      await pumpDetail(tester);

      final controller = tester
          .widget<Scrollbar>(find.byType(Scrollbar))
          .controller!;

      await tester.pumpWidget(const SizedBox());

      // `ChangeNotifier.debugAssertNotDisposed` throws a `FlutterError` after
      // dispose. Deterministic, with no dependence on GC timing.
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    testWidgets('looks the breed up by the id it was given', (tester) async {
      await pumpDetail(tester);

      verify(() => useCase('abys')).called(1);
    });
  });

  group('DetailCatPage measure', () {
    // A description long enough to wrap, so the `Text` fills the width it is
    // given instead of sizing to its own content — which is what makes its
    // rendered width a measurement of the constraint above it.
    final wordy = catBreedEntity(
      id: 'abys',
      name: 'Abyssinian',
      description: List.filled(60, 'graceful').join(' '),
    );

    setUp(() => when(() => useCase('abys')).thenAnswer((_) async => Ok(wordy)));

    double descriptionWidth(WidgetTester tester) =>
        tester.getSize(find.text(wordy.description)).width;

    // Phase 8. The description is the longest text in the app; left to fill a
    // 1440 px window it becomes a line the eye cannot track back from. The cap is
    // typographic rather than a breakpoint, so it is asserted as a width and not
    // as a `WindowSize`.
    testWidgets('the description fills a phone edge to edge', (tester) async {
      await pumpDetail(tester, windowSize: phone);

      // 390 minus the screen's 16 px horizontal padding on each side.
      expect(descriptionWidth(tester), closeTo(390 - 32, 1));
    });

    testWidgets('the description stops widening on a desktop window', (
      tester,
    ) async {
      await pumpDetail(tester, windowSize: desktop);

      expect(descriptionWidth(tester), lessThanOrEqualTo(720));
      expect(
        descriptionWidth(tester),
        greaterThan(600),
        reason: 'capped, not collapsed to the phone width',
      );
    });
  });

  group('DetailCatPage while resolving', () {
    /// Holds the lookup open, so the loading state is observable.
    ///
    /// A plain `thenAnswer((_) async => ...)` resolves within the first pump, so
    /// the spinner would never be seen and the test would assert nothing.
    ///
    /// **Created inside the test body, never in a `setUp`** — the same trap
    /// `pump_app.dart` documents for blocs, and it bites identically here.
    /// `setUp` runs outside `testWidgets`' `FakeAsync` zone, so a `Completer`
    /// built there produces a future bound to the real zone: `pump` never drains
    /// it, the state stays on loading, and `pumpAndSettle` dies on the spinner's
    /// animation with "timed out" — pointing at the pump rather than at the
    /// completer.
    Completer<CatsResult<CatBreedEntity>> stubPending() {
      final pending = Completer<CatsResult<CatBreedEntity>>();
      when(() => useCase('abys')).thenAnswer((_) => pending.future);
      return pending;
    }

    testWidgets('shows the loading view before the breed arrives', (
      tester,
    ) async {
      final pending = stubPending();

      await tester.pumpAppWith(
        const DetailCatPage(breedId: 'abys'),
        breedByIdUseCase: useCase,
      );
      await tester.pump();

      expect(find.byType(CatsLoadingView), findsOneWidget);
      expect(find.text('Easy to care for and a joy to have.'), findsNothing);

      pending.complete(Ok(breed));
      await tester.pumpAndSettle();
    });

    testWidgets('falls back to a generic title until the breed is known', (
      tester,
    ) async {
      // The app bar used to read `catBreedEntity.name`, which was always there
      // because the whole entity arrived through the route. It now has to cope
      // with not knowing yet.
      final pending = stubPending();

      await tester.pumpAppWith(
        const DetailCatPage(breedId: 'abys'),
        breedByIdUseCase: useCase,
      );
      await tester.pump();

      expect(find.text('Catbreeds'), findsOneWidget);
      expect(tester.takeException(), isNull);

      pending.complete(Ok(breed));
      await tester.pumpAndSettle();

      // And it takes the real name once it has one.
      expect(find.text('Abyssinian'), findsOneWidget);
    });
  });

  group('DetailCatPage when the breed cannot be shown', () {
    testWidgets('an unknown id shows a message, not a blank screen', (
      tester,
    ) async {
      // The case routing by id introduces: a stale link, a typed URL, a breed the
      // API dropped. Before Phase 6 the route could not express it — the entity
      // was always handed over pre-built, and a deep link with no entity crashed.
      stubFailure(const NotFoundFailure(id: 'abys'));

      await pumpDetail(tester);

      expect(find.byType(CatsErrorView), findsOneWidget);
      expect(find.textContaining('could not find'), findsOneWidget);
    });

    testWidgets('a network failure reads as a network failure', (tester) async {
      // Not "not found". Saying the breed does not exist because the request
      // failed would be a lie, and the typed failure is what keeps them apart all
      // the way from the data layer to the copy.
      stubFailure(const NetworkFailure());

      await pumpDetail(tester);

      expect(find.textContaining('No internet connection'), findsOneWidget);
    });

    testWidgets('Retry re-runs the same lookup', (tester) async {
      stubFailure(const NetworkFailure());

      await pumpDetail(tester);

      when(() => useCase('abys')).thenAnswer((_) async => Ok(breed));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(CatsErrorView), findsNothing);
      expect(find.text('Country: Egypt'), findsOneWidget);
      verify(() => useCase('abys')).called(2);
    });
  });
}
