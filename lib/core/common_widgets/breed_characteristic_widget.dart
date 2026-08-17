import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tecnical_test_pragma/core/design_system/cats_tokens.dart';

/// A labelled five-dot rating meter.
///
/// Phase 7 replaced the `double? fontSize` parameter with [labelStyle]. The old
/// one existed so the two call sites could render the label at different sizes
/// (20 in a card, 18 in the detail list), which meant every caller had to know a
/// number. They now pass a role off the `TextTheme` and the numbers live in one
/// place.
class BreedCharacteristicWidget extends StatelessWidget {
  const BreedCharacteristicWidget({
    super.key,
    required this.nameCharacteristic,
    required this.value,
    this.width,
    this.height,
    this.radius,
    this.labelStyle,
  });

  final String nameCharacteristic;
  final int value;
  final double? width;
  final double? height;
  final double? radius;

  /// Defaults to `titleLarge`.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The one pair of colours in this app with no Material 3 role: a filled and
    // an empty dot have to stay legible against each other, not against the
    // surface. See `CatsTokens`.
    final tokens = theme.cats;

    return SizedBox(
      width: width ?? 200.w,
      height: height ?? 60.h,
      child: Row(
        children: [
          Text(
            nameCharacteristic,
            style: labelStyle ?? theme.textTheme.titleLarge,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return CircleAvatar(
                  radius: radius ?? 20,
                  backgroundColor: value > index
                      ? tokens.ratingFilled
                      : tokens.ratingEmpty,
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(width: 5.w);
              },
            ),
          ),
        ],
      ),
    );
  }
}
