import 'package:injectable/injectable.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
// Imported for the `CatBreedModelMapper.toEntity` extension, which is only in
// scope where its defining library is imported.
import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/repository/landing_cats_repository.dart';

import '../datasource/landing_cats_data_source.dart';

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
  LandingCatsRepositoryImpl({required this.landingCatsDataSource});

  final LandingCatsDataSource landingCatsDataSource;

  @override
  Future<CatsResult<List<CatBreedEntity>>> getAllCats() async {
    try {
      final models = await landingCatsDataSource.getAllCats();
      // Phase 4: an explicit conversion where there used to be an implicit
      // upcast. `CatBreedModel extends CatBreedEntity` meant `Ok(models)`
      // type-checked, so the objects living in the bloc state — and therefore in
      // the widget tree — were always models. Anything TheCatAPI added to its
      // payload reached the domain for free.
      return Ok([for (final model in models) model.toEntity()]);
    } on CatsFailure catch (failure) {
      return Err(failure);
    } catch (error) {
      // The catch-all makes this a total function. It used to be `on InvalidData`
      // only, so any other error escaped the result channel entirely and the
      // bloc's `fold` never ran — the app just sat on its spinner. Phase 2 pinned
      // that with a characterization test; Phase 3 replaces it.
      //
      // Nothing above the data layer should ever have to handle a raw exception.
      return Err(UnknownFailure(detail: '$error'));
    }
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
      _inFlight.remove(referenceImageId);
    }
  }
}
