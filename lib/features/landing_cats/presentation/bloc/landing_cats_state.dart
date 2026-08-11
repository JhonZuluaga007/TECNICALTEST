part of 'landing_cats_bloc.dart';

/// Phase 3: a `sealed` hierarchy instead of one class with a status field.
///
/// The payoff is that illegal states stop being representable. `breeds` exists
/// only on [CatsLoaded] and `failure` only on [CatsError], so it is no longer
/// possible to read a breed list from a failed request — or, more importantly, to
/// *forget* to handle the failed request, because the `switch` in
/// `landing_page.dart` is checked for exhaustiveness by the compiler. Before this,
/// the UI did `state.formSubmissionStatusService is SubmissionSuccess ? list :
/// spinner`, and an API error meant an infinite spinner.
///
/// The subclasses live in this `part`, which is the same library as
/// `landing_cats_bloc.dart` — what `sealed` requires.
///
/// `copyWith` is gone: with variants that hold different fields it has no single
/// meaning. Phase 4 brings it back per variant via `freezed`.
sealed class LandingCatsState extends Equatable {
  /// [searchHistory] is `required`, with **no default**, on purpose.
  ///
  /// It is orthogonal to the fetch lifecycle and has to survive
  /// initial -> loading -> loaded/error. `copyWith` used to carry it along for
  /// free; now every `emit` builds a fresh variant and has to pass it explicitly.
  /// Making it required turns forgetting it into a **compile error** instead of a
  /// silently emptied history — which is precisely the failure mode Phase 2 spent
  /// its time making loud.
  const LandingCatsState({required this.searchHistory});

  final List<String> searchHistory;

  @override
  List<Object?> get props => [searchHistory];
}

final class CatsInitial extends LandingCatsState {
  const CatsInitial({required super.searchHistory});
}

final class CatsLoading extends LandingCatsState {
  const CatsLoading({required super.searchHistory});
}

final class CatsLoaded extends LandingCatsState {
  const CatsLoaded({required this.breeds, required super.searchHistory});

  final List<CatBreedEntity> breeds;

  /// `searchHistory` is **not** optional here. Leaving it out would make two
  /// `CatsLoaded` states with different histories compare equal, `emit` would
  /// drop the update, and the search history would die in the only state where
  /// the search screen is reachable at all.
  @override
  List<Object?> get props => [breeds, searchHistory];
}

final class CatsError extends LandingCatsState {
  const CatsError({required this.failure, required super.searchHistory});

  final CatsFailure failure;

  @override
  List<Object?> get props => [failure, searchHistory];
}
