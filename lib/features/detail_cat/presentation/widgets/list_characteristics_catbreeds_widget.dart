import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tecnical_test_pragma/core/common_widgets/breed_characteristic_widget.dart';

/// A single breed characteristic: its label and its value.
typedef BreedCharacteristic = ({String label, int value});

/// List of a breed's characteristics.
///
/// Phase 2: this previously took two parallel lists (a `List<String>` of labels
/// and a `List<int>` of values) indexed together, with the loop bound taken only
/// from the labels list. Adding a label without its value was a runtime
/// `RangeError`, and a longer values list silently dropped the extras — with no
/// constructor validation and no compiler protection.
///
/// With a single list of records the misalignment is unrepresentable.
class ListCharacteristicsCatbreeds extends StatelessWidget {
  const ListCharacteristicsCatbreeds({
    super.key,
    required this.characteristics,
    this.labelStyle,
    this.radius,
  });

  final List<BreedCharacteristic> characteristics;

  /// Phase 7: was `double? fontSize`. Defaults to `bodyLarge`.
  final TextStyle? labelStyle;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final characteristic in characteristics)
          Column(
            children: [
              BreedCharacteristicWidget(
                width: 500.w,
                height: 30,
                radius: radius ?? 10,
                labelStyle: labelStyle ?? Theme.of(context).textTheme.bodyLarge,
                nameCharacteristic: characteristic.label,
                value: characteristic.value,
              ),
              SizedBox(height: 8.h),
            ],
          ),
      ],
    );
  }
}
