import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/design_system/spacing.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/common_widgets/status_views.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';

void main() {
  // Phase 7: `messageFor` now takes an `AppLocalizations`. Loading the delegate
  // directly is what keeps these eight assertions unit tests — the alternative,
  // reading it off a `BuildContext`, would mean pumping a widget to check a
  // string.
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('messageFor', () {
    test('gives every failure variant its own message', () {
      // No two causes share copy: that is the entire point of having replaced
      // `InvalidData`'s single interpolated string with a sealed hierarchy.
      //
      // **This list is hand-written and cannot enforce its own completeness** —
      // Phase 6 found it asserting `hasLength(5)` while `CatsFailure` had grown a
      // sixth variant, i.e. green and no longer meaning what its name says. What
      // does enforce it is the compiler: `messageFor` is an exhaustive `switch`
      // over a sealed type, so a new variant breaks the build, and
      // `cats_failure_test.dart`'s own switch breaks with it. This test only
      // checks that the messages are distinct and non-empty.
      final messages = <String>{
        messageFor(l10n, const NetworkFailure()),
        messageFor(l10n, const TimeoutFailure()),
        messageFor(l10n, const ServerFailure(statusCode: 500)),
        messageFor(l10n, const UnexpectedResponseFailure(detail: 'x')),
        messageFor(l10n, const NotFoundFailure(id: 'abys')),
        messageFor(l10n, const UnknownFailure(detail: 'x')),
      };

      expect(messages, hasLength(6));
      expect(messages, everyElement(isNotEmpty));
    });

    test('401 and 403 read as authentication, not as a broken server', () {
      // The guard clause. This comment used to claim the hardcoded key returned
      // 401 "so this is the message the app shows today"; Phase 4 measured it and
      // it was false. The branch still earns its place — a wrong key is possible —
      // it is just not the common path.
      const auth = 'Could not authenticate with the cat service.';

      expect(messageFor(l10n, const ServerFailure(statusCode: 401)), auth);
      expect(messageFor(l10n, const ServerFailure(statusCode: 403)), auth);
      expect(
        messageFor(l10n, const ServerFailure(statusCode: 500)),
        isNot(auth),
      );
    });

    test('a server failure surfaces its status code', () {
      expect(
        messageFor(l10n, const ServerFailure(statusCode: 503)),
        contains('503'),
      );
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

      expect(
        find.text(messageFor(l10n, const NetworkFailure())),
        findsOneWidget,
      );
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

  group('the shared status-message skeleton', () {
    /// Vertical gaps inside one status view.
    ///
    /// Phase 9 pulled the empty and error views onto a common private body. The
    /// difference between them is the trailing action, and the trap is emitting
    /// its gap unconditionally: the empty view would gain 16 px of space below
    /// copy that is supposed to sit centred, pushing it visibly off centre.
    ///
    /// Found by mutation, not by design — making the gap unconditional left the
    /// whole suite green, so this is the case that was missing.
    /// Matched on its height rather than by counting every `SizedBox` in the
    /// subtree: `ElevatedButton` brings one of its own, so a raw count asserts
    /// about Material's internals as much as about this layout.
    Finder actionGapIn(Type view) => find.descendant(
      of: find.byType(view),
      matching: find.byWidgetPredicate(
        (w) => w is SizedBox && w.height == AppSpacing.lg,
      ),
    );

    testWidgets('the empty view emits no gap for the action it does not have', (
      tester,
    ) async {
      await tester.pumpAppWith(const Scaffold(body: CatsEmptyView()));

      expect(actionGapIn(CatsEmptyView), findsNothing);
    });

    testWidgets('the error view emits exactly one gap before its button', (
      tester,
    ) async {
      await tester.pumpAppWith(
        Scaffold(
          body: CatsErrorView(failure: const NetworkFailure(), onRetry: () {}),
        ),
      );

      expect(actionGapIn(CatsErrorView), findsOneWidget);
    });

    testWidgets('the empty view keeps its content vertically centred', (
      tester,
    ) async {
      // The user-visible consequence of the same trap, stated as a position
      // rather than as a widget count. The `Column` fills the viewport, so its
      // own edges say nothing; what moves is the icon-to-copy block inside it,
      // which a trailing 16 px gap would push up by half that.
      await tester.pumpAppWith(const Scaffold(body: CatsEmptyView()));

      final column = tester.getRect(
        find.descendant(
          of: find.byType(CatsEmptyView),
          matching: find.byType(Column),
        ),
      );
      final icon = tester.getRect(find.byType(Icon));
      final copy = tester.getRect(find.byType(Text));

      expect((icon.top + copy.bottom) / 2, closeTo(column.center.dy, 0.5));
    });
  });
}
