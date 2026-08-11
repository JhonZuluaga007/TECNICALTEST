import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/landing_status_views.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('messageFor', () {
    test('gives every failure variant its own message', () {
      // No two causes share copy: that is the entire point of having replaced
      // `InvalidData`'s single interpolated string with a sealed hierarchy.
      final messages = <String>{
        messageFor(const NetworkFailure()),
        messageFor(const TimeoutFailure()),
        messageFor(const ServerFailure(statusCode: 500)),
        messageFor(const UnexpectedResponseFailure(detail: 'x')),
        messageFor(const UnknownFailure(detail: 'x')),
      };

      expect(messages, hasLength(5));
      expect(messages, everyElement(isNotEmpty));
    });

    test('401 and 403 read as authentication, not as a broken server', () {
      // The guard clause. It matters in practice: the API key hardcoded in
      // `Endpoints` returns 401, so this is the message the app shows today.
      const auth = 'Could not authenticate with the cat service.';

      expect(messageFor(const ServerFailure(statusCode: 401)), auth);
      expect(messageFor(const ServerFailure(statusCode: 403)), auth);
      expect(messageFor(const ServerFailure(statusCode: 500)), isNot(auth));
    });

    test('a server failure surfaces its status code', () {
      expect(messageFor(const ServerFailure(statusCode: 503)), contains('503'));
    });
  });

  group('CatsLoadingView', () {
    testWidgets('renders a spinner', (tester) async {
      await tester.pumpAppWith(const Scaffold(body: CatsLoadingView()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('CatsEmptyView', () {
    testWidgets('explains the empty result instead of rendering nothing', (
      tester,
    ) async {
      // Before Phase 3 this case was an empty `ListView`: a blank screen,
      // indistinguishable from a broken app.
      await tester.pumpAppWith(const Scaffold(body: CatsEmptyView()));

      expect(find.text('No cat breeds to show.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('CatsErrorView', () {
    testWidgets('shows the message for the failure it was given', (
      tester,
    ) async {
      await tester.pumpAppWith(
        Scaffold(
          body: CatsErrorView(failure: const NetworkFailure(), onRetry: () {}),
        ),
      );

      expect(find.text(messageFor(const NetworkFailure())), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('a different failure shows a different message', (
      tester,
    ) async {
      await tester.pumpAppWith(
        Scaffold(
          body: CatsErrorView(
            failure: const ServerFailure(statusCode: 401),
            onRetry: () {},
          ),
        ),
      );

      expect(find.textContaining('authenticate'), findsOneWidget);
    });

    testWidgets('tapping Retry invokes the callback exactly once', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpAppWith(
        Scaffold(
          body: CatsErrorView(
            failure: const TimeoutFailure(),
            onRetry: () => retries++,
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retries, 1);
    });

    testWidgets('does not need a bloc to be pumped', (tester) async {
      // The view takes a callback rather than reading the bloc, so it can be
      // tested in isolation — and `pumpAppWith` is called here with no bloc at
      // all, which is the assertion.
      await tester.pumpAppWith(
        Scaffold(
          body: CatsErrorView(
            failure: const UnknownFailure(detail: 'boom'),
            onRetry: () {},
          ),
        ),
      );

      expect(find.byType(CatsErrorView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
