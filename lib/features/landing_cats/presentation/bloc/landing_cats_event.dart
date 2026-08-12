part of 'landing_cats_bloc.dart';

/// The landing screen's events.
///
/// They need value equality — not for the bloc's sake, but so the search
/// delegate's widget test can write
/// `verify(() => bloc.add(const AddNameAlreadySearchedEvent(name: 'sia')))`,
/// because mocktail's `verify` compares arguments with `==`. Phase 2 got that
/// from `Equatable`; Phase 4 gets it from `freezed`, with the variant names given
/// explicitly so no consumer changed.
@freezed
sealed class LandingCatsEvent with _$LandingCatsEvent {
  /// Fetch every breed. Dispatched on mount and by the error view's Retry button.
  const factory LandingCatsEvent.allCats() = AllCatsEvent;

  /// Record a searched name in the history.
  ///
  /// Carries a single name, not the whole list. It previously carried a
  /// `List<String>` that the widget mutated in place before dispatching — and
  /// that list was the same instance living in the bloc's state. Building the new
  /// list is the bloc's job.
  const factory LandingCatsEvent.addNameAlreadySearched({
    required String name,
  }) = AddNameAlreadySearchedEvent;
}
