import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:tecnical_test_pragma/core/common_widgets/card/card_cat_widget.dart';
import 'package:tecnical_test_pragma/core/common_widgets/my_app_scaffold.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/settings/presentation/bloc/theme_mode_cubit.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/breed_image.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/landing_status_views.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/search_delegate_all_catbreeds.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
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

        return MyAppScaffold(
          paddingColumn: EdgeInsets.symmetric(horizontal: 12.w),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            // Phase 7: `backgroundColor` was pinned to white. An `AppBar` takes
            // `colorScheme.surface` from the theme, which follows the brightness.
            title: Text(l10n.appTitle, style: theme.textTheme.titleLarge),
            actions: const [_ThemeModeButton()],
            bottom: PreferredSize(
              preferredSize: Size(double.infinity, 40.h),
              child: Padding(
                padding: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 5.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.w, right: 8.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // The `fontWeight: FontWeight.w100` that used to be here
                        // is gone rather than ported: Acme ships a single
                        // Regular weight, so it asked the engine to synthesize a
                        // thin face that does not exist. `fontStyle:
                        // FontStyle.normal` was the default spelled out.
                        Text(l10n.searchHint, style: theme.textTheme.bodyLarge),
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
            SizedBox(height: 12.h),
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
    final list = Scrollbar(
      controller: scrollController,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: breeds.length,
        itemBuilder: (context, index) {
          final breed = breeds[index];
          return CardCatWidget(
            nameCat: breed.name,
            // Phase 4: `imageUrlCat: breed.urlImage` — a URL the datasource had
            // already resolved for all 65 breeds before this list existed. Now the
            // card resolves its own, and only the ones `ListView` actually builds.
            image: BreedImage(referenceImageId: breed.referenceImageId),
            countryOrigin: breed.origin,
            intelligent: breed.intelligence,
            onPressed: () {
              // Phase 6: the id, not the entity. Same destination, but this one
              // survives being written down as a URL.
              context.goNamed(detailPage, pathParameters: {'id': breed.id});
            },
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(height: 12.h),
      ),
    );

    if (banner == null) return list;

    return Column(
      children: [
        banner,
        SizedBox(height: 12.h),
        Expanded(child: list),
      ],
    );
  }
}

/// The only affordance for the theme, deliberately one button rather than a
/// settings screen.
///
/// Phase 7. Dark mode with no control is invisible to a user whose device is in
/// light mode, which is most of them — and the roadmap does not have a settings
/// screen on it.
///
/// Its own widget, and `const`, so cycling the theme rebuilds this icon rather
/// than the whole page and its list.
class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeModeCubit, ThemeMode>(
      builder: (context, mode) => IconButton(
        tooltip: AppLocalizations.of(context).toggleTheme,
        onPressed: context.read<ThemeModeCubit>().cycle,
        icon: Icon(switch (mode) {
          ThemeMode.system => Icons.brightness_auto_outlined,
          ThemeMode.light => Icons.light_mode_outlined,
          ThemeMode.dark => Icons.dark_mode_outlined,
        }),
      ),
    );
  }
}
