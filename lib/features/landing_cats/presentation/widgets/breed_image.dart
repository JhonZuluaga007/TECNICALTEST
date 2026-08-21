import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tecnical_test_pragma/cats_icons.dart';

import '../../domain/use_cases/get_breed_image_use_case.dart';
import '../bloc/breed_image/breed_image_cubit.dart';

/// Resolves and renders one breed's image, lazily.
///
/// This widget is what makes Phase 4's N+1 fix possible: `getAllCats` no longer
/// resolves 65 image URLs before the first frame. Each card resolves its own, only
/// once the list actually builds it — so a screen showing 3 cards costs 3 requests
/// instead of 65 — and the repository memoises the result, so scrolling back is
/// free.
///
/// The use case comes from a `RepositoryProvider` rather than from
/// `Injector.resolve()`. Reaching into the service locator from inside a widget
/// would force every widget test that paints a card to boot the real DI container,
/// which is exactly the trap `SearchCatBreedsUseCase` documents avoiding.
///
/// Phase 9 folded `core/common_widgets/network_image.dart` in here and deleted
/// it. It was a "reusable component" with one caller, and it was not reusable:
/// it imported `cats_icons.dart` so a `core/` widget knew what a cat was, and it
/// duplicated this widget's spinner and its `notImage` fallback — the same asset
/// and the same 250 px default decided in two layers. It also carried a real
/// defect; see [_fallback].
class BreedImage extends StatelessWidget {
  const BreedImage({super.key, required this.referenceImageId, this.height});

  final String referenceImageId;
  final double? height;

  /// The last of the five `250`s Phase 9 found spread across two files.
  ///
  /// It stays a private constant rather than becoming an `AppSpacing`-style
  /// token: it is one widget's default height, not a scale anything else agrees
  /// with.
  static const double _defaultHeight = 250;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // `..resolve(...)` in `create` rather than in a `StatefulWidget.initState`:
      // the cubit is built once per card and the request fires with it.
      create: (_) => BreedImageCubit(
        getBreedImageUseCase: context.read<GetBreedImageUseCase>(),
      )..resolve(referenceImageId),
      child: BlocBuilder<BreedImageCubit, BreedImageState>(
        builder: (context, state) => switch (state) {
          ImageLoading() => _placeholder(),
          ImageReady(:final url) => Image.network(
            url,
            height: height ?? _defaultHeight,
            fit: BoxFit.contain,
            // Phase 7: the indicator's colour was a hardcoded near-black. Unset,
            // it takes `colorScheme.primary` and follows the active brightness.
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
            errorBuilder: (_, _, _) => _fallback(),
          ),
          ImageUnavailable() => _fallback(),
        },
      ),
    );
  }

  Widget _placeholder() => SizedBox(
    height: height ?? _defaultHeight,
    child: const Center(child: CircularProgressIndicator()),
  );

  /// The placeholder for "there is no image to show", whatever the reason.
  ///
  /// Phase 9 fixed a real defect here. `NetworkImageWidget`'s `errorBuilder`
  /// branched on `stackTrace != null` and, when it was null, returned
  /// `Image.network(imageUrl)` — **re-issuing, from inside its own error
  /// handler, the request that had just failed**. That retry carried no
  /// `errorBuilder` of its own, so its failure escaped to `FlutterError` instead
  /// of being handled. The condition discriminated nothing useful either: a null
  /// stack trace does not mean the URL is worth trying again.
  ///
  /// A failed load and a breed with no `reference_image_id` are the same thing to
  /// the user, so they land on the same widget — which is the reasoning
  /// `ImageUnavailable` already documents for merging its two causes.
  Widget _fallback() =>
      Image.asset(CatsIcons.notImage, height: height ?? _defaultHeight);
}
