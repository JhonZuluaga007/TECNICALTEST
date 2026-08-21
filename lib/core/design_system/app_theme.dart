import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'cats_tokens.dart';
import 'radii.dart';

/// The app's two themes.
///
/// Phase 7. Before it, `MaterialApp.router` passed no theme at all, so every
/// colour and every text style was decided at the call site — `AppCatsColor()`
/// re-instantiated inside ten `build` methods, and a `fontSize` hardcoded at each
/// of the twenty-one places that rendered text.
///
/// **`useMaterial3` is deliberately not passed.** It is not deprecated in 3.44.9,
/// but it already defaults to `true` (`theme_data.dart:1146`), so passing it is
/// noise that reads as if it were doing something.
///
/// **There is no separate typography file either.** The plan called for one;
/// `ThemeData`'s own `fontFamily` applies the family to `textTheme` *and*
/// `primaryTextTheme` (`theme_data.dart:510-512`), so a hand-written `TextTheme`
/// would have been fifteen styles restating the M3 scale in order to change one
/// property of it.
abstract final class AppTheme {
  static ThemeData light() => _build(lightScheme, CatsTokens.light);

  static ThemeData dark() => _build(darkScheme, CatsTokens.dark);

  static ThemeData _build(ColorScheme scheme, CatsTokens tokens) => ThemeData(
    colorScheme: scheme,
    // Bundled as an asset in Phase 7; `google_fonts` used to fetch it at runtime
    // on every screen.
    fontFamily: 'Acme',
    extensions: [tokens],
    // Phase 9. This chrome used to live inside `CardCatWidget`, which meant a
    // global visual decision was owned by one feature's widget and no other
    // `Card` in the app inherited it. `Card` is a Material component whose
    // appearance is *supposed* to come from the theme; the app was declining the
    // contract the framework offers.
    //
    // `CardThemeData`, not `CardTheme` — the latter is the inherited widget, and
    // `ThemeData.cardTheme` takes the data class (`theme_data.dart:1327`).
    //
    // **`margin` is deliberately unset.** `Card`'s own default is
    // `EdgeInsets.all(4)`, and naming it here would be restating the SDK; leaving
    // it is also what keeps this change pixel-identical to the call-site chrome
    // it replaces.
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        // No `width: 1` — that is `BorderSide`'s own default
        // (`borders.dart:71`), so passing it says nothing.
        side: BorderSide(color: scheme.outline),
      ),
    ),
  );
}
