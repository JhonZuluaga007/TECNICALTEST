import 'package:tecnical_test_pragma/core/storage/key_value_store.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';

/// What [LandingCatsLocalDataSource.readBreeds] hands back.
///
/// A record rather than a class: it is two values with no behaviour, read in one
/// place. `isExpired` is deliberately reported instead of hidden — the repository
/// needs an expired entry, because serving stale breeds beats an error screen when
/// the network is down. A `readBreeds()` that filtered them out would make that
/// impossible.
typedef CachedBreeds = ({List<CatBreedModel> breeds, bool isExpired});

/// The breeds cache, on disk.
///
/// New in Phase 6. Before it, every cold start and every return from the detail
/// page hit the network for a list of cat breeds that changes roughly never.
///
/// It caches **models, not entities**. Two reasons: the model is what has
/// `fromJson`/`toJson`, and a cache is a data-layer concern that should not be
/// able to reach the domain shape. Phase 4 already paid for this — see the note in
/// `build.yaml` about `explicit_to_json`, which is exactly the setting that makes
/// a nested `WeightModel` survive a round trip through a map.
class LandingCatsLocalDataSource {
  LandingCatsLocalDataSource({
    required this.store,
    this.ttl = const Duration(hours: 12),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// **Versioned on purpose.** A change to `CatBreedModel` leaves whatever is on
  /// disk unreadable, and bumping the suffix is cheaper — and far safer — than
  /// writing a migration for a cache that regenerates itself in one request.
  ///
  /// The version is a belt to [readBreeds]'s braces: even without a bump, an
  /// unreadable payload is treated as no payload.
  static const breedsKey = 'landing_cats.breeds.v1';

  static const _savedAtField = 'savedAt';
  static const _breedsField = 'breeds';

  final KeyValueStore store;

  /// How long a cached list is served without asking the network.
  ///
  /// Twelve hours because breed data is essentially static — TheCatAPI's catalogue
  /// changes on the order of years — so the TTL is really about bounding how long a
  /// bug in the payload could persist, not about freshness.
  final Duration ttl;

  /// Injected so the expiry tests do not have to spend real time.
  final DateTime Function() _clock;

  /// The cached breeds, or `null` when there are none to read.
  ///
  /// **Synchronous**, because `KeyValueStore.read` is: a cold start can serve the
  /// cache without awaiting, so there is no frame of spinner before a list the app
  /// already had.
  ///
  /// **Never throws.** Anything unreadable — a payload from an older model, a
  /// half-written entry, a value of the wrong type entirely — is reported as "no
  /// cache" and the caller goes to the network. This is not defensive
  /// programming for its own sake: a cache that can throw is a cache that can make
  /// the app unlaunchable after a deploy, and the only fix a user has for that is
  /// reinstalling.
  CachedBreeds? readBreeds() {
    // The shape checks below are **redundant with the `catch`**, and it is worth
    // saying so rather than implying two independent guards. Verified by mutation:
    // deleting them and casting instead leaves the whole suite green, because
    // every bad shape reaches the same `return null` either way — one by a test,
    // the other by a `TypeError`.
    //
    // They stay because they state the contract a payload has to meet, in the
    // order it has to meet it, instead of leaving that implicit in which cast
    // happens to throw first. The `catch` is the backstop for what they miss.
    try {
      final raw = store.read(breedsKey);
      if (raw is! Map) return null;

      final savedAt = raw[_savedAtField];
      final breeds = raw[_breedsField];
      if (savedAt is! int || breeds is! List) return null;

      final models = [
        for (final entry in breeds)
          CatBreedModel.fromJson(Map<String, dynamic>.from(entry as Map)),
      ];

      final age = _clock().difference(
        DateTime.fromMillisecondsSinceEpoch(savedAt),
      );

      // `age.isNegative` covers a clock that moved backwards (a timezone change,
      // a manual adjustment). Treating the future as expired is the safe read:
      // the worst case is one extra request.
      return (breeds: models, isExpired: age.isNegative || age >= ttl);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeBreeds(List<CatBreedModel> breeds) =>
      store.write(breedsKey, <String, Object?>{
        _savedAtField: _clock().millisecondsSinceEpoch,
        _breedsField: [for (final breed in breeds) breed.toJson()],
      });
}
