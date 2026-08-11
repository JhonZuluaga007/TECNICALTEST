import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';

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
    : super(const CatsInitial(searchHistory: [])) {
    on<AllCatsEvent>(_onAllCats);
    on<AddNameAlreadySearchedEvent>(_onAddNameAlreadySearched);
  }

  final GetAllCatsUseCase getAllCatsUseCase;

  Future<void> _onAllCats(
    AllCatsEvent event,
    Emitter<LandingCatsState> emit,
  ) async {
    emit(CatsLoading(searchHistory: state.searchHistory));

    final result = await getAllCatsUseCase.getAllCatsCall();

    // Phase 3: an exhaustive `switch` expression instead of `Either.fold` with two
    // closures. The compiler now guarantees both outcomes are handled, and the
    // failure arrives **typed** at the UI instead of being flattened into
    // `Exception(error.message)`, which is what lets the error view show a
    // different message per cause.
    emit(switch (result) {
      Ok(:final value) => CatsLoaded(
        breeds: value,
        searchHistory: state.searchHistory,
      ),
      Err(:final failure) => CatsError(
        failure: failure,
        searchHistory: state.searchHistory,
      ),
    });
  }

  /// Trimming and de-duplicating the history used to live in the search
  /// delegate's `buildResults`, which also mutated the state's list in place.
  /// Here both are testable, and the emitted list is always new and unmodifiable.
  void _onAddNameAlreadySearched(
    AddNameAlreadySearchedEvent event,
    Emitter<LandingCatsState> emit,
  ) {
    final name = event.name.trim();
    if (name.isEmpty || state.searchHistory.contains(name)) return;

    final history = List<String>.unmodifiable([...state.searchHistory, name]);

    // "The same variant, with a different history." More verbose than the old
    // `copyWith`, and better: when Phase 6 adds a variant for the hydrated/
    // refreshing case, the compiler will refuse to build until this switch
    // accounts for it.
    emit(switch (state) {
      CatsInitial() => CatsInitial(searchHistory: history),
      CatsLoading() => CatsLoading(searchHistory: history),
      CatsLoaded(:final breeds) => CatsLoaded(
        breeds: breeds,
        searchHistory: history,
      ),
      CatsError(:final failure) => CatsError(
        failure: failure,
        searchHistory: history,
      ),
    });
  }
}
