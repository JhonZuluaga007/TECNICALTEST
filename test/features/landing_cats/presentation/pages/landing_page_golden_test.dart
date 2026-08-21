@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/breeds_snapshot.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/pages/landing_page.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/window_size.dart';

/// Golden tests for the adaptive landing screen.
///
/// **Only possible as of Phase 7**, which bundled `Acme-Regular.ttf` as an asset
/// and dropped `google_fonts`. `flutter_test` has no font-loading code of its
/// own, so before that every glyph rendered as an empty box and a golden would
/// have pinned the box, not the type. `flutter_test_config.dart` loads the real
/// font for every test file.
///
/// Phase 9 tagged this file `golden` so CI can run it on a macOS runner, the
/// host these PNGs were generated on. Font rasterization differs between
/// platforms, so the same tree can be pixel-correct here and one antialiased
/// edge off on Linux — a failure that says nothing about the code. The tag is
/// how the Linux job excludes it *and* how the macOS job selects it, so the file
/// cannot end up skipped by both.
///
/// Regenerate with:
///
/// ```bash
/// fvm flutter test --update-goldens test/features/landing_cats/presentation/pages/landing_page_golden_test.dart
/// ```
///
/// Failures write the actual/expected/diff triplet under `test/**/failures/`,
/// which `.gitignore` has covered since Phase 0 — it was added there for exactly
/// this phase.
void main() {
  late MockGetAllCatsUseCase useCase;

  setUp(() {
    useCase = MockGetAllCatsUseCase();
    when(() => useCase.getAllCatsCall()).thenAnswer(
      (_) async => Ok(FreshBreeds(breeds: breedsFrom('breeds_3.json'))),
    );
  });

  // One golden per window size class. They are the cheapest possible check that
  // the grid actually looks like a grid: `crossAxisCount == 3` is satisfied just
  // as well by three columns of clipped rubble.
  for (final (name, window) in <(String, Size)>[
    ('compact', phone),
    ('medium', tabletPortrait),
    ('expanded', tabletLandscape),
    ('large', desktop),
  ]) {
    testWidgets('landing at $name', (tester) async {
      await tester.pumpAppWith(
        const LandingPage(),
        bloc: tester.buildBloc(useCase, fetchOnBuild: true),
        windowSize: window,
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LandingPage),
        matchesGoldenFile('goldens/landing_$name.png'),
      );
    });
  }
}
