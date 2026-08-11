import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/common_widgets/breed_characteristic_widget.dart';
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
          .widgetList<BreedCharacteristicWidget>(
            find.byType(BreedCharacteristicWidget),
          )
          .toList();

      expect(widgets, hasLength(2));
      expect(widgets[0].nameCharacteristic, 'Intelligence:');
      expect(widgets[0].value, 5);
      expect(widgets[1].nameCharacteristic, 'Adaptability:');
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

      expect(find.byType(BreedCharacteristicWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('applies the fontSize and radius defaults', (tester) async {
      await tester.pumpAppWith(
        const ListCharacteristicsCatbreeds(
          characteristics: [(label: 'Intelligence:', value: 5)],
        ),
      );

      final widget = tester.widget<BreedCharacteristicWidget>(
        find.byType(BreedCharacteristicWidget),
      );
      expect(widget.fontSize, 18);
      expect(widget.radius, 10);
    });

    testWidgets('forwards fontSize and radius when provided', (tester) async {
      await tester.pumpAppWith(
        const ListCharacteristicsCatbreeds(
          characteristics: [(label: 'Intelligence:', value: 5)],
          fontSize: 20,
          radius: 12,
        ),
      );

      final widget = tester.widget<BreedCharacteristicWidget>(
        find.byType(BreedCharacteristicWidget),
      );
      expect(widget.fontSize, 20);
      expect(widget.radius, 12);
    });
  });
}
