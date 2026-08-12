import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/weight_cat_entity.dart';

part 'catbreed_model.freezed.dart';
part 'catbreed_model.g.dart';

/// Data model for TheCatAPI's `/v1/breeds` payload.
///
/// Phase 4 changed three things:
///
/// 1. **It no longer extends `CatBreedEntity`.** With inheritance, any change to
///    TheCatAPI's JSON reached the domain for free, and since the repository
///    upcast without converting, the objects travelling in the bloc state were
///    always models. Conversion is now explicit and one-directional:
///    [CatBreedModelMapper.toEntity].
///
/// 2. **`fromMap(json, {required String urlImage})` became `fromJson(json)`.**
///    That `urlImage` parameter was the coupling that tied mapping to the N+1:
///    the datasource could not build a model without first resolving an image.
///
/// 3. **The 39 hand-written `json["x"] ?? default` lines are generated.** The
///    snake_case mapping comes from `field_rename: snake` in `build.yaml`, and
///    `@Default` reproduces the old behaviour exactly — json_serializable emits
///    `json['x'] as String? ?? ''`, which covers a missing key *and* an explicit
///    `null`, both of which occur in the real payload.
@freezed
abstract class CatBreedModel with _$CatBreedModel {
  const factory CatBreedModel({
    // `weight` was the only field the hand-written mapper guarded separately: a
    // payload with `"weight": null` threw a `TypeError` when passing null to a
    // `Map<String, dynamic>` parameter. json_serializable generates the same
    // null check around the nested `fromJson`.
    @Default(WeightModel()) WeightModel weight,
    @Default('') String id,
    @Default('') String name,
    @Default('') String cfaUrl,
    @Default('') String vetstreetUrl,
    @Default('') String vcahospitalsUrl,
    @Default('') String temperament,
    @Default('') String origin,
    @Default('') String countryCodes,
    @Default('') String countryCode,
    @Default('') String description,
    @Default('') String lifeSpan,
    @Default(0) int indoor,
    @Default(0) int lap,
    @Default('') String altNames,
    @Default(0) int adaptability,
    @Default(0) int affectionLevel,
    @Default(0) int childFriendly,
    @Default(0) int dogFriendly,
    @Default(0) int energyLevel,
    @Default(0) int grooming,
    @Default(0) int healthIssues,
    @Default(0) int intelligence,
    @Default(0) int sheddingLevel,
    @Default(0) int socialNeeds,
    @Default(0) int strangerFriendly,
    @Default(0) int vocalisation,
    @Default(0) int experimental,
    @Default(0) int hairless,
    @Default(0) int natural,
    @Default(0) int rare,
    @Default(0) int rex,
    @Default(0) int suppressedTail,
    @Default(0) int shortLegs,
    @Default('') String wikipediaUrl,
    @Default(0) int hypoallergenic,
    @Default('') String referenceImageId,
    @Default(0) int catFriendly,
    @Default(0) int bidability,
  }) = _CatBreedModel;

  factory CatBreedModel.fromJson(Map<String, dynamic> json) =>
      _$CatBreedModelFromJson(json);
}

/// The seam that replaced `class CatBreedModel extends CatBreedEntity`.
///
/// Every field is copied explicitly. That verbosity is the feature: adding a
/// field to the API payload no longer reaches the domain silently, and the one
/// place where the two shapes are reconciled is greppable.
extension CatBreedModelMapper on CatBreedModel {
  CatBreedEntity toEntity() => CatBreedEntity(
    weight: weight.toEntity(),
    id: id,
    name: name,
    cfaUrl: cfaUrl,
    vetstreetUrl: vetstreetUrl,
    vcahospitalsUrl: vcahospitalsUrl,
    temperament: temperament,
    origin: origin,
    countryCodes: countryCodes,
    countryCode: countryCode,
    description: description,
    lifeSpan: lifeSpan,
    indoor: indoor,
    lap: lap,
    altNames: altNames,
    adaptability: adaptability,
    affectionLevel: affectionLevel,
    childFriendly: childFriendly,
    dogFriendly: dogFriendly,
    energyLevel: energyLevel,
    grooming: grooming,
    healthIssues: healthIssues,
    intelligence: intelligence,
    sheddingLevel: sheddingLevel,
    socialNeeds: socialNeeds,
    strangerFriendly: strangerFriendly,
    vocalisation: vocalisation,
    // `this.` is required here, not stylistic: `freezed_annotation` re-exports
    // `package:meta`, whose top-level `const experimental` annotation wins the
    // lexical lookup over this model's getter of the same name.
    experimental: this.experimental,
    hairless: hairless,
    natural: natural,
    rare: rare,
    rex: rex,
    suppressedTail: suppressedTail,
    shortLegs: shortLegs,
    wikipediaUrl: wikipediaUrl,
    hypoallergenic: hypoallergenic,
    referenceImageId: referenceImageId,
    catFriendly: catFriendly,
    bidability: bidability,
  );
}

/// The nested `weight` object.
///
/// `imperial` and `metric` were the only two unchecked dynamic casts into a
/// non-nullable `String` in the whole mapping; `@Default('')` now covers both.
@freezed
abstract class WeightModel with _$WeightModel {
  const factory WeightModel({
    @Default('') String imperial,
    @Default('') String metric,
  }) = _WeightModel;

  factory WeightModel.fromJson(Map<String, dynamic> json) =>
      _$WeightModelFromJson(json);
}

extension WeightModelMapper on WeightModel {
  WeightEntity toEntity() => WeightEntity(imperial: imperial, metric: metric);
}
