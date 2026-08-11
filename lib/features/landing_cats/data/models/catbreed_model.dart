import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/weight_cat_entity.dart';

/// Data model for TheCatAPI.
///
/// Phase 2: `fromMap` now takes `urlImage` instead of leaving it as `""` for the
/// datasource to overwrite later, which is what lets the entity be immutable.
/// Phase 4 kills the `Model extends Entity` inheritance in favour of an explicit
/// mapper.
class CatBreedModel extends CatBreedEntity {
  const CatBreedModel({
    required WeightModel super.weight,
    required super.id,
    required super.name,
    required super.urlImage,
    required super.cfaUrl,
    required super.vetstreetUrl,
    required super.vcahospitalsUrl,
    required super.temperament,
    required super.origin,
    required super.countryCodes,
    required super.countryCode,
    required super.description,
    required super.lifeSpan,
    required super.indoor,
    required super.lap,
    required super.altNames,
    required super.adaptability,
    required super.affectionLevel,
    required super.childFriendly,
    required super.dogFriendly,
    required super.energyLevel,
    required super.grooming,
    required super.healthIssues,
    required super.intelligence,
    required super.sheddingLevel,
    required super.socialNeeds,
    required super.strangerFriendly,
    required super.vocalisation,
    required super.experimental,
    required super.hairless,
    required super.natural,
    required super.rare,
    required super.rex,
    required super.suppressedTail,
    required super.shortLegs,
    required super.wikipediaUrl,
    required super.hypoallergenic,
    required super.referenceImageId,
    required super.catFriendly,
    required super.bidability,
  });

  factory CatBreedModel.fromMap(
    Map<String, dynamic> json, {
    required String urlImage,
  }) => CatBreedModel(
    urlImage: urlImage,
    // `weight` was the only field without a null guard: a payload missing that
    // key threw `TypeError` when passing `null` to a `Map<String, dynamic>`
    // parameter.
    weight: json["weight"] == null
        ? const WeightModel.empty()
        : WeightModel.fromMap(json["weight"] as Map<String, dynamic>),
    id: json["id"] ?? "",
    name: json["name"] ?? "",
    cfaUrl: json["cfa_url"] ?? "",
    vetstreetUrl: json["vetstreet_url"] ?? "",
    vcahospitalsUrl: json["vcahospitals_url"] ?? "",
    temperament: json["temperament"] ?? "",
    origin: json["origin"] ?? "",
    countryCodes: json["country_codes"] ?? "",
    countryCode: json["country_code"] ?? "",
    description: json["description"] ?? "",
    lifeSpan: json["life_span"] ?? "",
    indoor: json["indoor"] ?? 0,
    lap: json["lap"] ?? 0,
    altNames: json["alt_names"] ?? "",
    adaptability: json["adaptability"] ?? 0,
    affectionLevel: json["affection_level"] ?? 0,
    childFriendly: json["child_friendly"] ?? 0,
    dogFriendly: json["dog_friendly"] ?? 0,
    energyLevel: json["energy_level"] ?? 0,
    grooming: json["grooming"] ?? 0,
    healthIssues: json["health_issues"] ?? 0,
    intelligence: json["intelligence"] ?? 0,
    sheddingLevel: json["shedding_level"] ?? 0,
    socialNeeds: json["social_needs"] ?? 0,
    strangerFriendly: json["stranger_friendly"] ?? 0,
    vocalisation: json["vocalisation"] ?? 0,
    experimental: json["experimental"] ?? 0,
    hairless: json["hairless"] ?? 0,
    natural: json["natural"] ?? 0,
    rare: json["rare"] ?? 0,
    rex: json["rex"] ?? 0,
    suppressedTail: json["suppressed_tail"] ?? 0,
    shortLegs: json["short_legs"] ?? 0,
    wikipediaUrl: json["wikipedia_url"] ?? "",
    hypoallergenic: json["hypoallergenic"] ?? 0,
    referenceImageId: json["reference_image_id"] ?? "",
    catFriendly: json["cat_friendly"] ?? 0,
    bidability: json["bidability"] ?? 0,
  );
}

class WeightModel extends WeightEntity {
  const WeightModel({required super.imperial, required super.metric});

  const WeightModel.empty() : this(imperial: "", metric: "");

  /// `imperial` and `metric` were unchecked: they were the only two dynamic
  /// casts into a non-nullable `String` in the entire mapping.
  factory WeightModel.fromMap(Map<String, dynamic> json) => WeightModel(
    imperial: (json["imperial"] as String?) ?? "",
    metric: (json["metric"] as String?) ?? "",
  );
}
