import 'package:flutter/material.dart';
import 'package:tecnical_test_pragma/core/common_widgets/breed_characteristic_widget.dart';
import 'package:tecnical_test_pragma/core/design_system/spacing.dart';

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final characteristic in characteristics)
          Column(
            children: [
              // Phase 8: the `width: 500.w` that used to be here was wider than
              // any window the app runs in, so it was "as wide as possible"
              // spelled as a number that happened to be big enough. Stretching
              // says it, and stops saying it wrong on a 1440 px desktop window.
              BreedCharacteristicWidget(
                radius: radius ?? 10,
                labelStyle: labelStyle ?? Theme.of(context).textTheme.bodyLarge,
                nameCharacteristic: characteristic.label,
                value: characteristic.value,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
      ],
    );
  }
}
