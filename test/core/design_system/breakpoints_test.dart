import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/design_system/breakpoints.dart';

import '../../helpers/window_size.dart';

void main() {
  group('WindowSize.fromWidth', () {
    // The boundaries are the whole content of this type, so they are asserted on
    // both sides. An off-by-one here is invisible in the app — the layout still
    // renders, just one column wrong on exactly one window width.
    test('classifies each Material 3 boundary, on both sides', () {
      expect(WindowSize.fromWidth(0), WindowSize.compact);
      expect(WindowSize.fromWidth(599.9), WindowSize.compact);
      expect(WindowSize.fromWidth(600), WindowSize.medium);
      expect(WindowSize.fromWidth(839.9), WindowSize.medium);
      expect(WindowSize.fromWidth(840), WindowSize.expanded);
      expect(WindowSize.fromWidth(1199.9), WindowSize.expanded);
      expect(WindowSize.fromWidth(1200), WindowSize.large);
      expect(WindowSize.fromWidth(4000), WindowSize.large);
    });

    test('classifies the devices the golden tests use', () {
      expect(WindowSize.fromWidth(phone.width), WindowSize.compact);
      expect(WindowSize.fromWidth(tabletPortrait.width), WindowSize.medium);
      expect(WindowSize.fromWidth(tabletLandscape.width), WindowSize.expanded);
      expect(WindowSize.fromWidth(desktop.width), WindowSize.large);
    });
  });

  group('WindowSize.columns', () {
    test('one column per size class, increasing', () {
      expect(WindowSize.compact.columns, 1);
      expect(WindowSize.medium.columns, 2);
      expect(WindowSize.expanded.columns, 3);
      expect(WindowSize.large.columns, 4);
    });

    // Written as a property rather than as four literals so that adding a fifth
    // size class cannot land with a column count that goes backwards.
    test('never decreases as the window grows', () {
      final counts = WindowSize.values.map((size) => size.columns).toList();
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThan(counts[i - 1]));
      }
    });
  });

  group('WindowSize.of', () {
    testWidgets('reads the width from the enclosing MediaQuery', (
      tester,
    ) async {
      late WindowSize seen;
      setWindowSize(tester, tabletLandscape);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              seen = WindowSize.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen, WindowSize.expanded);
    });

    testWidgets('follows the window when it is resized', (tester) async {
      final seen = <WindowSize>[];
      setWindowSize(tester, phone);

      Widget probe() => MaterialApp(
        home: Builder(
          builder: (context) {
            seen.add(WindowSize.of(context));
            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpWidget(probe());
      setWindowSize(tester, desktop);
      await tester.pumpWidget(probe());
      await tester.pump();

      expect(seen.first, WindowSize.compact);
      expect(seen.last, WindowSize.large);
    });
  });
}
