// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/weight_cat_entity.dart';

/// Domain entity for a cat breed.
///
/// Phase 2: became `Equatable` so the bloc state can be compared by value in
/// tests, and `urlImage` went from `late String` to `final String`. That `late`
/// bought nothing for deferred initialization (the constructor already required
/// the field): it existed purely so the datasource could overwrite it after
/// construction, i.e. to mutate a domain entity. The datasource now resolves the
/// URL *before* building the model.
///
/// Phase 4 replaces this class with a freezed-generated one.
class CatBreedEntity extends Equatable {
  const CatBreedEntity({
    required this.weight,
    required this.id,
    required this.name,
    required this.cfaUrl,
    required this.urlImage,
    required this.vetstreetUrl,
    required this.vcahospitalsUrl,
    required this.temperament,
    required this.origin,
    required this.countryCodes,
    required this.countryCode,
    required this.description,
    required this.lifeSpan,
    required this.indoor,
    required this.lap,
    required this.altNames,
    required this.adaptability,
    required this.affectionLevel,
    required this.childFriendly,
    required this.dogFriendly,
    required this.energyLevel,
    required this.grooming,
    required this.healthIssues,
    required this.intelligence,
    required this.sheddingLevel,
    required this.socialNeeds,
    required this.strangerFriendly,
    required this.vocalisation,
    required this.experimental,
    required this.hairless,
    required this.natural,
    required this.rare,
    required this.rex,
    required this.suppressedTail,
    required this.shortLegs,
    required this.wikipediaUrl,
    required this.hypoallergenic,
    required this.referenceImageId,
    required this.catFriendly,
    required this.bidability,
  });

  final WeightEntity weight;
  final String id;
  final String name;
  final String cfaUrl;
  final String urlImage;
  final String vetstreetUrl;
  final String vcahospitalsUrl;
  final String temperament;
  final String origin;
  final String countryCodes;
  final String countryCode;
  final String description;
  final String lifeSpan;
  final int indoor;
  final int lap;
  final String altNames;
  final int adaptability;
  final int affectionLevel;
  final int childFriendly;
  final int dogFriendly;
  final int energyLevel;
  final int grooming;
  final int healthIssues;
  final int intelligence;
  final int sheddingLevel;
  final int socialNeeds;
  final int strangerFriendly;
  final int vocalisation;
  final int experimental;
  final int hairless;
  final int natural;
  final int rare;
  final int rex;
  final int suppressedTail;
  final int shortLegs;
  final String wikipediaUrl;
  final int hypoallergenic;
  final String referenceImageId;
  final int catFriendly;
  final int bidability;

  /// All 40 fields, on purpose. A partial `props` would hide exactly the
  /// regressions Phase 4 might introduce when moving to freezed.
  @override
  List<Object?> get props => [
    weight,
    id,
    name,
    cfaUrl,
    urlImage,
    vetstreetUrl,
    vcahospitalsUrl,
    temperament,
    origin,
    countryCodes,
    countryCode,
    description,
    lifeSpan,
    indoor,
    lap,
    altNames,
    adaptability,
    affectionLevel,
    childFriendly,
    dogFriendly,
    energyLevel,
    grooming,
    healthIssues,
    intelligence,
    sheddingLevel,
    socialNeeds,
    strangerFriendly,
    vocalisation,
    experimental,
    hairless,
    natural,
    rare,
    rex,
    suppressedTail,
    shortLegs,
    wikipediaUrl,
    hypoallergenic,
    referenceImageId,
    catFriendly,
    bidability,
  ];
}
