import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tecnical_test_pragma/core/common_widgets/text/text_widget.dart';
import 'package:tecnical_test_pragma/core/config/theme/app_cats_colors.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';

/// The three non-list branches of `LandingPage`'s exhaustive `switch`.
///
/// They are public, and in their own file, for two reasons: `landing_page.dart`
/// stays readable, and widget tests can assert `find.byType(CatsErrorView)`
/// instead of matching on copy that Phase 7's localization will move anyway.
///
/// None of them knows about the bloc — [CatsErrorView] takes an `onRetry`
/// callback — so each can be pumped on its own. Phase 9 promotes them to
/// `core/common_widgets/` if a second screen ever needs them.

/// Shown while the request is in flight, and for the initial state.
class CatsLoadingView extends StatelessWidget {
  const CatsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: AppCatsColor().black),
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
    final wColor = AppCatsColor();
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets_outlined, size: 48.sp, color: wColor.black[50]),
            SizedBox(height: 12.h),
            TextWidget(
              text: 'No cat breeds to show.',
              textAlign: TextAlign.center,
              fontSize: 18,
              colorText: wColor.black,
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
    final wColor = AppCatsColor();
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: wColor.black[100]),
            SizedBox(height: 12.h),
            TextWidget(
              text: messageFor(failure),
              textAlign: TextAlign.center,
              fontSize: 18,
              colorText: wColor.black,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onRetry,
              child: TextWidget(
                text: 'Retry',
                fontSize: 16,
                colorText: wColor.black,
              ),
            ),
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
    final wColor = AppCatsColor();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: wColor.mapColors["W"],
        border: Border.all(color: wColor.black, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 20.sp, color: wColor.black[100]),
          SizedBox(width: 8.w),
          Expanded(
            child: TextWidget(
              // Deliberately says the list is old BEFORE saying why. The cause is
              // secondary — what the user needs to know first is that what they
              // are looking at is still usable.
              text: 'Showing saved breeds. ${messageFor(failure)}',
              textAlign: TextAlign.start,
              fontSize: 14,
              colorText: wColor.black,
            ),
          ),
          SizedBox(width: 8.w),
          TextButton(
            onPressed: onRetry,
            child: TextWidget(
              text: 'Refresh',
              fontSize: 14,
              colorText: wColor.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Maps a failure to the copy the user reads.
///
/// It lives in the presentation layer on purpose: the domain should not own copy,
/// and Phase 7 replaces the right-hand sides with localized lookups in this one
/// place.
///
/// Exhaustive by construction — `CatsFailure` is `sealed`, so adding a variant
/// stops this from compiling until it has a message.
///
// TODO(phase 7): these strings move to ARB files with the rest of the copy.
@visibleForTesting
String messageFor(CatsFailure failure) => switch (failure) {
  NetworkFailure() =>
    'No internet connection. Check your network and try again.',
  TimeoutFailure() => 'The request took too long. Try again.',
  // A guard clause, so an auth problem does not read as "our servers are down".
  //
  // This comment used to add "the API key shipped in `Endpoints` returns 401,
  // which makes this the branch the app actually hits today". Phase 4 measured
  // that and it was false — `/v1/breeds` answers 200 anonymously, so this branch
  // is not the common case. It stays because a wrong key is still possible; it is
  // just not what the app does.
  ServerFailure(:final statusCode)
      when statusCode == 401 || statusCode == 403 =>
    'Could not authenticate with the cat service.',
  ServerFailure(:final statusCode) =>
    'The cat service failed ($statusCode). Try again later.',
  UnexpectedResponseFailure() =>
    'The cat service returned something unexpected.',
  // No id in the copy: it is an internal key, and the user did not type it — they
  // followed a link. Retrying is pointless here, which is also why
  // `isRetryable` says no.
  NotFoundFailure() => 'We could not find that cat breed.',
  UnknownFailure() => 'Something went wrong. Try again.',
};
