import 'package:freezed_annotation/freezed_annotation.dart';

part 'weight_cat_entity.freezed.dart';

/// A breed's weight, as the two strings TheCatAPI reports (`"7  -  10"`).
///
/// Not parsed into numbers on purpose: the API's own formatting is inconsistent
/// (double spaces, ranges, occasional single values) and the UI only ever
/// displays it. Parsing would be inventing precision the source does not have.
@freezed
abstract class WeightEntity with _$WeightEntity {
  const factory WeightEntity({
    required String imperial,
    required String metric,
  }) = _WeightEntity;
}
