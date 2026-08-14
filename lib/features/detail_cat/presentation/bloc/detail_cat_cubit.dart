import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_by_id_use_case.dart';

part 'detail_cat_cubit.freezed.dart';

/// The detail screen's state.
///
/// New in Phase 6. The screen used to need no state at all: `go_router` handed it
/// a fully-built `CatBreedEntity` through `extra`, so there was nothing to load
/// and nothing that could fail. That was also why a deep link to `/home/detail`
/// crashed — `extra` is not reconstructible from a URL — and why the route carried
/// a `redirect` to paper over it.
///
/// Resolving an id instead means the screen can be waiting, or wrong. Both are now
/// states with a branch rather than a null check.
@freezed
sealed class DetailCatState with _$DetailCatState {
  const factory DetailCatState.loading() = DetailLoading;

  const factory DetailCatState.ready({required CatBreedEntity breed}) =
      DetailReady;

  /// The breed could not be shown, with the typed reason.
  ///
  /// Covers both "no such id" (`NotFoundFailure`) and "we could not find out"
  /// (a network failure with no cache to fall back on). They are one state because
  /// the screen does the same thing with them — shows `messageFor(failure)` — and
  /// the copy already distinguishes the causes.
  const factory DetailCatState.failed({required CatsFailure failure}) =
      DetailFailed;
}

/// Resolves one breed by id for the detail screen.
///
/// A `Cubit` rather than a bloc: there is exactly one input (an id) and no event
/// vocabulary worth naming. Same reasoning as `BreedImageCubit`.
class DetailCatCubit extends Cubit<DetailCatState> {
  DetailCatCubit({required this.getBreedByIdUseCase})
    : super(const DetailLoading());

  final GetBreedByIdUseCase getBreedByIdUseCase;

  /// Looks [id] up and emits the outcome.
  ///
  /// Usually costs no network at all: the use case goes through the repository's
  /// cache, which the landing screen has almost always filled already. On a cold
  /// deep link it costs the single `/breeds` request — the same one the app makes
  /// at startup anyway.
  ///
  /// The `isClosed` guard is for the user who presses back while the lookup is in
  /// flight; emitting on a closed cubit throws.
  Future<void> load(String id) async {
    final result = await getBreedByIdUseCase(id);
    if (isClosed) return;

    emit(switch (result) {
      Ok(:final value) => DetailReady(breed: value),
      Err(:final failure) => DetailFailed(failure: failure),
    });
  }
}
