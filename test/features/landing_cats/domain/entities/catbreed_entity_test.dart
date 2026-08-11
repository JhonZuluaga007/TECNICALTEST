import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/weight_cat_entity.dart';

import '../../../../helpers/builders.dart';

void main() {
  group('WeightEntity', () {
    test('is equal by value', () {
      expect(
        const WeightEntity(imperial: '7', metric: '3'),
        const WeightEntity(imperial: '7', metric: '3'),
      );
      expect(
        const WeightEntity(imperial: '7', metric: '3'),
        isNot(const WeightEntity(imperial: '8', metric: '3')),
      );
    });
  });

  group('CatBreedEntity', () {
    test('two instances with the same fields are equal', () {
      expect(catBreedModel(), catBreedModel());
      expect(catBreedModel().hashCode, catBreedModel().hashCode);
    });

    test('differs by id', () {
      expect(catBreedModel(id: 'abys'), isNot(catBreedModel(id: 'aege')));
    });

    test('differs by the nested weight', () {
      // Proves two things at once: that `weight` is in the props, and that
      // `WeightEntity` has value equality of its own (otherwise comparing two
      // distinct instances would always fail).
      expect(
        catBreedModel(
          weight: const WeightModel(imperial: '7', metric: '3'),
        ),
        isNot(
          catBreedModel(
            weight: const WeightModel(imperial: '9', metric: '3'),
          ),
        ),
      );
    });

    test('differs by urlImage', () {
      expect(
        catBreedModel(urlImage: 'https://x/a.jpg'),
        isNot(catBreedModel(urlImage: 'https://x/b.jpg')),
      );
    });

    test('a model is NOT equal to an entity with the same 40 fields', () {
      // `Equatable.operator ==` compares `runtimeType`, so
      // `CatBreedModel != CatBreedEntity` even with identical fields.
      //
      // This matters across the whole suite: the repository upcasts the models to
      // `List<CatBreedEntity>` without converting them, so the runtime elements
      // of the bloc state are ALWAYS `CatBreedModel`. That is why every builder
      // returns models. And this test is the canary for Phase 4, when
      // `Model extends Entity` goes away.
      final model = catBreedModel();
      final entity = CatBreedEntity(
        weight: model.weight,
        id: model.id,
        name: model.name,
        urlImage: model.urlImage,
        cfaUrl: model.cfaUrl,
        vetstreetUrl: model.vetstreetUrl,
        vcahospitalsUrl: model.vcahospitalsUrl,
        temperament: model.temperament,
        origin: model.origin,
        countryCodes: model.countryCodes,
        countryCode: model.countryCode,
        description: model.description,
        lifeSpan: model.lifeSpan,
        indoor: model.indoor,
        lap: model.lap,
        altNames: model.altNames,
        adaptability: model.adaptability,
        affectionLevel: model.affectionLevel,
        childFriendly: model.childFriendly,
        dogFriendly: model.dogFriendly,
        energyLevel: model.energyLevel,
        grooming: model.grooming,
        healthIssues: model.healthIssues,
        intelligence: model.intelligence,
        sheddingLevel: model.sheddingLevel,
        socialNeeds: model.socialNeeds,
        strangerFriendly: model.strangerFriendly,
        vocalisation: model.vocalisation,
        experimental: model.experimental,
        hairless: model.hairless,
        natural: model.natural,
        rare: model.rare,
        rex: model.rex,
        suppressedTail: model.suppressedTail,
        shortLegs: model.shortLegs,
        wikipediaUrl: model.wikipediaUrl,
        hypoallergenic: model.hypoallergenic,
        referenceImageId: model.referenceImageId,
        catFriendly: model.catFriendly,
        bidability: model.bidability,
      );

      expect(model, isNot(entity));
      expect(model.props, entity.props);
    });
  });
}
