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
      expect(catBreedEntity(), catBreedEntity());
      expect(catBreedEntity().hashCode, catBreedEntity().hashCode);
    });

    test('differs by id', () {
      expect(catBreedEntity(id: 'abys'), isNot(catBreedEntity(id: 'aege')));
    });

    test('differs by the nested weight', () {
      // Proves two things at once: that `weight` participates in equality, and
      // that `WeightEntity` has value equality of its own (otherwise comparing
      // two distinct instances would always fail).
      expect(
        catBreedEntity(
          weight: const WeightModel(imperial: '7', metric: '3'),
        ),
        isNot(
          catBreedEntity(
            weight: const WeightModel(imperial: '9', metric: '3'),
          ),
        ),
      );
    });

    test('equality covers fields no test varies by hand', () {
      // Phase 2 wrote `props` by hand across 40 fields with a comment saying a
      // partial list would hide exactly the regressions Phase 4 might introduce.
      // freezed generates `==` from the constructor, so it cannot be partial —
      // but that is a claim about the generator, and this checks it on a field
      // nothing else in the suite touches.
      expect(
        catBreedModel(bidability: 3).toEntity(),
        isNot(catBreedModel(bidability: 4).toEntity()),
      );
    });

    test('a model is not assignable to an entity', () {
      // The replacement for Phase 2's canary test, which asserted that
      // `CatBreedModel != CatBreedEntity` despite having all 40 fields identical
      // (`Equatable.operator ==` compares `runtimeType`). That asymmetry was a
      // consequence of `CatBreedModel extends CatBreedEntity` plus a repository
      // that upcast without converting, so the objects in the bloc state were
      // always models.
      //
      // Phase 4 removed the inheritance, so the two types are now unrelated and
      // the assertion is a **compile-time** one: the `isNot` below still holds,
      // but what actually matters is that this file could not pass a
      // `CatBreedModel` where a `CatBreedEntity` is expected even if it tried.
      expect(catBreedModel(), isA<CatBreedModel>());
      expect(catBreedModel(), isNot(isA<CatBreedEntity>()));
      expect(catBreedEntity(), isA<CatBreedEntity>());
      expect(catBreedEntity(), isNot(isA<CatBreedModel>()));
    });

    test('urlImage is gone from the domain', () {
      // It was a data-layer artifact in the domain entity, and holding it is what
      // forced the datasource to resolve 65 image URLs before the first frame.
      // `referenceImageId` is what remains, and `BreedImage` resolves it lazily.
      expect(catBreedEntity().referenceImageId, '0XYvRd7oD');
      // The compile-time half: `catBreedEntity().urlImage` does not exist. If it
      // came back, `landing_page.dart` could go straight back to N+1.
      expect(
        catBreedEntity().toString(),
        isNot(contains('urlImage')),
        reason: 'freezed toString lists every field',
      );
    });
  });
}
