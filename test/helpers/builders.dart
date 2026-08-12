import 'dart:convert';

import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

import 'fixture_reader.dart';

/// Builds a `CatBreedModel` with every field defaulted.
///
/// Phase 4 note: this used to carry a long warning that `CatBreedModel !=
/// CatBreedEntity` even with all 40 fields identical (`Equatable.operator ==`
/// compares `runtimeType`), and that since the repository upcast without
/// converting, the objects in `state.listAllCats` were always models — so a
/// builder returning the bare entity would never match an equality assertion.
///
/// **That trap is gone.** The repository now maps explicitly via
/// `CatBreedModel.toEntity()`, so models live in the data layer and entities
/// everywhere above it. Use this builder for data-layer tests and
/// [catBreedEntity] for everything else; there is no longer a way to accidentally
/// compare across the boundary, because the types are unrelated.
CatBreedModel catBreedModel({
  String id = 'abys',
  String name = 'Abyssinian',
  String referenceImageId = '0XYvRd7oD',
  WeightModel weight = const WeightModel(imperial: '7  -  10', metric: '3 - 5'),
  String cfaUrl = 'http://cfa.org/Breeds/BreedsAB/Abyssinian.aspx',
  String vetstreetUrl = 'http://www.vetstreet.com/cats/abyssinian',
  String vcahospitalsUrl =
      'https://vcahospitals.com/know-your-pet/cat-breeds/abyssinian',
  String temperament = 'Active, Energetic, Independent, Intelligent, Gentle',
  String origin = 'Egypt',
  String countryCodes = 'EG',
  String countryCode = 'EG',
  String description = 'The Abyssinian is easy to care for, and a joy to have.',
  String lifeSpan = '14 - 15',
  int indoor = 0,
  int lap = 1,
  String altNames = '',
  int adaptability = 5,
  int affectionLevel = 5,
  int childFriendly = 3,
  int dogFriendly = 4,
  int energyLevel = 5,
  int grooming = 1,
  int healthIssues = 2,
  int intelligence = 5,
  int sheddingLevel = 2,
  int socialNeeds = 5,
  int strangerFriendly = 5,
  int vocalisation = 1,
  int experimental = 0,
  int hairless = 0,
  int natural = 1,
  int rare = 0,
  int rex = 0,
  int suppressedTail = 0,
  int shortLegs = 0,
  String wikipediaUrl = 'https://en.wikipedia.org/wiki/Abyssinian_(cat)',
  int hypoallergenic = 0,
  int catFriendly = 0,
  int bidability = 0,
}) => CatBreedModel(
  weight: weight,
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
  experimental: experimental,
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

/// Builds a `CatBreedEntity` with every field defaulted.
///
/// Delegates to [catBreedModel] and maps, rather than repeating 39 parameters —
/// so the two builders cannot drift apart, and every entity a test uses has been
/// through the real mapper.
///
/// It forwards only the fields tests actually vary; add one here when a test needs
/// it. Dart has no parameter forwarding, and enumerating all 39 twice would be a
/// second place to keep in sync.
CatBreedEntity catBreedEntity({
  String id = 'abys',
  String name = 'Abyssinian',
  String referenceImageId = '0XYvRd7oD',
  String origin = 'Egypt',
  String lifeSpan = '14 - 15',
  String description = 'The Abyssinian is easy to care for, and a joy to have.',
  WeightModel weight = const WeightModel(imperial: '7  -  10', metric: '3 - 5'),
  int intelligence = 5,
  int adaptability = 5,
}) => catBreedModel(
  id: id,
  name: name,
  referenceImageId: referenceImageId,
  origin: origin,
  lifeSpan: lifeSpan,
  description: description,
  weight: weight,
  intelligence: intelligence,
  adaptability: adaptability,
).toEntity();

/// Decodes a breeds fixture into **models**, for data-layer tests.
List<CatBreedModel> modelsFrom(String fixtureName) =>
    (json.decode(fixture(fixtureName)) as List)
        .cast<Map<String, dynamic>>()
        .map(CatBreedModel.fromJson)
        .toList();

/// Decodes a breeds fixture into **entities** — what the repository hands up, and
/// therefore what a bloc state or a widget test should be asserting against.
List<CatBreedEntity> breedsFrom(String fixtureName) =>
    modelsFrom(fixtureName).map((model) => model.toEntity()).toList();

/// The raw maps from a fixture, for `fromJson` tests.
List<Map<String, dynamic>> rawBreedsFrom(String fixtureName) =>
    (json.decode(fixture(fixtureName)) as List).cast<Map<String, dynamic>>();
