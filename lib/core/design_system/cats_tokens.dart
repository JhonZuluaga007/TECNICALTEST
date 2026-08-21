import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The colours this app needs that Material 3 has no role for.
///
/// Only the five-dot rating meter in `RatingMeter` qualifies. A
/// filled dot is not `primary` — `primary` is for the things the user acts on,
/// and these dots are a read-only measure — and an empty dot is not
/// `surfaceContainerHighest` either, because the pair has to stay legible against
/// each other rather than against the surface. Forcing them into M3 roles would
/// have meant picking roles by colour rather than by meaning, which is how a
/// design system stops being one.
///
/// Everything else in the old `AppCatsColor` **did** have a role and was mapped to
/// it; this extension exists precisely so that the leftovers are a short, named,
/// theme-aware list instead of an untyped `Map<String, Color>`.
@immutable
final class CatsTokens extends ThemeExtension<CatsTokens> {
  const CatsTokens({required this.ratingFilled, required this.ratingEmpty});

  /// A dot below the breed's score for a characteristic.
  ///
  /// The light value is the exact colour the app already used
  /// (`AppCatsColor.mapColors["LigthGreen"]`, typo included).
  final Color ratingFilled;

  /// A dot above the breed's score. Light value: the former `"LigthGrey"`.
  final Color ratingEmpty;

  static const CatsTokens light = CatsTokens(
    ratingFilled: kSeedColor,
    ratingEmpty: Color(0xFFE1DFDF),
  );

  /// Darkened rather than reused: the light pair is two high-luminance colours,
  /// and on a dark surface both would read as "filled".
  static const CatsTokens dark = CatsTokens(
    ratingFilled: Color(0xFF4C7A4E),
    ratingEmpty: Color(0xFF3A3A3A),
  );

  @override
  CatsTokens copyWith({Color? ratingFilled, Color? ratingEmpty}) => CatsTokens(
    ratingFilled: ratingFilled ?? this.ratingFilled,
    ratingEmpty: ratingEmpty ?? this.ratingEmpty,
  );

  /// Required by [ThemeExtension]. Without it an animated theme switch would jump
  /// these two colours while every other colour on screen interpolates.
  @override
  CatsTokens lerp(ThemeExtension<CatsTokens>? other, double t) {
    if (other is! CatsTokens) return this;
    return CatsTokens(
      ratingFilled: Color.lerp(ratingFilled, other.ratingFilled, t)!,
      ratingEmpty: Color.lerp(ratingEmpty, other.ratingEmpty, t)!,
    );
  }
}

/// Reads the tokens off the current theme.
///
/// The `!` is deliberate. A widget pumped without the app's `ThemeData` — which
/// in practice means a test harness that forgot it — crashes on the spot in the
/// test that did it, instead of silently rendering a fallback colour and passing.
/// `AppTheme` registers the extension on both themes and there is a test for it.
extension CatsTokensX on ThemeData {
  CatsTokens get cats => extension<CatsTokens>()!;
}
