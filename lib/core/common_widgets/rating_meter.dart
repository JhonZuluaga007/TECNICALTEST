import 'package:flutter/material.dart';
import 'package:tecnical_test_pragma/core/design_system/cats_tokens.dart';
import 'package:tecnical_test_pragma/core/design_system/spacing.dart';

/// A labelled five-dot rating meter.
///
/// Phase 7 replaced the `double? fontSize` parameter with [labelStyle]. The old
/// one existed so the two call sites could render the label at different sizes
/// (20 in a card, 18 in the detail list), which meant every caller had to know a
/// number. They now pass a role off the `TextTheme` and the numbers live in one
/// place.
///
/// Phase 8 removed `width` and `height`, and this is the widget the phase was
/// really about. Measured with the real Acme font that Phase 7 bundled:
/// `Text('Intelligence:')` at `titleLarge` is **107.6 px** at text scale 1.0,
/// 161.3 at 1.5 and **215.1 at 2.0** — against the `SizedBox(width: 190.w)`
/// `BreedCard` used to impose. So at the largest accessibility text size the
/// label alone did not fit, and the card overflowed by 37 px. That was a real
/// layout bug, not the font-metrics artifact the previous phases were working
/// around.
///
/// It now sizes to its content and lets the caller decide the constraint:
///
/// - the label is [Flexible] and ellipsizes rather than overflowing;
/// - the dots are a `Row` with `mainAxisSize.min`, not a horizontal `ListView`.
///   Five dots at radius 10 measure 116 px and always fit, so the scrollable
///   bought nothing — and it cost a `ScrollPosition` per card in a list of 67.
///
/// Phase 9 renamed it from `BreedCharacteristicWidget`. Nothing about it is
/// breed-specific — it draws a label and `value` filled dots out of five — and
/// the old name was the only thing tying a `core/` widget to the cat domain.
class RatingMeter extends StatelessWidget {
  const RatingMeter({
    super.key,
    required this.label,
    required this.value,
    this.dotRadius,
    this.labelStyle,
  });

  final String label;
  final int value;

  /// Defaults to 10, and that default lives **here only**. Phase 9 removed a
  /// second `?? 10` from `ListCharacteristicsCatbreeds`, which meant changing
  /// the dot size took two edits and silently disagreed if you made one.
  final double? dotRadius;

  /// Defaults to `titleLarge`.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The one pair of colours in this app with no Material 3 role: a filled and
    // an empty dot have to stay legible against each other, not against the
    // surface. See `CatsTokens`.
    final tokens = theme.cats;
    final radius = dotRadius ?? 10;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: labelStyle ?? theme.textTheme.titleLarge,
            // The label is the part that grows with the user's text size, so it
            // is the part that gives way. Truncating a label the dots explain is
            // better than clipping the dots, which carry the actual value.
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        for (var index = 0; index < 5; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.xs),
          CircleAvatar(
            radius: radius,
            backgroundColor: value > index
                ? tokens.ratingFilled
                : tokens.ratingEmpty,
          ),
        ],
      ],
    );
  }
}
