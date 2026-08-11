import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tecnical_test_pragma/core/config/helpers/form_submission_status.dart';

import '../../domain/entities/catbreed_entity.dart';
import '../../domain/use_cases/get_all_cats_use_case.dart';

part 'landing_cats_event.dart';
part 'landing_cats_state.dart';

class LandingCatsBloc extends Bloc<LandingCatsEvent, LandingCatsState> {
  /// Phase 2: the use case now comes in through the constructor.
  ///
  /// The constructor previously took no arguments and called
  /// `Injector.resolve<GetAllCatsUseCase>()` in its body, so every bloc test
  /// would have had to boot the real container and hit the real network.
  /// Resolution now lives in the composition root (`main.dart`), and this file no
  /// longer imports `core/injector/injector.dart`.
  LandingCatsBloc({required this.getAllCatsUseCase})
    : super(const LandingCatsState()) {
    on<AllCatsEvent>(_onAllCats);
    on<AddNameAlreadySearchedEvent>(_onAddNameAlreadySearched);
  }

  final GetAllCatsUseCase getAllCatsUseCase;

  Future<void> _onAllCats(
    AllCatsEvent event,
    Emitter<LandingCatsState> emit,
  ) async {
    emit(state.copyWith(formSubmissionStatusService: const FormSubmitting()));

    final getAllCatsResponse = await getAllCatsUseCase.getAllCatsCall();

    getAllCatsResponse.fold(
      (error) => emit(
        state.copyWith(
          formSubmissionStatusService: SubmissionFailed(
            exception: Exception(error.message),
          ),
        ),
      ),
      (response) => emit(
        state.copyWith(
          formSubmissionStatusService: const SubmissionSuccess(),
          listAllCats: response,
        ),
      ),
    );
  }

  /// Trimming and de-duplicating the history used to live in the search
  /// delegate's `buildResults`, which also mutated the state's list in place.
  /// Here both are testable, and the emitted list is always new and unmodifiable.
  void _onAddNameAlreadySearched(
    AddNameAlreadySearchedEvent event,
    Emitter<LandingCatsState> emit,
  ) {
    final name = event.name.trim();
    if (name.isEmpty || state.namesAlreadySearched.contains(name)) return;

    emit(
      state.copyWith(
        namesAlreadySearched: List.unmodifiable([
          ...state.namesAlreadySearched,
          name,
        ]),
      ),
    );
  }
}
