import 'dart:convert';

import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';

import 'fixture_reader.dart';

/// Builds a `CatBreedModel` with every field defaulted.
///
/// **Returns `CatBreedModel`, never `CatBreedEntity`.** `Equatable.operator ==`
/// compares `runtimeType`, so `CatBreedModel(...) != CatBreedEntity(...)` even
/// with all 40 fields identical. And since the repository upcasts without
/// converting, the runtime elements of `state.listAllCats` are always
/// `CatBreedModel`. If a builder returned the bare entity, no equality assertion
/// would ever match.
CatBreedModel catBreedModel({
  String id = 'abys',
  String name = 'Abyssinian',
  String urlImage = '',
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
  urlImage: urlImage,
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

/// Decodes a breeds fixture into models, all sharing the same `urlImage`.
List<CatBreedModel> breedsFrom(String fixtureName, {String urlImage = ''}) =>
    (json.decode(fixture(fixtureName)) as List)
        .cast<Map<String, dynamic>>()
        .map((raw) => CatBreedModel.fromMap(raw, urlImage: urlImage))
        .toList();

/// The raw maps from a fixture, for `fromMap` tests.
List<Map<String, dynamic>> rawBreedsFrom(String fixtureName) =>
    (json.decode(fixture(fixtureName)) as List).cast<Map<String, dynamic>>();
