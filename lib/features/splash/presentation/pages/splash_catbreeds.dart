import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tecnical_test_pragma/cats_icons.dart';
import 'package:tecnical_test_pragma/core/common_widgets/app_scaffold.dart';
import 'package:tecnical_test_pragma/core/design_system/spacing.dart';
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
    return AppScaffold(
      // Phase 7: both of these were pinned to white, which on a dark device gave
      // a white splash followed by a dark app.
      backgroundColor: theme.colorScheme.surface,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      paddingColumn: const EdgeInsets.all(AppSpacing.md),
      bottomSheet: Container(
        color: theme.colorScheme.surface,
        // Phase 8: was `width: 200.w`, i.e. 200 px on a 390 px phone and 738 px
        // on a 1440 px desktop window — the cat grew with the window while
        // `height: 300` did not, so the image distorted as the window widened.
        // A `FractionallySizedBox` says "half the width" and keeps the aspect
        // ratio the asset was drawn with.
        child: FractionallySizedBox(
          widthFactor: 0.5,
          child: Image.asset(CatsIcons.imageCatSplash, height: 300),
        ),
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
        const SizedBox(height: 170),
      ],
    );
  }
}
