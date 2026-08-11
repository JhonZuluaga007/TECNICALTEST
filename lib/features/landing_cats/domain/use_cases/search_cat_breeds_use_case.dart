import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

/// Filters breeds by name.
///
/// This was the only real business logic in the project, and it lived duplicated
/// literally (same code, different lambda name) across `buildResults` and
/// `buildSuggestions` in the search delegate. Here it is a pure, testable
/// function.
///
/// It also fixes the original filter's missing `trim()`.
///
/// It is deliberately not registered in the DI container: it has no
/// dependencies, and registering it would force every search-delegate widget
/// test to call `Injector.setup()`. It is injected with a default value instead.
class SearchCatBreedsUseCase {
  const SearchCatBreedsUseCase();

  List<CatBreedEntity> call(List<CatBreedEntity> all, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    return all
        .where((breed) => breed.name.toLowerCase().contains(normalized))
        .toList(growable: false);
  }
}
