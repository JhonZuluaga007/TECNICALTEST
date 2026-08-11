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
  // The API key currently shipped in `Endpoints` returns 401, which makes this
  // the branch the app actually hits today. Phase 4 owns the key itself.
  ServerFailure(:final statusCode)
      when statusCode == 401 || statusCode == 403 =>
    'Could not authenticate with the cat service.',
  ServerFailure(:final statusCode) =>
    'The cat service failed ($statusCode). Try again later.',
  UnexpectedResponseFailure() =>
    'The cat service returned something unexpected.',
  UnknownFailure() => 'Something went wrong. Try again.',
};
