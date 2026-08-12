import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';

import '../../../../helpers/builders.dart';

/// Fixtures captured from `https://api.thecatapi.com/v1/breeds` on 2026-08-10.
/// TheCatAPI's payload drifts over time: if `breeds_full.json` goes stale, the
/// last case in the first group is what tells you.
///
/// Phase 4 replaced the hand-written `fromMap(json, {required String urlImage})`
/// with a generated `fromJson(json)`. Every case below survived that migration
/// unchanged in intent, which is the point: the generated mapper has to reproduce
/// the hand-written one's null handling exactly, and these fixtures — with
/// explicit `null`s, not just missing keys — are what proves it.
void main() {
  group('CatBreedModel.fromJson', () {
    test('maps the full payload of a real breed', () {
      final raw = rawBreedsFrom('breeds_3.json').first;

      final model = CatBreedModel.fromJson(raw);

      expect(model.id, 'abys');
      expect(model.name, 'Abyssinian');
      expect(model.origin, 'Egypt');
      expect(model.countryCode, 'EG');
      expect(model.lifeSpan, '14 - 15');
      expect(model.referenceImageId, '0XYvRd7oD');
      expect(model.intelligence, 5);
      expect(model.adaptability, 5);
      expect(
        model.weight,
        const WeightModel(imperial: '7  -  10', metric: '3 - 5'),
      );
      expect(model.description, contains('Abyssinian'));
      expect(model.temperament, contains('Active'));
      expect(model.wikipediaUrl, startsWith('https://en.wikipedia.org'));
    });

    test('reads snake_case keys, which is the whole build.yaml config', () {
      // `field_rename: snake` is set in one place and applies to 39 fields. If it
      // were dropped, every multi-word key would silently fall back to its
      // `@Default` — a mapper that returns blank data without ever failing, which
      // is the worst possible failure mode. These four are all multi-word.
      final raw = rawBreedsFrom('breeds_3.json').first;

      final model = CatBreedModel.fromJson(raw);

      expect(model.cfaUrl, isNotEmpty, reason: 'cfa_url');
      expect(model.lifeSpan, isNotEmpty, reason: 'life_span');
      expect(model.referenceImageId, isNotEmpty, reason: 'reference_image_id');
      expect(model.affectionLevel, isNot(0), reason: 'affection_level');
    });

    test('applies defaults when optional keys are missing', () {
      // `Malayan` carries no cfa_url, vetstreet_url, vcahospitals_url, lap,
      // reference_image_id, cat_friendly or bidability.
      final raw = rawBreedsFrom('breeds_missing_optionals.json').first;

      final model = CatBreedModel.fromJson(raw);

      expect(model.name, 'Malayan');
      expect(model.cfaUrl, '');
      expect(model.vetstreetUrl, '');
      expect(model.vcahospitalsUrl, '');
      expect(model.lap, 0);
      expect(model.referenceImageId, '');
      expect(model.catFriendly, 0);
      expect(model.bidability, 0);
      // And what is present is preserved.
      expect(model.altNames, 'Asian');
      expect(model.intelligence, 3);
    });

    test('does not throw when weight is null', () {
      // `weight` was the ONLY mapped field with no null guard: this case threw
      // `TypeError` when passing `null` to a `Map<String, dynamic>` parameter.
      // json_serializable generates the same `== null ? default : fromJson(...)`
      // ternary the hand-written mapper had.
      final raw = rawBreedsFrom('breeds_null_weight.json').first;

      final model = CatBreedModel.fromJson(raw);

      expect(model.weight, const WeightModel());
      expect(model.weight.imperial, '');
      expect(model.weight.metric, '');
    });

    test('does not throw when imperial and metric are null', () {
      // The only two remaining dynamic casts into a non-nullable `String`.
      final raw = rawBreedsFrom('breeds_weight_null_fields.json').first;

      final model = CatBreedModel.fromJson(raw);

      expect(model.weight, const WeightModel());
    });

    test('defaults cover an absent key AND an explicit null', () {
      // These are two different code paths in the generator, and only one of them
      // occurs in the live payload today.
      //
      // What TheCatAPI actually sends: `European Burmese` and `Malayan` **omit**
      // `reference_image_id` entirely. Measured — the only key the live response
      // ever sends as `null` is `breed_group`, which this model does not map.
      // `breeds_no_reference_image_id.json` matches that shape.
      final absent = rawBreedsFrom('breeds_no_reference_image_id.json').first;
      expect(absent.containsKey('reference_image_id'), isFalse);
      expect(CatBreedModel.fromJson(absent).referenceImageId, '');

      // And the shape the API could start sending without warning. The
      // hand-written mapper's `json["x"] ?? ""` handled both; `@Default` had to
      // keep doing so, or a future payload change would put `null` into a
      // non-nullable `String`. Verified in json_serializable's generator, which
      // emits `json['x'] as String? ?? ''` — one expression, both cases.
      final explicitNull = {...absent, 'reference_image_id': null};
      expect(CatBreedModel.fromJson(explicitNull).referenceImageId, '');
      expect(CatBreedModel.fromJson({...absent, 'name': null}).name, '');
      expect(
        CatBreedModel.fromJson({...absent, 'intelligence': null}).intelligence,
        0,
      );
    });

    test('two mappings of the same payload are equal', () {
      final raw = rawBreedsFrom('breeds_3.json').first;

      expect(CatBreedModel.fromJson(raw), CatBreedModel.fromJson(raw));
    });

    test('a differing field breaks equality', () {
      expect(
        catBreedModel(intelligence: 5),
        isNot(catBreedModel(intelligence: 4)),
      );
      expect(catBreedModel(name: 'Aegean'), isNot(catBreedModel()));
      expect(
        catBreedModel(
          weight: const WeightModel(imperial: '1', metric: '2'),
        ),
        isNot(catBreedModel()),
      );
    });

    test('decodes all 67 real breeds without throwing', () {
      final models = modelsFrom('breeds_full.json');

      expect(models, hasLength(67));
      expect(models.map((m) => m.id), everyElement(isNotEmpty));
      expect(models.map((m) => m.name), everyElement(isNotEmpty));
      // Exactly 2 breeds carry no reference image.
      expect(
        models.where((m) => m.referenceImageId.isEmpty).map((m) => m.name),
        containsAll(['European Burmese', 'Malayan']),
      );
      expect(models.where((m) => m.referenceImageId.isEmpty), hasLength(2));
    });
  });

  group('CatBreedModel.toJson', () {
    test('round-trips every breed in the real payload', () {
      // Nothing in the app serializes a breed today — `create_to_json` is on
      // because freezed generates `toJson` for any class with a `fromJson`
      // factory, so switching it off means fighting the generator.
      //
      // Rather than leave ~40 generated lines untested with a note saying they are
      // unused, this exercises them, and it buys something concrete: Phase 6 wants
      // to persist cached breeds through `hydrated_bloc`, which needs exactly this
      // round-trip to hold. If a `@JsonKey` or `field_rename` ever stops being
      // symmetric, this is what says so.
      for (final model in modelsFrom('breeds_full.json')) {
        expect(
          CatBreedModel.fromJson(model.toJson()),
          model,
          reason: 'round-trip changed ${model.name}',
        );
      }
    });

    test('writes snake_case keys, matching what fromJson reads', () {
      final json = modelsFrom('breeds_3.json').first.toJson();

      expect(json, containsPair('cfa_url', isNotEmpty));
      expect(json, containsPair('life_span', isNotEmpty));
      expect(json, containsPair('reference_image_id', '0XYvRd7oD'));
      expect(json.keys, isNot(contains('cfaUrl')));
    });

    test('the nested weight survives the round-trip', () {
      final model = catBreedModel(
        weight: const WeightModel(imperial: '7  -  10', metric: '3 - 5'),
      );

      expect(
        CatBreedModel.fromJson(model.toJson()).weight,
        const WeightModel(imperial: '7  -  10', metric: '3 - 5'),
      );
    });
  });

  group('CatBreedModelMapper.toEntity', () {
    test('carries every field across, including the nested weight', () {
      // The seam that replaced `class CatBreedModel extends CatBreedEntity`. With
      // inheritance there was nothing to test — the model *was* the entity. Now
      // there are 39 assignments written by hand, and a forgotten one would ship a
      // blank field rather than fail to compile, so each is checked against the
      // model it came from.
      final model = modelsFrom('breeds_full.json').first;

      final entity = model.toEntity();

      expect(entity.weight.imperial, model.weight.imperial);
      expect(entity.weight.metric, model.weight.metric);
      expect(entity.id, model.id);
      expect(entity.name, model.name);
      expect(entity.cfaUrl, model.cfaUrl);
      expect(entity.vetstreetUrl, model.vetstreetUrl);
      expect(entity.vcahospitalsUrl, model.vcahospitalsUrl);
      expect(entity.temperament, model.temperament);
      expect(entity.origin, model.origin);
      expect(entity.countryCodes, model.countryCodes);
      expect(entity.countryCode, model.countryCode);
      expect(entity.description, model.description);
      expect(entity.lifeSpan, model.lifeSpan);
      expect(entity.indoor, model.indoor);
      expect(entity.lap, model.lap);
      expect(entity.altNames, model.altNames);
      expect(entity.adaptability, model.adaptability);
      expect(entity.affectionLevel, model.affectionLevel);
      expect(entity.childFriendly, model.childFriendly);
      expect(entity.dogFriendly, model.dogFriendly);
      expect(entity.energyLevel, model.energyLevel);
      expect(entity.grooming, model.grooming);
      expect(entity.healthIssues, model.healthIssues);
      expect(entity.intelligence, model.intelligence);
      expect(entity.sheddingLevel, model.sheddingLevel);
      expect(entity.socialNeeds, model.socialNeeds);
      expect(entity.strangerFriendly, model.strangerFriendly);
      expect(entity.vocalisation, model.vocalisation);
      expect(entity.experimental, model.experimental);
      expect(entity.hairless, model.hairless);
      expect(entity.natural, model.natural);
      expect(entity.rare, model.rare);
      expect(entity.rex, model.rex);
      expect(entity.suppressedTail, model.suppressedTail);
      expect(entity.shortLegs, model.shortLegs);
      expect(entity.wikipediaUrl, model.wikipediaUrl);
      expect(entity.hypoallergenic, model.hypoallergenic);
      expect(entity.referenceImageId, model.referenceImageId);
      expect(entity.catFriendly, model.catFriendly);
      expect(entity.bidability, model.bidability);
    });

    test('no field is left at its default when the source has a value', () {
      // The cheap check that catches a whole class of copy-paste slip: if
      // `toEntity` mapped a field to the wrong source, or skipped it, the blank
      // would show up here. `breeds_full.json`'s first breed has every field
      // populated.
      final entity = modelsFrom('breeds_full.json').first.toEntity();

      expect(entity.id, isNotEmpty);
      expect(entity.name, isNotEmpty);
      expect(entity.cfaUrl, isNotEmpty);
      expect(entity.temperament, isNotEmpty);
      expect(entity.wikipediaUrl, isNotEmpty);
      expect(entity.weight.imperial, isNotEmpty);
      expect(entity.intelligence, greaterThan(0));
      expect(entity.adaptability, greaterThan(0));
    });

    test('experimental survives the meta annotation name clash', () {
      // `freezed_annotation` re-exports `package:meta`, whose top-level
      // `const experimental` wins the lexical lookup inside the mapper extension
      // over the model's getter of the same name — so `toEntity` has to write
      // `this.experimental`. Without it the code does not compile, but a future
      // refactor could "fix" the compile error the wrong way, and this is what
      // would catch that.
      expect(catBreedModel(experimental: 1).toEntity().experimental, 1);
      expect(catBreedModel(experimental: 0).toEntity().experimental, 0);
    });
  });

  group('WeightModel', () {
    test('defaults to both fields blank', () {
      expect(const WeightModel().imperial, '');
      expect(const WeightModel().metric, '');
    });

    test('is equal by value', () {
      expect(
        const WeightModel(imperial: '7', metric: '3'),
        const WeightModel(imperial: '7', metric: '3'),
      );
      expect(
        const WeightModel(imperial: '7', metric: '3'),
        isNot(const WeightModel(imperial: '7', metric: '4')),
      );
    });
  });
}
