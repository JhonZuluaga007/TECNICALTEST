import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

part 'breeds_snapshot.freezed.dart';

/// A list of breeds, plus how much you should trust it.
///
/// New in Phase 6, and it exists because "here are the breeds" stopped being the
/// whole answer once there was a cache. The repository can now hand back a list it
/// could not refresh, and the UI has to be able to tell the difference — that is
/// the entire reason the `CatsStale` state variant exists.
///
/// [breeds] is declared on **both** constructors, so freezed exposes it on the
/// sealed base and `snapshot.breeds` reads without a `switch`. Same mechanism the
/// landing state uses for `searchHistory`.
@freezed
sealed class BreedsSnapshot with _$BreedsSnapshot {
  /// Served from the network, or from a cache still inside its TTL.
  const factory BreedsSnapshot.fresh({required List<CatBreedEntity> breeds}) =
      FreshBreeds;

  /// Served from an expired cache, because the refresh failed.
  ///
  /// [failure] is why it could not be refreshed. It travels with the data instead
  /// of replacing it: the app has a perfectly usable list of cat breeds, and
  /// throwing that away to show an error screen — which is what happened before
  /// Phase 6 — is strictly worse for the user than showing it with a notice.
  const factory BreedsSnapshot.stale({
    required List<CatBreedEntity> breeds,
    required CatsFailure failure,
  }) = StaleBreeds;
}
