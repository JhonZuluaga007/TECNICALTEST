import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tecnical_test_pragma/core/common_widgets/app_scaffold.dart';
import 'package:tecnical_test_pragma/core/common_widgets/status_views.dart';
import 'package:tecnical_test_pragma/core/design_system/breakpoints.dart';
import 'package:tecnical_test_pragma/core/design_system/radii.dart';
import 'package:tecnical_test_pragma/core/design_system/spacing.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/breed_card.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/breed_image.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/search_delegate_all_catbreeds.dart';
import 'package:tecnical_test_pragma/features/settings/presentation/widgets/theme_mode_button.dart';
import 'package:go_router/go_router.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';
import 'package:tecnical_test_pragma/routers/routers.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController scrollController = ScrollController();

  // There is no `initState` here any more.
  //
  // It used to hold `BlocProvider.of<LandingCatsBloc>(context).add(const
  // AllCatsEvent())`, and that was a bug with a long tail: this page is
  // re-created by `go_router` on every return from the detail screen, so every
  // back navigation refetched the whole breed list. Phase 4 made that one request
  // instead of 66, which made it cheap enough to stop being obvious — but it was
  // still a network round trip to redisplay a list the app already had.
  //
  // The dispatch now happens once, where the bloc is created, in `main.dart`. Two
  // consequences worth knowing: the fetch starts during the splash rather than
  // after it, so those five seconds do something; and this page became a pure
  // consumer, which is why widget tests dispatch explicitly instead of relying on
  // a side effect of mounting.

  @override
  void dispose() {
    // There was not a single `dispose()` anywhere in `lib/`: this controller and
    // the other two leaked.
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<LandingCatsBloc, LandingCatsState>(
      builder: (context, state) {
        // The breed list exists on only some variants, so the app bar has to ask
        // for it rather than assume it is always there.
        //
        // `CatsStale` carries breeds too, so the search screen keeps working
        // offline. Leaving it out of this pattern would have been a silent
        // regression: a full list on screen and an empty search behind it, with
        // nothing throwing.
        final breeds = switch (state) {
          CatsLoaded(:final breeds) || CatsStale(:final breeds) => breeds,
          _ => const <CatBreedEntity>[],
        };

        return AppScaffold(
          paddingColumn: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            // Phase 7: `backgroundColor` was pinned to white. An `AppBar` takes
            // `colorScheme.surface` from the theme, which follows the brightness.
            title: Text(l10n.appTitle, style: theme.textTheme.titleLarge),
            actions: const [ThemeModeButton()],
            bottom: PreferredSize(
              preferredSize: const Size(double.infinity, 48),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.xs,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    // No `width: 1` — that is `Border.all`'s own default
                    // (`box_border.dart:468`).
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // The `fontWeight: FontWeight.w100` that used to be here
                        // is gone rather than ported: Acme ships a single
                        // Regular weight, so it asked the engine to synthesize a
                        // thin face that does not exist. `fontStyle:
                        // FontStyle.normal` was the default spelled out.
                        Expanded(
                          child: Text(
                            l10n.searchHint,
                            style: theme.textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showSearch(
                              context: context,
                              delegate: SearchDelegateAllCatbreeds(
                                listCatBreedEntity: breeds,
                              ),
                            );
                          },
                          icon: const Icon(Icons.search_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          children: [
            const SizedBox(height: AppSpacing.md),
            Expanded(
              // Phase 3: an exhaustive `switch` over the sealed state replaces
              // `state.formSubmissionStatusService is SubmissionSuccess ? list :
              // spinner`. That ternary had an implicit `else`, which is how an API
              // failure ended up showing a spinner forever — nothing in the type
              // system asked for an error branch. Now the compiler does.
              //
              // Case order matters: `CatsLoaded(breeds: [])` is a list pattern
              // matching a strict subset, so it has to come before the general
              // `CatsLoaded`, which stays reachable.
              child: switch (state) {
                CatsInitial() || CatsLoading() => const CatsLoadingView(),
                CatsLoaded(breeds: []) => const CatsEmptyView(),
                CatsLoaded(:final breeds) => _breedList(context, breeds),
                // Phase 6's branch, and the compiler is what put it here: adding
                // `CatsStale` to the sealed state broke this switch until it
                // existed. The list is rendered exactly as in the loaded case,
                // with a strip above it — the data is real, just old.
                CatsStale(:final breeds, :final failure) => _breedList(
                  context,
                  breeds,
                  banner: StaleBanner(
                    failure: failure,
                    onRetry: () => _refetch(context),
                  ),
                ),
                CatsError(:final failure) => CatsErrorView(
                  failure: failure,
                  onRetry: () => _refetch(context),
                ),
              },
            ),
          ],
        );
      },
    );
  }

  void _refetch(BuildContext context) =>
      context.read<LandingCatsBloc>().add(const AllCatsEvent());

  /// The list, optionally under a [banner].
  ///
  /// The banner sits outside the `ListView` rather than as its first item so it
  /// stays put while the list scrolls — a notice that scrolls away is a notice the
  /// user will not see.
  Widget _breedList(
    BuildContext context,
    List<CatBreedEntity> breeds, {
    Widget? banner,
  }) {
    // Phase 8. One column is a `ListView`, more than one is a `GridView`, and the
    // distinction is deliberate rather than a special case of the same widget: a
    // one-column `GridView` still forces every tile to the same height, so a
    // breed with a long name would leave a gap under every other card on a phone
    // — the window size the app is used at most.
    final columns = WindowSize.of(context).columns;

    final list = Scrollbar(
      controller: scrollController,
      child: columns == 1
          ? ListView.separated(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: breeds.length,
              itemBuilder: (context, index) => _card(context, breeds[index]),
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: AppSpacing.md),
            )
          : GridView.builder(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                // Not `childAspectRatio`, which is a ratio of the *tile* and
                // therefore turns any text growth into an overflow. A fixed
                // extent lets the card keep its natural height as the column
                // gets narrower, and 420 is what a card measures with the
                // image slot at text scale 1.0.
                mainAxisExtent: 420,
              ),
              itemCount: breeds.length,
              itemBuilder: (context, index) => _card(context, breeds[index]),
            ),
    );

    if (banner == null) return list;

    return Column(
      children: [
        banner,
        const SizedBox(height: AppSpacing.md),
        Expanded(child: list),
      ],
    );
  }

  /// One breed card, shared by the list and the grid.
  Widget _card(BuildContext context, CatBreedEntity breed) => BreedCard(
    name: breed.name,
    // Phase 4: `imageUrlCat: breed.urlImage` — a URL the datasource had already
    // resolved for all 65 breeds before this list existed. Now the card resolves
    // its own, and only the ones the viewport actually builds.
    image: BreedImage(referenceImageId: breed.referenceImageId),
    origin: breed.origin,
    intelligence: breed.intelligence,
    onPressed: () {
      // Phase 6: the id, not the entity. Same destination, but this one survives
      // being written down as a URL.
      context.goNamed(detailPage, pathParameters: {'id': breed.id});
    },
  );
}
