import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/search_cat_breeds_use_case.dart';

import '../../../../helpers/builders.dart';

void main() {
  const search = SearchCatBreedsUseCase();

  final breeds = <CatBreedEntity>[
    catBreedEntity(id: 'siam', name: 'Siamese'),
    catBreedEntity(id: 'abob', name: 'American Bobtail'),
    catBreedEntity(id: 'abys', name: 'Abyssinian'),
  ];

  group('SearchCatBreedsUseCase', () {
    test('an empty query returns nothing', () {
      expect(search(breeds, ''), isEmpty);
    });

    test('a whitespace-only query returns nothing', () {
      // The original filter did not `trim()`: "   " matched everything
      // containing a space.
      expect(search(breeds, '   '), isEmpty);
    });

    test('is case-insensitive', () {
      expect(search(breeds, 'siA').map((b) => b.name), ['Siamese']);
      expect(search(breeds, 'SIAMESE').map((b) => b.name), ['Siamese']);
    });

    test('matches by substring, not only by prefix', () {
      expect(search(breeds, 'ame').map((b) => b.name), [
        'Siamese',
        'American Bobtail',
      ]);
    });

    test('trims whitespace from the query', () {
      expect(search(breeds, '  siamese  ').map((b) => b.name), ['Siamese']);
    });

    test('returns empty when there is no match', () {
      expect(search(breeds, 'zzz'), isEmpty);
    });

    test('returns empty when the source list is empty', () {
      expect(search(const [], 'siamese'), isEmpty);
    });

    test('preserves the source list order', () {
      expect(search(breeds, 'a').map((b) => b.id), ['siam', 'abob', 'abys']);
    });

    test('does not mutate the source list', () {
      final original = List<CatBreedEntity>.from(breeds);
      search(breeds, 'siamese');
      expect(breeds, original);
    });
  });
}
