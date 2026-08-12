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

  /// The fetch failed, carrying the **typed** failure so the error view can show
  /// a different message per cause instead of one generic string.
  const factory LandingCatsState.error({
    required CatsFailure failure,
    required List<String> searchHistory,
  }) = CatsError;
}
