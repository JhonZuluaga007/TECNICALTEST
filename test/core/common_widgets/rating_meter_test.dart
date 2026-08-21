import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/common_widgets/rating_meter.dart';
import 'package:tecnical_test_pragma/core/design_system/cats_tokens.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('RatingMeter', () {
    /// The filled/empty split, read off what was actually painted.
    ///
    /// Phase 9: the meter had no test file of its own — its behaviour was
    /// covered incidentally through the card and the detail list, which meant
    /// the one thing it exists to do (turn a number into filled dots) was never
    /// asserted directly.
    (int filled, int empty) dots(WidgetTester tester) {
      final tokens = Theme.of(tester.element(find.byType(RatingMeter))).cats;
      final avatars = tester.widgetList<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      return (
        avatars.where((a) => a.backgroundColor == tokens.ratingFilled).length,
        avatars.where((a) => a.backgroundColor == tokens.ratingEmpty).length,
      );
    }

    testWidgets('always draws exactly five dots', (tester) async {
      await tester.pumpAppWith(
        const RatingMeter(label: 'Intelligence:', value: 3),
      );

      expect(find.byType(CircleAvatar), findsNWidgets(5));
    });

    testWidgets('fills as many dots as the value', (tester) async {
      await tester.pumpAppWith(
        const RatingMeter(label: 'Intelligence:', value: 3),
      );

      expect(dots(tester), (3, 2));
    });

    testWidgets('fills none at zero and all at five', (tester) async {
      await tester.pumpAppWith(const RatingMeter(label: 'Low:', value: 0));
      expect(dots(tester), (0, 5));

      await tester.pumpAppWith(const RatingMeter(label: 'High:', value: 5));
      expect(dots(tester), (5, 0));
    });

    testWidgets('clamps a value above five to five filled dots', (
      tester,
    ) async {
      // The API takes an `int`, and TheCatAPI is documented as 1-5 but is not
      // enforced by the model. A value of 7 must not draw seven dots or throw —
      // the loop is bound to five, and this pins that.
      await tester.pumpAppWith(
        const RatingMeter(label: 'Off scale:', value: 7),
      );

      expect(find.byType(CircleAvatar), findsNWidgets(5));
      expect(dots(tester), (5, 0));
    });

    testWidgets('defaults the dot radius to 10', (tester) async {
      await tester.pumpAppWith(
        const RatingMeter(label: 'Intelligence:', value: 3),
      );

      expect(
        tester.widget<CircleAvatar>(find.byType(CircleAvatar).first).radius,
        10,
      );
    });

    testWidgets('lets the caller override the dot radius', (tester) async {
      await tester.pumpAppWith(
        const RatingMeter(label: 'Intelligence:', value: 3, dotRadius: 12),
      );

      expect(
        tester.widget<CircleAvatar>(find.byType(CircleAvatar).first).radius,
        12,
      );
    });

    testWidgets('ellipsizes the label rather than overflowing', (tester) async {
      // Phase 8's rule: the label gives way, never the dots, because the dots
      // carry the value and the label is what grows with the user's text size.
      await tester.pumpAppWith(
        RatingMeter(label: 'Intelligence: ${'very ' * 40}', value: 3),
      );

      expect(
        tester.widget<Text>(find.byType(Text)).overflow,
        TextOverflow.ellipsis,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CircleAvatar), findsNWidgets(5));
    });
  });
}
