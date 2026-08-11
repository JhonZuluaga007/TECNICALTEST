part of 'landing_cats_bloc.dart';

/// Phase 2: became `Equatable`, and the lists are no longer nullable.
///
/// With `const []` defaults the constructor can be `const`, which is what makes
/// `bloc_test`'s `expect:` readable (`const LandingCatsState().copyWith(...)`),
/// and it removes the four `state.listAllCats![index]` force-unwraps from
/// `landing_page.dart`.
class LandingCatsState extends Equatable {
  const LandingCatsState({
    this.listAllCats = const [],
    this.namesAlreadySearched = const [],
    this.formSubmissionStatusService = const InitialFormStatus(),
  });

  final List<CatBreedEntity> listAllCats;
  final List<String> namesAlreadySearched;
  final FormSubmissionStatus formSubmissionStatusService;

  LandingCatsState copyWith({
    List<CatBreedEntity>? listAllCats,
    List<String>? namesAlreadySearched,
    FormSubmissionStatus? formSubmissionStatusService,
  }) {
    return LandingCatsState(
      listAllCats: listAllCats ?? this.listAllCats,
      namesAlreadySearched: namesAlreadySearched ?? this.namesAlreadySearched,
      formSubmissionStatusService:
          formSubmissionStatusService ?? this.formSubmissionStatusService,
    );
  }

  @override
  List<Object?> get props => [
    listAllCats,
    namesAlreadySearched,
    formSubmissionStatusService,
  ];
}
