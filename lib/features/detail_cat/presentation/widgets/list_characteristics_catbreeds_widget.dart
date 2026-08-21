import 'package:flutter/material.dart';
import 'package:tecnical_test_pragma/core/common_widgets/rating_meter.dart';
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
    this.dotRadius,
  });

  final List<BreedCharacteristic> characteristics;

  /// Phase 7: was `double? fontSize`. Defaults to `bodyLarge`.
  final TextStyle? labelStyle;

  /// Forwarded to [RatingMeter], which owns the default. Phase 9: this used to
  /// pass `radius ?? 10`, restating a default the meter already applies.
  final double? dotRadius;

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
              RatingMeter(
                dotRadius: dotRadius,
                labelStyle: labelStyle ?? Theme.of(context).textTheme.bodyLarge,
                label: characteristic.label,
                value: characteristic.value,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
      ],
    );
  }
}
