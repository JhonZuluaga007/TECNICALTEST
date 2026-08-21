import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/common_widgets/rating_meter.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/widgets/list_characteristics_catbreeds_widget.dart';

import '../../../../helpers/pump_app.dart';

/// There is no test for label/value misalignment: with a single list of records
/// that state is unrepresentable, so there is nothing to assert. It used to be two
/// parallel lists, where a label without its value was a `RangeError`.
void main() {
  group('ListCharacteristicsCatbreeds', () {
    testWidgets('renders one widget per characteristic', (tester) async {
      await tester.pumpAppWith(
        const ListCharacteristicsCatbreeds(
          characteristics: [
            (label: 'Intelligence:', value: 5),
            (label: 'Adaptability:', value: 3),
          ],
        ),
      );

      final widgets = tester
          .widgetList<RatingMeter>(find.byType(RatingMeter))
          .toList();

      expect(widgets, hasLength(2));
      expect(widgets[0].label, 'Intelligence:');
      expect(widgets[0].value, 5);
      expect(widgets[1].label, 'Adaptability:');
      expect(widgets[1].value, 3);
      expect(find.text('Intelligence:'), findsOneWidget);
      expect(find.text('Adaptability:'), findsOneWidget);
    });

    testWidgets('an empty list renders nothing and does not throw', (
      tester,
    ) async {
      await tester.pumpAppWith(
        const ListCharacteristicsCatbreeds(characteristics: []),
      );

      expect(find.byType(RatingMeter), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('applies the labelStyle and dot radius defaults', (
      tester,
    ) async {
      await tester.pumpAppWith(
        const ListCharacteristicsCatbreeds(
          characteristics: [(label: 'Intelligence:', value: 5)],
        ),
      );

      final widget = tester.widget<RatingMeter>(find.byType(RatingMeter));
      // Phase 7: the default is a role off the theme, not a number.
      //
      // Compared against the theme **of the widget's own context**, not against
      // `AppTheme.light().textTheme.bodyLarge`: `MaterialApp` merges the
      // locale's text geometry into the theme it hands down, so the raw
      // `ThemeData` and what `Theme.of` returns are not the same object.
      final context = tester.element(find.byType(RatingMeter));
      expect(widget.labelStyle, Theme.of(context).textTheme.bodyLarge);

      // Phase 9: this used to be `expect(widget.radius, 10)`, which only proved
      // the list forwarded the number it had just been handed. The default now
      // lives inside [RatingMeter], so the list forwards `null` — and the
      // assertion moved onto the dot that actually gets drawn, which is what the
      // old one was standing in for anyway.
      expect(widget.dotRadius, isNull);
      expect(
        tester.widget<CircleAvatar>(find.byType(CircleAvatar).first).radius,
        10,
      );
    });

    testWidgets('forwards labelStyle and dotRadius when provided', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 20);
      await tester.pumpAppWith(
        const ListCharacteristicsCatbreeds(
          characteristics: [(label: 'Intelligence:', value: 5)],
          labelStyle: style,
          dotRadius: 12,
        ),
      );

      final widget = tester.widget<RatingMeter>(find.byType(RatingMeter));
      expect(widget.labelStyle, style);
      expect(widget.dotRadius, 12);
      expect(
        tester.widget<CircleAvatar>(find.byType(CircleAvatar).first).radius,
        12,
      );
    });
  });
}
