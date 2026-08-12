import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tecnical_test_pragma/core/utils/cats_result.dart';

import '../../../domain/use_cases/get_breed_image_use_case.dart';

part 'breed_image_cubit.freezed.dart';

/// One breed image's resolution state.
///
/// A `Cubit` rather than events on `LandingCatsBloc` on purpose: keeping the URLs
/// in the landing state would mean every resolved image re-emits the whole state
/// and rebuilds the entire list. Per-card state keeps each resolution local to the
/// card that needs it.
@freezed
sealed class BreedImageState with _$BreedImageState {
  const factory BreedImageState.loading() = ImageLoading;

  const factory BreedImageState.ready({required String url}) = ImageReady;

  /// No image, for either reason.
  ///
  /// The breed has no `reference_image_id` (2 of the 67), or resolving it failed.
  /// Those are distinct causes with an identical remedy — show the placeholder —
  /// so they are one state rather than two the UI would handle identically.
  const factory BreedImageState.unavailable() = ImageUnavailable;
}

class BreedImageCubit extends Cubit<BreedImageState> {
  BreedImageCubit({required this.getBreedImageUseCase})
    : super(const ImageLoading());

  final GetBreedImageUseCase getBreedImageUseCase;

  /// Resolves [referenceImageId] and emits the outcome.
  ///
  /// The `isClosed` guard is not defensive noise: cards are scrolled out of view
  /// and disposed while their request is still in flight, and emitting on a closed
  /// cubit throws. The work is not wasted either — the repository caches the URL,
  /// so scrolling back finds it already resolved.
  Future<void> resolve(String referenceImageId) async {
    if (referenceImageId.isEmpty) {
      emit(const ImageUnavailable());
      return;
    }

    final result = await getBreedImageUseCase(referenceImageId);
    if (isClosed) return;

    emit(switch (result) {
      // An empty URL means the API had no usable one, which for the user is the
      // same as having no image.
      Ok(value: '') => const ImageUnavailable(),
      Ok(:final value) => ImageReady(url: value),
      Err() => const ImageUnavailable(),
    });
  }
}
