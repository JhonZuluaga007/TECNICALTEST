import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';

import '../../../../helpers/builders.dart';

/// Fixtures captured from `https://api.thecatapi.com/v1/breeds` on 2026-08-10.
/// TheCatAPI's payload drifts over time: if `breeds_full.json` goes stale, the
/// last case in this group is what tells you.
void main() {
  group('CatBreedModel.fromMap', () {
    test('maps the full payload of a real breed', () {
      final raw = rawBreedsFrom('breeds_3.json').first;

      final model = CatBreedModel.fromMap(raw, urlImage: 'https://x/y.jpg');

      expect(model.id, 'abys');
      expect(model.name, 'Abyssinian');
      expect(model.urlImage, 'https://x/y.jpg');
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

    test('applies defaults when optional keys are missing', () {
      // `Malayan` carries no cfa_url, vetstreet_url, vcahospitals_url, lap,
      // reference_image_id, cat_friendly or bidability.
      final raw = rawBreedsFrom('breeds_missing_optionals.json').first;

      final model = CatBreedModel.fromMap(raw, urlImage: '');

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
      final raw = rawBreedsFrom('breeds_null_weight.json').first;

      final model = CatBreedModel.fromMap(raw, urlImage: '');

      expect(model.weight, const WeightModel.empty());
      expect(model.weight.imperial, '');
      expect(model.weight.metric, '');
    });

    test('does not throw when imperial and metric are null', () {
      // The only two remaining dynamic casts into a non-nullable `String`.
      final raw = rawBreedsFrom('breeds_weight_null_fields.json').first;

      final model = CatBreedModel.fromMap(raw, urlImage: '');

      expect(model.weight, const WeightModel.empty());
    });

    test('two mappings of the same payload are equal', () {
      final raw = rawBreedsFrom('breeds_3.json').first;

      expect(
        CatBreedModel.fromMap(raw, urlImage: 'https://x/y.jpg'),
        CatBreedModel.fromMap(raw, urlImage: 'https://x/y.jpg'),
      );
    });

    test('urlImage participates in equality', () {
      final raw = rawBreedsFrom('breeds_3.json').first;

      expect(
        CatBreedModel.fromMap(raw, urlImage: 'https://x/y.jpg'),
        isNot(CatBreedModel.fromMap(raw, urlImage: 'https://x/z.jpg')),
      );
    });

    test('a differing field breaks equality', () {
      // Guards against a stubbed `props` such as `=> [id]`.
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
      final models = breedsFrom('breeds_full.json');

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

  group('WeightModel', () {
    test('empty() is a const with both fields blank', () {
      expect(const WeightModel.empty().imperial, '');
      expect(const WeightModel.empty().metric, '');
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
