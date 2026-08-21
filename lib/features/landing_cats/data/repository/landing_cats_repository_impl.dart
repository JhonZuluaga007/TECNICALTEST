import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
// Imported for the `CatBreedModelMapper.toEntity` extension, which is only in
// scope where its defining library is imported.
import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/breeds_snapshot.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/repository/landing_cats_repository.dart';

import '../datasource/landing_cats_data_source.dart';
import '../datasource/landing_cats_local_data_source.dart';

/// `as:` is what binds the abstraction to this implementation, so consumers keep
/// depending on `LandingCatsRepository`.
///
/// `LazySingleton` rather than `Injectable` is a **correctness requirement**, not a
/// preference: this class holds the resolved image-URL cache and the in-flight
/// request map added in Phase 4. As a factory, every resolve would hand out a fresh
/// empty cache and nothing would ever be cached or de-duplicated. The behaviour
/// that depends on it is pinned in `landing_cats_repository_impl_test.dart`.
@LazySingleton(as: LandingCatsRepository)
class LandingCatsRepositoryImpl implements LandingCatsRepository {
  LandingCatsRepositoryImpl({
    required this.landingCatsDataSource,
    required this.localDataSource,
  });

  final LandingCatsDataSource landingCatsDataSource;

  /// The disk cache. Phase 6.
  final LandingCatsLocalDataSource localDataSource;

  /// Cache first, network second, and never both when the cache is fresh.
  ///
  /// The whole policy, in the order it runs:
  ///
  /// - a cached list inside its TTL is served as [FreshBreeds] and **the network
  ///   is not touched at all** — that is what stops the refetch on every return
  ///   from the detail screen;
  /// - otherwise the network is asked, and a success refreshes the cache;
  /// - if that fails but an expired entry exists, it is served as [StaleBreeds]
  ///   carrying the failure. Before Phase 6 this case was an error screen, which
  ///   threw away a perfectly usable list of cat breeds;
  /// - only with no cache at all does a failure become an `Err`.
  @override
  Future<CatsResult<BreedsSnapshot>> getAllCats() async {
    // Read once, up front: `readBreeds` is synchronous (see the note on it), and
    // both the fresh path and the fallback need the same answer. Reading it twice
    // would also let the two disagree if a write landed in between.
    final cached = localDataSource.readBreeds();

    if (cached != null && !cached.isExpired) {
      return Ok(FreshBreeds(breeds: _toEntities(cached.breeds)));
    }

    try {
      final models = await landingCatsDataSource.getAllCats();
      await localDataSource.writeBreeds(models);
      // Phase 4: an explicit conversion where there used to be an implicit
      // upcast. `CatBreedModel extends CatBreedEntity` meant `Ok(models)`
      // type-checked, so the objects living in the bloc state — and therefore in
      // the widget tree — were always models. Anything TheCatAPI added to its
      // payload reached the domain for free.
      return Ok(FreshBreeds(breeds: _toEntities(models)));
    } on CatsFailure catch (failure) {
      return _staleOr(cached, failure);
    } catch (error) {
      // The catch-all makes this a total function. It used to be `on InvalidData`
      // only, so any other error escaped the result channel entirely and the
      // bloc's `fold` never ran — the app just sat on its spinner. Phase 2 pinned
      // that with a characterization test; Phase 3 replaces it.
      //
      // Nothing above the data layer should ever have to handle a raw exception.
      return _staleOr(cached, UnknownFailure(detail: '$error'));
    }
  }

  /// The expired cache if there is one, and the failure alone if there is not.
  CatsResult<BreedsSnapshot> _staleOr(
    CachedBreeds? cached,
    CatsFailure failure,
  ) => cached == null
      ? Err(failure)
      : Ok(StaleBreeds(breeds: _toEntities(cached.breeds), failure: failure));

  List<CatBreedEntity> _toEntities(List<CatBreedModel> models) => [
    for (final model in models) model.toEntity(),
  ];

  /// Resolves one breed through [getAllCats], so it goes down the same
  /// cache-then-network path.
  ///
  /// There is no `GET /v1/breeds/{id}` call here on purpose. The list endpoint is
  /// a single request that the app has almost always made already, so on a warm
  /// cache this costs **zero** requests; a dedicated per-id endpoint would cost one
  /// every time. On a cold deep link it costs the same one request either way.
  ///
  /// A stale list is good enough to answer with: breed records do not change, and
  /// refusing to show a breed because the refresh failed would be the same mistake
  /// the error screen used to make.
  @override
  Future<CatsResult<CatBreedEntity>> getBreedById(String id) async {
    final snapshot = await getAllCats();

    return switch (snapshot) {
      // `breeds` is on both snapshot variants, so freezed puts it on the sealed
      // base and one pattern covers fresh and stale alike.
      Ok(:final value) => _findById(value.breeds, id),
      Err(:final failure) => Err(failure),
    };
  }

  CatsResult<CatBreedEntity> _findById(List<CatBreedEntity> breeds, String id) {
    for (final breed in breeds) {
      if (breed.id == id) return Ok(breed);
    }
    return Err(NotFoundFailure(id: id));
  }

  /// Resolved image URLs, keyed by `reference_image_id`.
  ///
  /// An image URL never changes for a given id, so this is a pure memo. It is
  /// what makes scrolling back up free, and it is why the injector registers this
  /// repository as a **singleton**: as a factory, every `resolve()` would hand out
  /// a fresh empty cache and the memo would never hit.
  ///
  /// In-memory only, so it dies with the process. Phase 6 adds the persistent,
  /// TTL'd layer.
  final Map<String, String> _urlCache = {};

  /// Requests currently in flight, keyed by the same id.
  ///
  /// Without this, a list building four cards in the same frame — or the user
  /// scrolling an id back into view before its first request came back — fires
  /// several identical requests. The cache alone does not prevent that: it is only
  /// populated *after* the response arrives.
  final Map<String, Future<CatsResult<String>>> _inFlight = {};

  @override
  Future<CatsResult<String>> getBreedImageUrl(String referenceImageId) {
    final cached = _urlCache[referenceImageId];
    if (cached != null) return Future.value(Ok(cached));

    final pending = _inFlight[referenceImageId];
    if (pending != null) return pending;

    final request = _resolve(referenceImageId);
    _inFlight[referenceImageId] = request;
    return request;
  }

  Future<CatsResult<String>> _resolve(String referenceImageId) async {
    try {
      final url = await landingCatsDataSource.getBreedImageUrl(
        referenceImageId,
      );
      _urlCache[referenceImageId] = url;
      return Ok(url);
    } on CatsFailure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(UnknownFailure(detail: '$error'));
    } finally {
      // Always cleared, including on failure: leaving a failed future parked here
      // would make the error permanent for that id, and a retry impossible for as
      // long as the app lives.
      //
      // `unawaited`, because `_inFlight` maps to `Future`s, so `remove` hands one
      // back and discarding it is indistinguishable from forgetting an `await`.
      // There is nothing to wait for: this is the future the caller already holds.
      unawaited(_inFlight.remove(referenceImageId));
    }
  }
}
