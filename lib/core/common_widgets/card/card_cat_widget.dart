import 'package:flutter/material.dart';
import 'package:tecnical_test_pragma/core/common_widgets/breed_characteristic_widget.dart';
import 'package:tecnical_test_pragma/core/design_system/spacing.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';

class CardCatWidget extends StatelessWidget {
  const CardCatWidget({
    super.key,
    required this.nameCat,
    required this.image,
    required this.countryOrigin,
    required this.intelligent,
    required this.onPressed,
  });
  final String nameCat;

  /// The image, as a widget slot rather than a URL.
  ///
  /// Phase 4 changed this from `String imageUrlCat`. This card lives in
  /// `core/common_widgets/`, and resolving a breed image now needs a cubit that
  /// belongs to the landing feature — taking a `referenceImageId` here would make
  /// `core/` depend on a feature. A slot keeps the dependency pointing the right
  /// way, and makes the card reusable with any image source.
  final Widget image;
  final String countryOrigin;
  final int intelligent;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      // Phase 7: `color` and `surfaceTintColor` were both pinned to white. A
      // `Card` already takes `colorScheme.surfaceContainerLow` and tints by
      // elevation, which is what makes it legible in dark mode too.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline, width: 1),
      ),
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
                    nameCat,
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
                Text(countryOrigin, style: theme.textTheme.bodyLarge),
                BreedCharacteristicWidget(
                  nameCharacteristic: l10n.intelligenceLabel,
                  value: intelligent,
                  radius: 10,
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
