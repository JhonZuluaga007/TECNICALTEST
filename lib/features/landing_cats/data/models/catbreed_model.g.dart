// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catbreed_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatBreedModel _$CatBreedModelFromJson(Map<String, dynamic> json) =>
    _CatBreedModel(
      weight: json['weight'] == null
          ? const WeightModel()
          : WeightModel.fromJson(json['weight'] as Map<String, dynamic>),
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cfaUrl: json['cfa_url'] as String? ?? '',
      vetstreetUrl: json['vetstreet_url'] as String? ?? '',
      vcahospitalsUrl: json['vcahospitals_url'] as String? ?? '',
      temperament: json['temperament'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      countryCodes: json['country_codes'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      lifeSpan: json['life_span'] as String? ?? '',
      indoor: (json['indoor'] as num?)?.toInt() ?? 0,
      lap: (json['lap'] as num?)?.toInt() ?? 0,
      altNames: json['alt_names'] as String? ?? '',
      adaptability: (json['adaptability'] as num?)?.toInt() ?? 0,
      affectionLevel: (json['affection_level'] as num?)?.toInt() ?? 0,
      childFriendly: (json['child_friendly'] as num?)?.toInt() ?? 0,
      dogFriendly: (json['dog_friendly'] as num?)?.toInt() ?? 0,
      energyLevel: (json['energy_level'] as num?)?.toInt() ?? 0,
      grooming: (json['grooming'] as num?)?.toInt() ?? 0,
      healthIssues: (json['health_issues'] as num?)?.toInt() ?? 0,
      intelligence: (json['intelligence'] as num?)?.toInt() ?? 0,
      sheddingLevel: (json['shedding_level'] as num?)?.toInt() ?? 0,
      socialNeeds: (json['social_needs'] as num?)?.toInt() ?? 0,
      strangerFriendly: (json['stranger_friendly'] as num?)?.toInt() ?? 0,
      vocalisation: (json['vocalisation'] as num?)?.toInt() ?? 0,
      experimental: (json['experimental'] as num?)?.toInt() ?? 0,
      hairless: (json['hairless'] as num?)?.toInt() ?? 0,
      natural: (json['natural'] as num?)?.toInt() ?? 0,
      rare: (json['rare'] as num?)?.toInt() ?? 0,
      rex: (json['rex'] as num?)?.toInt() ?? 0,
      suppressedTail: (json['suppressed_tail'] as num?)?.toInt() ?? 0,
      shortLegs: (json['short_legs'] as num?)?.toInt() ?? 0,
      wikipediaUrl: json['wikipedia_url'] as String? ?? '',
      hypoallergenic: (json['hypoallergenic'] as num?)?.toInt() ?? 0,
      referenceImageId: json['reference_image_id'] as String? ?? '',
      catFriendly: (json['cat_friendly'] as num?)?.toInt() ?? 0,
      bidability: (json['bidability'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CatBreedModelToJson(_CatBreedModel instance) =>
    <String, dynamic>{
      'weight': instance.weight.toJson(),
      'id': instance.id,
      'name': instance.name,
      'cfa_url': instance.cfaUrl,
      'vetstreet_url': instance.vetstreetUrl,
      'vcahospitals_url': instance.vcahospitalsUrl,
      'temperament': instance.temperament,
      'origin': instance.origin,
      'country_codes': instance.countryCodes,
      'country_code': instance.countryCode,
      'description': instance.description,
      'life_span': instance.lifeSpan,
      'indoor': instance.indoor,
      'lap': instance.lap,
      'alt_names': instance.altNames,
      'adaptability': instance.adaptability,
      'affection_level': instance.affectionLevel,
      'child_friendly': instance.childFriendly,
      'dog_friendly': instance.dogFriendly,
      'energy_level': instance.energyLevel,
      'grooming': instance.grooming,
      'health_issues': instance.healthIssues,
      'intelligence': instance.intelligence,
      'shedding_level': instance.sheddingLevel,
      'social_needs': instance.socialNeeds,
      'stranger_friendly': instance.strangerFriendly,
      'vocalisation': instance.vocalisation,
      'experimental': instance.experimental,
      'hairless': instance.hairless,
      'natural': instance.natural,
      'rare': instance.rare,
      'rex': instance.rex,
      'suppressed_tail': instance.suppressedTail,
      'short_legs': instance.shortLegs,
      'wikipedia_url': instance.wikipediaUrl,
      'hypoallergenic': instance.hypoallergenic,
      'reference_image_id': instance.referenceImageId,
      'cat_friendly': instance.catFriendly,
      'bidability': instance.bidability,
    };

_WeightModel _$WeightModelFromJson(Map<String, dynamic> json) => _WeightModel(
  imperial: json['imperial'] as String? ?? '',
  metric: json['metric'] as String? ?? '',
);

Map<String, dynamic> _$WeightModelToJson(_WeightModel instance) =>
    <String, dynamic>{'imperial': instance.imperial, 'metric': instance.metric};
