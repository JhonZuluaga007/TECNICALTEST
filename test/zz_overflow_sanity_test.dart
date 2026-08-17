// TEMPORARY sanity check for the ignoreOverflowErrors measurement.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/ignore_overflow_errors.dart';

void main() {
  Widget overflowing() => const MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 50,
        child: Row(children: [SizedBox(width: 400, height: 10)]),
      ),
    ),
  );

  testWidgets('SANITY without the helper an overflow is reported', (
    tester,
  ) async {
    await tester.pumpWidget(overflowing());
  });

  testWidgets('SANITY with the helper it is silenced', (tester) async {
    ignoreOverflowErrors();
    await tester.pumpWidget(overflowing());
  });
}
