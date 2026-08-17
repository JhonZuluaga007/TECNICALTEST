import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:tecnical_test_pragma/cats_icons.dart';
import 'package:tecnical_test_pragma/core/common_widgets/my_app_scaffold.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';
import 'package:tecnical_test_pragma/routers/routers.dart';

class SplashCatBreeds extends StatefulWidget {
  const SplashCatBreeds({super.key});

  @override
  State<SplashCatBreeds> createState() => _SplashCatBreedsState();
}

class _SplashCatBreedsState extends State<SplashCatBreeds> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // The `Timer? timer` field existed but was NEVER assigned: `startTimer()`
    // was pointlessly `async` and returned the `Timer` inside a `Future` nobody
    // read. So the timer stayed alive with no reference, impossible to cancel.
    _timer = Timer(const Duration(seconds: 5), _goToHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToHome() {
    // Without this guard, leaving the splash before the 5 s elapsed called
    // `goNamed` on an already-unmounted `State.context`.
    if (!mounted) return;
    context.goNamed(homePage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MyAppScaffold(
      // Phase 7: both of these were pinned to white, which on a dark device gave
      // a white splash followed by a dark app.
      backgroundColor: theme.colorScheme.surface,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      paddingColumn: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      bottomSheet: Container(
        color: theme.colorScheme.surface,
        child: Image.asset(CatsIcons.imageCatSplash, width: 200.w, height: 300),
      ),
      children: [
        Center(
          child: Text(
            AppLocalizations.of(context).appTitle,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 170.h),
      ],
    );
  }
}
