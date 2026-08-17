import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';

/// The three non-list branches of `LandingPage`'s exhaustive `switch`.
///
/// They are public, and in their own file, for two reasons: `landing_page.dart`
/// stays readable, and widget tests can assert `find.byType(CatsErrorView)`
/// instead of matching on copy — which Phase 7 has now moved into ARB files, so
/// that indirection paid off exactly as intended.
///
/// None of them knows about the bloc — [CatsErrorView] takes an `onRetry`
/// callback — so each can be pumped on its own. Phase 9 promotes them to
/// `core/common_widgets/` if a second screen ever needs them.

/// Shown while the request is in flight, and for the initial state.
class CatsLoadingView extends StatelessWidget {
  const CatsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Shown when the request succeeded with zero breeds.
///
/// New in Phase 3. That case used to render an empty `ListView`, i.e. a blank
/// screen with no explanation — indistinguishable from a broken app.
class CatsEmptyView extends StatelessWidget {
  const CatsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 48.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              AppLocalizations.of(context).emptyBreeds,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the request failed. Replaces the infinite spinner.
class CatsErrorView extends StatelessWidget {
  const CatsErrorView({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final CatsFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.sp,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: 12.h),
            Text(
              messageFor(l10n, failure),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

/// Shown above the list when the breeds came from an expired cache.
///
/// New in Phase 6, and the visible half of `CatsStale`. It is a strip rather than
/// a full-screen state on purpose: the list underneath is real, usable data, and
/// the only thing wrong with it is its age. Replacing the screen with an error —
/// which is what happened before this phase — threw that away.
///
/// [onRetry] is the same callback the error view takes, so the user has a way out
/// without hunting for one.
class StaleBanner extends StatelessWidget {
  const StaleBanner({super.key, required this.failure, required this.onRetry});

  final CatsFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outline, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 20.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 8.w),
          Expanded(
            // The ARB template keeps the ordering this comment used to defend:
            // the copy says the list is old BEFORE saying why. The cause is
            // secondary — what the user needs to know first is that what they are
            // looking at is still usable.
            child: Text(
              l10n.staleBanner(messageFor(l10n, failure)),
              textAlign: TextAlign.start,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(width: 8.w),
          TextButton(onPressed: onRetry, child: Text(l10n.refresh)),
        ],
      ),
    );
  }
}

/// Maps a failure to the copy the user reads.
///
/// It lives in the presentation layer on purpose: the domain should not own copy.
/// Phase 7 replaced the right-hand sides with localized lookups, in this one
/// place, exactly as Phase 3 said it would.
///
/// **Still a top-level pure function, and [l10n] comes first.** It could have
/// taken a `BuildContext`, but then asserting on the copy would mean pumping a
/// widget; a caller can get an [AppLocalizations] from
/// `AppLocalizations.delegate.load(...)` in one line, so the eight unit tests
/// that cover this stay unit tests.
///
/// Exhaustive by construction — `CatsFailure` is `sealed`, so adding a variant
/// stops this from compiling until it has a message.
@visibleForTesting
String messageFor(
  AppLocalizations l10n,
  CatsFailure failure,
) => switch (failure) {
  NetworkFailure() => l10n.failureNetwork,
  TimeoutFailure() => l10n.failureTimeout,
  // A guard clause, so an auth problem does not read as "our servers are
  // down".
  //
  // This comment used to add "the API key shipped in `Endpoints` returns 401,
  // which makes this the branch the app actually hits today". Phase 4 measured
  // that and it was false — `/v1/breeds` answers 200 anonymously, so this
  // branch is not the common case. It stays because a wrong key is still
  // possible; it is just not what the app does.
  ServerFailure(:final statusCode)
      when statusCode == 401 || statusCode == 403 =>
    l10n.failureAuth,
  ServerFailure(:final statusCode) => l10n.failureServer(statusCode),
  UnexpectedResponseFailure() => l10n.failureUnexpected,
  // No id in the copy: it is an internal key, and the user did not type it —
  // they followed a link. Retrying is pointless here, which is also why
  // `isRetryable` says no.
  NotFoundFailure() => l10n.failureNotFound,
  UnknownFailure() => l10n.failureUnknown,
};
