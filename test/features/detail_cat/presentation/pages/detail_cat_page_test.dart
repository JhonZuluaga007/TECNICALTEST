import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/common_widgets/breed_characteristic_widget.dart';
import 'package:tecnical_test_pragma/core/common_widgets/text/text_widget.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/pages/detail_cat_page.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  final breed = catBreedEntity(
    name: 'Abyssinian',
    origin: 'Egypt',
    lifeSpan: '14 - 15',
    description: 'Easy to care for and a joy to have.',
    intelligence: 5,
    adaptability: 4,
  );

  group('DetailCatPage', () {
    testWidgets('renders the name, description, country and life span', (
      tester,
    ) async {
      await tester.pumpAppWith(DetailCatPage(catBreedEntity: breed));

      expect(find.text('Abyssinian'), findsOneWidget);
      expect(find.text('Easy to care for and a joy to have.'), findsOneWidget);
      expect(find.text('Country: Egypt'), findsOneWidget);
      expect(find.text('LifeSpan: 14 - 15 years'), findsOneWidget);
    });

    testWidgets('renders intelligence and adaptability with their values', (
      tester,
    ) async {
      await tester.pumpAppWith(DetailCatPage(catBreedEntity: breed));

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
      // `TextAlign.start` was a no-op.
      await tester.pumpAppWith(DetailCatPage(catBreedEntity: breed));

      final countryWidget = tester.widget<TextWidget>(
        find.widgetWithText(TextWidget, 'Country: Egypt'),
      );
      expect(countryWidget.textAlign, TextAlign.start);

      final countryText = tester.widget<Text>(find.text('Country: Egypt'));
      expect(countryText.textAlign, TextAlign.start);
    });

    testWidgets('unmounting it disposes the ScrollController', (tester) async {
      await tester.pumpAppWith(DetailCatPage(catBreedEntity: breed));

      final controller = tester
          .widget<Scrollbar>(find.byType(Scrollbar))
          .controller!;

      await tester.pumpWidget(const SizedBox());

      // `ChangeNotifier.debugAssertNotDisposed` throws a `FlutterError` after
      // dispose. Deterministic, with no dependence on GC timing.
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });
  });
}
