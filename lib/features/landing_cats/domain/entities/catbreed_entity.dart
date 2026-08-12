import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/weight_cat_entity.dart';

part 'catbreed_entity.freezed.dart';

/// Domain entity for a cat breed.
///
/// Phase 2 made it `Equatable` (so bloc state could be compared by value in
/// tests) and turned `urlImage` from `late String` into `final String`. That
/// `late` bought nothing for deferred initialization — the constructor already
/// required the field — it existed purely so the datasource could overwrite it
/// after construction, i.e. to mutate a domain entity.
///
/// Phase 4 changed two things:
///
/// 1. **`freezed` replaces `Equatable`.** The 40-line hand-written `props` list
///    is gone; `==`/`hashCode` cover every field because they are generated from
///    the constructor, which is what that list was trying to guarantee by hand.
///
/// 2. **`urlImage` is gone.** It was a data-layer artifact sitting in the domain:
///    the entity has no business knowing there is a CDN, and holding the resolved
///    URL is precisely what forced the datasource to make 65 extra requests
///    before the first frame. What stays is [referenceImageId] — the identifier
///    the API gives us — and resolving it to a URL is now the presentation
///    layer's problem, done lazily per card. See `BreedImage`.
///
/// This class is also no longer the parent of `CatBreedModel`. See
/// `CatBreedModelMapper.toEntity`.
@freezed
abstract class CatBreedEntity with _$CatBreedEntity {
  const factory CatBreedEntity({
    required WeightEntity weight,
    required String id,
    required String name,
    required String cfaUrl,
    required String vetstreetUrl,
    required String vcahospitalsUrl,
    required String temperament,
    required String origin,
    required String countryCodes,
    required String countryCode,
    required String description,
    required String lifeSpan,
    required int indoor,
    required int lap,
    required String altNames,
    required int adaptability,
    required int affectionLevel,
    required int childFriendly,
    required int dogFriendly,
    required int energyLevel,
    required int grooming,
    required int healthIssues,
    required int intelligence,
    required int sheddingLevel,
    required int socialNeeds,
    required int strangerFriendly,
    required int vocalisation,
    required int experimental,
    required int hairless,
    required int natural,
    required int rare,
    required int rex,
    required int suppressedTail,
    required int shortLegs,
    required String wikipediaUrl,
    required int hypoallergenic,
    required String referenceImageId,
    required int catFriendly,
    required int bidability,
  }) = _CatBreedEntity;
}
