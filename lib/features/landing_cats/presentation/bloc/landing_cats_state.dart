// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'landing_cats_bloc.dart';

class LandingCatsState {
  final List<CatBreedEntity>? listAllCats;
  final List<String>? namesAlreadySearched;
  final FormSubmissionStatus? formSubmissionStatusService;
  LandingCatsState({
    this.listAllCats,
    this.namesAlreadySearched,
    this.formSubmissionStatusService = const InitialFormStatus(),
  });

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
}
