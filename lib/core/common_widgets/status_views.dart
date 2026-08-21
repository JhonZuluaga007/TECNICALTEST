import 'package:flutter/material.dart';

import 'package:tecnical_test_pragma/core/design_system/radii.dart';
import 'package:tecnical_test_pragma/core/design_system/spacing.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';

/// The non-list branches of a screen's exhaustive state `switch`.
///
/// They are public, and in their own file, for two reasons: the pages that use
/// them stay readable, and widget tests can assert `find.byType(CatsErrorView)`
/// instead of matching on copy — which Phase 7 has now moved into ARB files, so
/// that indirection paid off exactly as intended.
///
/// None of them knows about a bloc — [CatsErrorView] takes an `onRetry`
/// callback — so each can be pumped on its own.
///
/// Phase 9 moved them here from `features/landing_cats/`, where they were called
/// `landing_status_views.dart`. The condition the old comment set — "if a second
/// screen ever needs them" — had already been met by the detail screen, which
/// was reaching across the feature boundary to import them. The move is legal
/// where `BreedImage`'s is not: these four depend on nothing but `AppSpacing`,
/// `CatsFailure` and the ARB files.
///
/// [CatsEmptyView] and [StaleBanner] still have exactly one consumer each. They
/// came along anyway: [messageFor] has to live here for [CatsErrorView], and
/// splitting the set would leave the landing feature importing its own copy
/// mapping from `core/` while two of its four siblings stayed behind. Half a set
/// in each layer is the worse boundary.

/// Shown while the request is in flight, and for the initial state.
class CatsLoadingView extends StatelessWidget {
  const CatsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// The shared body of the full-screen status views: an icon, a line of copy and
/// an optional action.
///
/// Phase 9 extracted it from [CatsEmptyView] and [CatsErrorView], which were the
/// same `Center`/`Padding`/`Column`/`Icon`/`Text` skeleton differing only in the
/// icon, its colour, and whether a button followed.
///
/// Private, and in this file: two callers in one file do not need a public
/// widget, and a third status view now costs four arguments instead of a copy.
class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.iconColor,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            // Both the gap and the button, or neither. Emitting the `SizedBox`
            // unconditionally would push the empty view's copy 16 px up off
            // centre for a button that is not there.
            if (action case final action?) ...[
              const SizedBox(height: AppSpacing.lg),
              action,
            ],
          ],
        ),
      ),
    );
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
    return _StatusMessage(
      icon: Icons.pets_outlined,
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      message: AppLocalizations.of(context).emptyBreeds,
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
    final l10n = AppLocalizations.of(context);

    return _StatusMessage(
      icon: Icons.error_outline,
      iconColor: Theme.of(context).colorScheme.error,
      message: messageFor(l10n, failure),
      action: ElevatedButton(onPressed: onRetry, child: Text(l10n.retry)),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
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
          const SizedBox(width: AppSpacing.sm),
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
