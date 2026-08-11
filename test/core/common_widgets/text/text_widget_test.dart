import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/common_widgets/text/text_widget.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('TextWidget', () {
    testWidgets('forwards textAlign to the Text', (tester) async {
      // Failed before Phase 2: `textAlign` was declared and never forwarded, so
      // the two call sites passing it were silent no-ops.
      await tester.pumpAppWith(
        const TextWidget(
          text: 'Catbreeds',
          textAlign: TextAlign.center,
          fontSize: 18,
          colorText: Colors.black,
        ),
      );

      expect(
        tester.widget<Text>(find.byType(Text)).textAlign,
        TextAlign.center,
      );
    });

    testWidgets('without textAlign it invents no default', (tester) async {
      await tester.pumpAppWith(
        const TextWidget(
          text: 'Catbreeds',
          fontSize: 18,
          colorText: Colors.black,
        ),
      );

      expect(tester.widget<Text>(find.byType(Text)).textAlign, isNull);
    });

    testWidgets('renders the text', (tester) async {
      await tester.pumpAppWith(
        const TextWidget(
          text: 'Abyssinian',
          fontSize: 18,
          colorText: Colors.black,
        ),
      );

      expect(find.text('Abyssinian'), findsOneWidget);
    });

    testWidgets(
      'forwards fontSize, color, weight and style to the text style',
      (tester) async {
        // Guards Phase 7's `ThemeData` migration: if the wrapper stops applying
        // the style, this catches it.
        await tester.pumpAppWith(
          const TextWidget(
            text: 'Catbreeds',
            fontSize: 42,
            colorText: Colors.red,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        );

        final style = tester.widget<Text>(find.byType(Text)).style!;
        expect(style.fontSize, 42);
        expect(style.color, Colors.red);
        expect(style.fontWeight, FontWeight.bold);
        expect(style.fontStyle, FontStyle.italic);
      },
    );
  });
}
