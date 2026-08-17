import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tecnical_test_pragma/core/common_widgets/breed_characteristic_widget.dart';
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
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(nameCat, style: theme.textTheme.bodyLarge),
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
            SizedBox(height: 5.h),
            image,
            SizedBox(height: 5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(countryOrigin, style: theme.textTheme.bodyLarge),
                ),
                BreedCharacteristicWidget(
                  width: 190.w,
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
