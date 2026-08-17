import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tecnical_test_pragma/cats_icons.dart';
import 'package:tecnical_test_pragma/core/common_widgets/network_image.dart';

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
class BreedImage extends StatelessWidget {
  const BreedImage({super.key, required this.referenceImageId, this.height});

  final String referenceImageId;
  final double? height;

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
          ImageLoading() => _placeholder(context),
          ImageReady(:final url) => NetworkImageWidget(
            imageUrl: url,
            height: height,
          ),
          ImageUnavailable() => Image.asset(
            CatsIcons.notImage,
            height: height ?? 250,
          ),
        },
      ),
    );
  }

  // Phase 7: the indicator's colour was a hardcoded near-black. Unset, it takes
  // `colorScheme.primary` and follows the active brightness.
  Widget _placeholder(BuildContext context) => SizedBox(
    height: height ?? 250,
    child: const Center(child: CircularProgressIndicator()),
  );
}
