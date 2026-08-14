import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';

import '../../domain/entities/breeds_snapshot.dart';
import '../../domain/entities/catbreed_entity.dart';
import '../../domain/use_cases/get_all_cats_use_case.dart';

part 'landing_cats_bloc.freezed.dart';
part 'landing_cats_event.dart';
part 'landing_cats_state.dart';

/// The landing screen's bloc.
///
/// Hydrated as of Phase 6, so the search history survives closing the app. Only
/// the history is persisted — see [toJson].
class LandingCatsBloc extends HydratedBloc<LandingCatsEvent, LandingCatsState> {
  /// Phase 2: the use case now comes in through the constructor.
  ///
  /// The constructor previously took no arguments and called
  /// `Injector.resolve<GetAllCatsUseCase>()` in its body, so every bloc test
  /// would have had to boot the real container and hit the real network.
  /// Resolution now lives in the composition root (`main.dart`), and this file no
  /// longer imports `core/injector/injector.dart`.
  ///
  /// Phase 6 adds [storage] on the same principle, and it is **required** rather
  /// than falling back to `HydratedBloc.storage`. That static is a process-wide
  /// global: leaving it as the default would mean every widget test either sets it
  /// or crashes with `StorageNotFound`, and — worse — that all the tests in a file
  /// would share one store, because `flutter_test_config.dart` runs once per file
  /// and the storage key is the runtime type. A history written by one case would
  /// leak into the next. Taking it here gives every bloc its own.
  LandingCatsBloc({required this.getAllCatsUseCase, required Storage storage})
    : super(const CatsInitial(searchHistory: []), storage: storage) {
    on<AllCatsEvent>(_onAllCats);
    on<AddNameAlreadySearchedEvent>(_onAddNameAlreadySearched);
  }

  final GetAllCatsUseCase getAllCatsUseCase;

  /// Persists **only** the search history.
  ///
  /// Not the breeds. They have their own cache, on disk, with a TTL, in the data
  /// layer where a cache belongs; storing them here as well would mean the same
  /// list saved twice under two unrelated expiry policies. It also keeps these
  /// writes cheap: `HydratedMixin.onChange` fires on *every* state change, and
  /// what it writes here is a handful of strings rather than 67 breeds.
  ///
  /// Returning the history unconditionally — rather than `null` for the empty
  /// case — means clearing the history is persisted too.
  @override
  Map<String, dynamic>? toJson(LandingCatsState state) => {
    _historyKey: state.searchHistory,
  };

  /// Restores the history into a fresh [CatsInitial].
  ///
  /// The breeds are deliberately not restored, so the app always starts by asking
  /// for them — from the disk cache first, which is what makes that cheap.
  ///
  /// Returns `null` for anything unreadable, which `hydrated_bloc` treats as "use
  /// the initial state". Same reasoning as the cache's `readBreeds`: a corrupt
  /// entry from an older build must not be able to stop the app from starting.
  @override
  LandingCatsState? fromJson(Map<String, dynamic> json) {
    final stored = json[_historyKey];
    if (stored is! List) return null;

    // `whereType` rather than `cast`: `cast` is a lazy view that throws on the
    // first bad element, which would happen later, somewhere else, on a list a
    // test never built. Dropping the bad entries fails softer and no worse.
    return CatsInitial(
      searchHistory: List<String>.unmodifiable(stored.whereType<String>()),
    );
  }

  static const _historyKey = 'searchHistory';

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
    //
    // Phase 6 splits the success side in two. Nesting the snapshot patterns inside
    // the result patterns keeps it one flat switch: three outcomes, three states,
    // no intermediate variable to forget to use.
    emit(switch (result) {
      Ok(value: FreshBreeds(:final breeds)) => CatsLoaded(
        breeds: breeds,
        searchHistory: state.searchHistory,
      ),
      Ok(value: StaleBreeds(:final breeds, :final failure)) => CatsStale(
        breeds: breeds,
        failure: failure,
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
