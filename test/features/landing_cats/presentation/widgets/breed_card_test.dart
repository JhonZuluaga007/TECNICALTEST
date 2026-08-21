import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/common_widgets/rating_meter.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/breed_card.dart';
import 'package:tecnical_test_pragma/core/design_system/app_theme.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';

import '../../../../helpers/window_size.dart';

/// Phase 8's regression suite for the overflow that was real.
///
/// Every phase before this one carried an `ignoreOverflowErrors()` helper and a
/// paragraph explaining that overflows under `flutter test` were an artifact of
/// the test font, in which every glyph is a full em square. That was true — and
/// it hid a second, real overflow underneath it.
///
/// Measured with the Acme font Phase 7 bundled, at `titleLarge`:
/// `Text('Intelligence:')` is 107.6 px at text scale 1.0, 161.3 at 1.5 and
/// **215.1 at 2.0** — against the `SizedBox(width: 190.w)` this card used to
/// impose on it. The card overflowed by 37 px at scale 2.0, on a 390 px phone,
/// with no accessibility setting more exotic than the largest system font size.
void main() {
  /// Collects overflow reports instead of failing on them, so a test can assert
  /// on *which* ones happened rather than only that the pump survived.
  List<String> captureOverflows() {
    final reported = <String>[];
    final original = FlutterError.onError;
    // Installed inside the test body, never in a `setUp`: `testWidgets` replaces
    // `FlutterError.onError` after the `setUp` callbacks run, so a `setUp`
    // placement would filter nothing. Same trap the deleted
    // `ignoreOverflowErrors()` documented.
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('overflowed')) {
        reported.add(details.exception.toString().split('\n').first);
      } else {
        original?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = original);
    return reported;
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required double textScale,
    Size window = phone,
    String name = 'Egyptian Mau',
    String origin = 'Egypt',
  }) async {
    setWindowSize(tester, window);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: BreedCard(
                name: name,
                image: const SizedBox(height: 100),
                origin: origin,
                intelligence: 5,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('BreedCard layout', () {
    // 2.0 is the value that used to overflow. 1.0 and 1.5 are here so a fix that
    // only worked at the extreme would still be caught.
    for (final scale in <double>[1.0, 1.5, 2.0]) {
      testWidgets('does not overflow on a phone at text scale $scale', (
        tester,
      ) async {
        final overflows = captureOverflows();

        await pumpCard(tester, textScale: scale);

        expect(overflows, isEmpty, reason: overflows.join(' | '));
      });
    }

    testWidgets('does not overflow with a long name and a long origin', (
      tester,
    ) async {
      final overflows = captureOverflows();

      // The longest pair in the real payload, rather than invented strings.
      await pumpCard(
        tester,
        textScale: 2.0,
        name: 'American Wirehair',
        origin: 'United States',
      );

      expect(overflows, isEmpty, reason: overflows.join(' | '));
    });

    testWidgets('the meter drops onto its own line when the row cannot fit', (
      tester,
    ) async {
      captureOverflows();
      await pumpCard(tester, textScale: 1.0);
      final tightTop = tester.getTopLeft(find.byType(RatingMeter));

      await pumpCard(tester, textScale: 2.0);
      final looseTop = tester.getTopLeft(find.byType(RatingMeter));

      // The `Wrap` is what fixes the overflow, so the test asserts the wrapping
      // actually happened rather than only that nothing was reported: a card
      // whose meter is clipped away entirely would also report no overflow.
      expect(
        looseTop.dy,
        greaterThan(tightTop.dy),
        reason: 'at scale 2.0 the meter should move below the origin',
      );
      expect(looseTop.dx, lessThan(tightTop.dx));
    });
  });
}
