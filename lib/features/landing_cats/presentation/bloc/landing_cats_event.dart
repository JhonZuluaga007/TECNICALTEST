part of 'landing_cats_bloc.dart';

/// Phase 2: events became `Equatable`.
///
/// Not for the bloc's sake: it is so the search delegate's widget test can write
/// `verify(() => bloc.add(const AddNameAlreadySearchedEvent(name: 'sia')))`,
/// because mocktail's `verify` compares arguments with `==`.
abstract class LandingCatsEvent extends Equatable {
  const LandingCatsEvent();

  @override
  List<Object?> get props => const [];
}

class AllCatsEvent extends LandingCatsEvent {
  const AllCatsEvent();
}

/// Carries a single name, not the whole history list.
///
/// It previously carried a `List<String>`, and the widget mutated it in place
/// before dispatching — and that list was the same instance living in the bloc's
/// state. The bloc now owns building the new list.
class AddNameAlreadySearchedEvent extends LandingCatsEvent {
  const AddNameAlreadySearchedEvent({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}
