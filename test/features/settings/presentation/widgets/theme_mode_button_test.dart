import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/features/settings/presentation/widgets/theme_mode_button.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('ThemeModeButton', () {
    /// The icon currently drawn, which is the only thing the user sees of the
    /// cubit's state.
    IconData icon(WidgetTester tester) =>
        tester.widget<Icon>(find.byType(Icon)).icon!;

    testWidgets('starts on the system icon', (tester) async {
      await tester.pumpAppWith(const ThemeModeButton());

      // `system` is the cubit's initial state, and the only correct one before
      // the user has expressed a preference — see `ThemeModeCubit`.
      expect(icon(tester), Icons.brightness_auto_outlined);
    });

    testWidgets('cycles system -> light -> dark -> system', (tester) async {
      await tester.pumpAppWith(const ThemeModeButton());

      // A cycle, not a boolean toggle: "follow the system" has to stay
      // reachable. A toggle that only swaps light and dark takes the user out of
      // `system` on the first tap with no way back, so the wrap-around on the
      // third tap is the part of this that actually matters.
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(icon(tester), Icons.light_mode_outlined);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(icon(tester), Icons.dark_mode_outlined);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(icon(tester), Icons.brightness_auto_outlined);
    });

    testWidgets('takes its tooltip from the ARB, not from a literal', (
      tester,
    ) async {
      // Pumped in Spanish on purpose: asserting the English copy would pass just
      // as happily against a hardcoded string that happens to match the ARB.
      await tester.pumpAppWith(
        const ThemeModeButton(),
        locale: const Locale('es'),
      );

      expect(
        tester.widget<IconButton>(find.byType(IconButton)).tooltip,
        'Cambiar tema',
      );
    });
  });
}
