import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tecnical_test_pragma/features/settings/presentation/bloc/theme_mode_cubit.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';

/// The only affordance for the theme, deliberately one button rather than a
/// settings screen.
///
/// Phase 7. Dark mode with no control is invisible to a user whose device is in
/// light mode, which is most of them — and the roadmap does not have a settings
/// screen on it.
///
/// Its own widget, and `const`, so cycling the theme rebuilds this icon rather
/// than the whole page and its list.
///
/// Phase 9 moved it out of `landing_page.dart`, where it was private. It is the
/// settings feature's only UI, and it was living inside another feature's page
/// file — the inverse of the misplacements the rest of this phase fixed. Being
/// public is what finally makes it testable: the theme toggle had **no**
/// coverage at all while it was a private class.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeModeCubit, ThemeMode>(
      builder: (context, mode) => IconButton(
        tooltip: AppLocalizations.of(context).toggleTheme,
        onPressed: context.read<ThemeModeCubit>().cycle,
        icon: Icon(switch (mode) {
          ThemeMode.system => Icons.brightness_auto_outlined,
          ThemeMode.light => Icons.light_mode_outlined,
          ThemeMode.dark => Icons.dark_mode_outlined,
        }),
      ),
    );
  }
}
