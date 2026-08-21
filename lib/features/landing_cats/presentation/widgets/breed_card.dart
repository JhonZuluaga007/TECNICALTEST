import 'package:flutter/material.dart';
import 'package:tecnical_test_pragma/core/common_widgets/rating_meter.dart';
import 'package:tecnical_test_pragma/core/design_system/spacing.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';

/// One breed, as it appears in the landing list and in search results.
///
/// Phase 9 moved it down here from `core/common_widgets/`, where it was called
/// `CardCatWidget`. It was never cross-cutting: both call sites are in this
/// feature, and the widget reaches for `l10n.moreAction` and
/// `l10n.intelligenceLabel` itself, so it could only ever render *this* card.
class BreedCard extends StatelessWidget {
  const BreedCard({
    super.key,
    required this.name,
    required this.image,
    required this.origin,
    required this.intelligence,
    required this.onPressed,
  });
  final String name;

  /// The image, as a widget slot rather than a URL.
  ///
  /// Phase 4 changed this from `String imageUrlCat` to keep `core/` from
  /// depending on a feature. That reason died with Phase 9's move, but the slot
  /// stays for a second one that outlived it: taking a `referenceImageId` would
  /// make every widget test that paints a card provide a `RepositoryProvider`
  /// and a `GetBreedImageUseCase`, and the most valuable test in this file is
  /// the Phase 8 overflow regression, which pumps the card with a cheap
  /// stand-in at text scale 2.0.
  final Widget image;
  final String origin;
  final int intelligence;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Phase 7: `color` and `surfaceTintColor` were both pinned to white. A
    // `Card` already takes `colorScheme.surfaceContainerLow` and tints by
    // elevation, which is what makes it legible in dark mode too.
    //
    // Phase 9: `elevation` and `shape` are gone from here too. They were a
    // global decision written inside one feature's widget; they now come from
    // `ThemeData.cardTheme`.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // `Expanded`, not a bare `Text`: Phase 8 measured this row
                // overflowing at text scale 2.0 once the real font was loaded.
                // The name is the flexible half — the action label is short and
                // fixed, and a truncated button reads as broken.
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  // The `overlayColor` override is gone: it forced a light-grey
                  // ripple that would have stayed light grey on a dark surface,
                  // and the default is derived from the button's own foreground.
                  onPressed: onPressed,
                  // No explicit style: `TextButton` already renders its label as
                  // `labelLarge`.
                  child: Text(l10n.moreAction),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            image,
            const SizedBox(height: AppSpacing.sm),
            // A `Wrap`, not a `Row`. Measured: at text scale 2.0 the origin plus
            // the intelligence meter need more than the 358 px a 390 px-wide card
            // has left after padding, which is exactly the 37 px overflow this
            // phase set out to fix. `Wrap` moves the meter onto its own line
            // instead of clipping it, with no breakpoint and no magic threshold —
            // it reacts to the text size the user actually chose.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                Text(origin, style: theme.textTheme.bodyLarge),
                RatingMeter(
                  label: l10n.intelligenceLabel,
                  value: intelligence,
                  labelStyle: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
