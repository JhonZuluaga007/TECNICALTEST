import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tecnical_test_pragma/core/common_widgets/app_scaffold.dart';
import 'package:tecnical_test_pragma/core/common_widgets/status_views.dart';
import 'package:tecnical_test_pragma/core/design_system/spacing.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/bloc/detail_cat_cubit.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/widgets/list_characteristics_catbreeds_widget.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_by_id_use_case.dart';
// The detail screen already depends on the landing feature for the entity it
// shows, and `BreedImage` follows the same dependency. It stays there
// permanently: Phase 9 went to promote it to `core/common_widgets/` — which four
// documents had promised — and found the promotion impossible. `BreedImage`
// needs `GetBreedImageUseCase` and `BreedImageCubit`, both landing-owned, so
// moving it would make `core/` import a feature and invert the one-way
// dependency rule. Dragging a domain use case into `core/` to make the import
// legal would be worse than the import. The status views, which depended on
// nothing feature-owned, did move.
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/breed_image.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';

/// The breed detail screen.
///
/// Takes a [breedId], not a `CatBreedEntity`. Phase 6 changed that: the entity
/// used to arrive through `go_router`'s `extra`, which is not reconstructible from
/// a URL — a deep link or a process restoration arrived with `state.extra == null`
/// and `(state.extra!) as CatBreedEntity` threw. The route carried a `redirect` to
/// send those to the home screen instead of crashing; that workaround is gone,
/// because the id in the path is all this screen needs.
class DetailCatPage extends StatelessWidget {
  const DetailCatPage({super.key, required this.breedId});

  final String breedId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // `..load` in the `create` rather than in an `initState`: the cubit is built
      // once per route, so there is no re-entry to guard against — which is
      // exactly the mistake the landing page's `initState` used to make.
      create: (_) => DetailCatCubit(
        getBreedByIdUseCase: context.read<GetBreedByIdUseCase>(),
      )..load(breedId),
      child: _DetailCatView(breedId: breedId),
    );
  }
}

class _DetailCatView extends StatefulWidget {
  const _DetailCatView({required this.breedId});

  /// Carried down only so Retry can re-run the same lookup.
  final String breedId;

  @override
  State<_DetailCatView> createState() => _DetailCatViewState();
}

class _DetailCatViewState extends State<_DetailCatView> {
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<DetailCatCubit, DetailCatState>(
      builder: (context, state) {
        return AppScaffold(
          paddingColumn: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          appBar: AppBar(
            automaticallyImplyLeading: true,
            title: Text(
              // The title has to survive not knowing the breed yet. It used to be
              // `widget.catBreedEntity.name`, which was always available because
              // the whole entity came in through the route.
              switch (state) {
                DetailReady(:final breed) => breed.name,
                _ => l10n.appTitle,
              },
              style: theme.textTheme.headlineSmall,
            ),
          ),
          children: [
            Expanded(
              child: switch (state) {
                DetailLoading() => const CatsLoadingView(),
                DetailReady(:final breed) => _breed(context, breed),
                // Reuses the landing screen's error view, callback and all. The
                // retry re-runs the lookup rather than navigating away, which is
                // the useful action for a network failure — and harmless for a
                // genuinely missing id, where the copy already says so.
                DetailFailed(:final failure) => CatsErrorView(
                  failure: failure,
                  onRetry: () =>
                      context.read<DetailCatCubit>().load(widget.breedId),
                ),
              },
            ),
          ],
        );
      },
    );
  }

  Widget _breed(BuildContext context, CatBreedEntity breed) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: BreedImage(
            height: MediaQuery.sizeOf(context).height / 2,
            referenceImageId: breed.referenceImageId,
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              // Phase 8. The description is the longest text in the app, and a
              // full-window line on a 1440 px desktop is unreadable — the eye
              // loses the start of the next line. Typographic measure, not a
              // breakpoint: it kicks in wherever the window happens to be wider
              // than a comfortable line, which is why it needs no `WindowSize`.
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phase 7 maps these three to `bodyLarge` rather than to the
                      // `titleLarge` their old 20 px would suggest: they are body
                      // copy, and a role carries meaning, not just a size.
                      Text(breed.description, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.countryLabel(breed.origin),
                        textAlign: TextAlign.start,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.lifeSpanLabel(breed.lifeSpan),
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ListCharacteristicsCatbreeds(
                        characteristics: [
                          (
                            label: l10n.intelligenceLabel,
                            value: breed.intelligence,
                          ),
                          (
                            label: l10n.adaptabilityLabel,
                            value: breed.adaptability,
                          ),
                        ],
                        labelStyle: theme.textTheme.titleLarge,
                        dotRadius: 12,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
