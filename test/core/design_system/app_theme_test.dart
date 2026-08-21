import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/design_system/app_colors.dart';
import 'package:tecnical_test_pragma/core/design_system/app_theme.dart';
import 'package:tecnical_test_pragma/core/design_system/cats_tokens.dart';
import 'package:tecnical_test_pragma/core/design_system/radii.dart';

/// WCAG 2.1 relative-contrast ratio between two opaque colours.
///
/// `(L1 + 0.05) / (L2 + 0.05)` with `L1` the lighter of the two. `Color`
/// already exposes `computeLuminance()`, which is the sRGB relative luminance
/// the formula asks for, so there is nothing to hand-roll here beyond the
/// ordering.
double _contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05);
}

void main() {
  group('AppTheme registers CatsTokens', () {
    // `Theme.of(context).cats` uses `!` on purpose (see `cats_tokens.dart`), so
    // a theme built without `extensions:` does not degrade to a fallback colour
    // — it crashes the first widget that reads a rating dot. These two tests are
    // what turn that crash into a failure here instead of somewhere downstream.
    test('the light theme carries the light tokens', () {
      final theme = AppTheme.light();

      expect(theme.extension<CatsTokens>(), isNotNull);
      expect(theme.cats.ratingFilled, CatsTokens.light.ratingFilled);
      expect(theme.cats.ratingEmpty, CatsTokens.light.ratingEmpty);
    });

    test('the dark theme carries the dark tokens', () {
      final theme = AppTheme.dark();

      expect(theme.extension<CatsTokens>(), isNotNull);
      expect(theme.cats.ratingFilled, CatsTokens.dark.ratingFilled);
      expect(theme.cats.ratingEmpty, CatsTokens.dark.ratingEmpty);
    });

    test('the two themes do not share one token set', () {
      // The pair is deliberately darkened rather than reused: on a dark surface
      // both light values read as "filled", so the meter would stop meaning
      // anything. Registering `CatsTokens.light` on both themes would compile,
      // pass the two tests above, and lose exactly that.
      expect(
        AppTheme.dark().cats.ratingFilled,
        isNot(AppTheme.light().cats.ratingFilled),
      );
    });
  });

  group('AppTheme brightness and contrast', () {
    test('the light theme is light and its body copy is legible', () {
      final theme = AppTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(
        _contrastRatio(theme.colorScheme.onSurface, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
        reason: 'WCAG AA for normal-sized text',
      );
    });

    test('the dark theme is dark and its body copy is legible', () {
      // The mutation this exists for: `AppTheme.dark()` built from
      // `lightScheme`. It is invisible in a unit test that only checks contrast
      // — the light scheme is internally consistent — and in the app it shows up
      // as a white screen flashing at a user in a dark room.
      final theme = AppTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(
        _contrastRatio(theme.colorScheme.onSurface, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
        reason: 'WCAG AA for normal-sized text',
      );
    });
  });

  group('AppTheme card chrome', () {
    /// The `BorderSide` a theme's `cardTheme` paints.
    BorderSide sideOf(ThemeData theme) =>
        (theme.cardTheme.shape! as RoundedRectangleBorder).side;

    test('both themes configure a card theme', () {
      // Phase 9 moved this chrome out of the breed card and into the theme. If
      // it is absent, every `Card` silently falls back to the M3 default — no
      // outline at all — which is a visual regression no widget test asserts on
      // directly.
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        expect(theme.cardTheme.elevation, 2);
        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      }
    });

    test('the card corner comes from the radius scale', () {
      expect(
        (AppTheme.light().cardTheme.shape! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.circular(AppRadius.md),
      );
    });

    test('each theme outlines its card with its own scheme', () {
      // The available mistake is the same one the token tests guard against:
      // building the dark `cardTheme` from `lightScheme` compiles, looks fine in
      // isolation, and draws a light-grey outline on a dark surface.
      expect(sideOf(AppTheme.light()).color, lightScheme.outline);
      expect(sideOf(AppTheme.dark()).color, darkScheme.outline);
      expect(
        sideOf(AppTheme.dark()).color,
        isNot(sideOf(AppTheme.light()).color),
      );
    });

    test('the card border keeps the SDK default width', () {
      // Phase 9 deleted three explicit `width: 1`s. This pins that the deletion
      // was a no-op rather than a change nobody noticed.
      expect(sideOf(AppTheme.light()).width, 1.0);
    });
  });
}
