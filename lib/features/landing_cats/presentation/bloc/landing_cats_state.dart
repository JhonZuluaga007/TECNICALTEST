part of 'landing_cats_bloc.dart';

/// The landing screen's state, as a sealed union.
///
/// Phase 3 introduced the modelling and Phase 4 moved it from hand-written
/// `Equatable` subclasses to `freezed`. The variant names are given explicitly
/// (`= CatsInitial`, `= CatsLoaded`, …) rather than letting freezed name them
/// `_$LandingCatsStateInitial`, which is why the exhaustive `switch` in
/// `landing_page.dart` did not change by a single character.
///
/// What the modelling buys, unchanged since Phase 3: the breed list exists on
/// exactly one variant and the failure on exactly one, so "loaded with an error"
/// and "failed but still holding breeds" are not expressible. Before this, all
/// three fields were always present and the UI decided with an `is` check that
/// had an implicit `else` — which is how an API failure showed a spinner forever.
///
/// [searchHistory] is the one field common to every variant, because it is
/// orthogonal to the fetch lifecycle: it has to survive loading → loaded → error.
/// It is `required` with **no default** on purpose — forgetting it is then a
/// compile error rather than a silently emptied history. And because it is on all
/// four constructors, freezed exposes it on the base type and generates a
/// `copyWith` for it that **preserves the concrete variant** (see the bloc's
/// `_onAddNameAlreadySearched`).
@freezed
sealed class LandingCatsState with _$LandingCatsState {
  /// Nothing requested yet. The landing page dispatches `AllCatsEvent` on mount,
  /// so this is visible for one frame.
  const factory LandingCatsState.initial({
    required List<String> searchHistory,
  }) = CatsInitial;

  /// A fetch is in flight.
  const factory LandingCatsState.loading({
    required List<String> searchHistory,
  }) = CatsLoading;

  /// The fetch succeeded. [breeds] may be empty, and the UI distinguishes that
  /// case with the list pattern `CatsLoaded(breeds: [])`.
  const factory LandingCatsState.loaded({
    required List<CatBreedEntity> breeds,
    required List<String> searchHistory,
  }) = CatsLoaded;

  /// Breeds from an expired cache, because the refresh failed.
  ///
  /// New in Phase 6, and the variant the README promised would force every
  /// `switch` over this type to grow a branch.
  ///
  /// **It is worth naming the tension.** Phase 3 argued that the value of the
  /// sealed modelling was that "loaded with an error" could not be expressed: the
  /// old state carried breeds, a failure and a status flag all at once, and the UI
  /// picked with an `is` check that had an implicit `else` — which is how an API
  /// failure showed a spinner forever. This variant makes that combination
  /// expressible again, on purpose. The difference is that it is now one named
  /// state with a required branch and a test, rather than an accidental product of
  /// three always-present fields. The compiler still refuses to let anyone ignore
  /// it.
  ///
  /// What it buys: the app works offline. Before Phase 6 a failed refresh showed
  /// an error screen while a complete list of cat breeds sat on disk, unused.
  const factory LandingCatsState.stale({
    required List<CatBreedEntity> breeds,
    required CatsFailure failure,
    required List<String> searchHistory,
  }) = CatsStale;

  /// The fetch failed **and there is nothing to show** — no cache, not even an
  /// expired one. Since Phase 6 this is a narrower state than it used to be:
  /// anything with breeds in hand becomes [CatsStale] instead.
  const factory LandingCatsState.error({
    required CatsFailure failure,
    required List<String> searchHistory,
  }) = CatsError;
}
