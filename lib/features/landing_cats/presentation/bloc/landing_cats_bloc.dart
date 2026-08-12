import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';

import '../../domain/entities/catbreed_entity.dart';
import '../../domain/use_cases/get_all_cats_use_case.dart';

part 'landing_cats_bloc.freezed.dart';
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

    // "The same variant, with a different history."
    //
    // Phase 3 wrote this as a four-branch `switch` reconstructing each variant by
    // hand, on the argument that a new variant would then force a compile error
    // here. Phase 4 makes that argument moot: `searchHistory` is declared on all
    // four constructors, so freezed's `copyWith` on the base **preserves the
    // concrete variant**. There is no branch left to forget — it is total by
    // construction, which is strictly better than being reminded to update it.
    //
    // The exhaustive `switch` that actually earns its keep is the one in
    // `landing_page.dart`, which is what forces the UI to have an error branch.
    emit(state.copyWith(searchHistory: history));
  }
}
