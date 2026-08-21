import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/common_widgets/app_scaffold.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppScaffold', () {
    testWidgets('leaves backgroundColor null so the theme decides', (
      tester,
    ) async {
      await tester.pumpAppWith(const AppScaffold(children: [Text('body')]));

      // Not "is transparent" and not "equals surface": the point is that the
      // widget hands `Scaffold` nothing, so `ThemeData.scaffoldBackgroundColor`
      // applies and follows the brightness. Asserting a concrete colour here
      // would pass just as happily against a hardcoded one.
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        isNull,
      );
    });

    testWidgets('forwards backgroundColor when a caller passes one', (
      tester,
    ) async {
      await tester.pumpAppWith(
        const AppScaffold(
          backgroundColor: Color(0xFF123456),
          children: [Text('body')],
        ),
      );

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        const Color(0xFF123456),
      );
    });

    testWidgets('puts the whole scaffold inside a SafeArea', (tester) async {
      await tester.pumpAppWith(const AppScaffold(children: [Text('body')]));

      expect(
        find.ancestor(
          of: find.byType(Scaffold),
          matching: find.byType(SafeArea),
        ),
        findsOneWidget,
      );
    });

    testWidgets('accepts any PreferredSizeWidget, not just an AppBar', (
      tester,
    ) async {
      // Phase 9 widened `appBar` from `AppBar?`. This case is as much a
      // compile-time assertion as a runtime one: before the widening it did not
      // type-check, and a `PreferredSize` is the cheapest bar that is not an
      // `AppBar`.
      await tester.pumpAppWith(
        const AppScaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(24),
            child: Text('bar'),
          ),
          children: [Text('body')],
        ),
      );

      expect(find.text('bar'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });
  });
}
