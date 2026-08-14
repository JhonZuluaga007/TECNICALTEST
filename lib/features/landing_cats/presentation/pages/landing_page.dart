import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:tecnical_test_pragma/core/common_widgets/card/card_cat_widget.dart';
import 'package:tecnical_test_pragma/core/common_widgets/my_app_scaffold.dart';
import 'package:tecnical_test_pragma/core/common_widgets/text/text_widget.dart';
import 'package:tecnical_test_pragma/core/config/theme/app_cats_colors.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
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
    final wColor = AppCatsColor();
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
            backgroundColor: wColor.mapColors["W"],
            title: TextWidget(
              text: "Catbreeds",
              fontSize: 20,
              colorText: wColor.black,
            ),
            bottom: PreferredSize(
              preferredSize: Size(double.infinity, 40.h),
              child: Padding(
                padding: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 5.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: wColor.mapColors["W"],
                    border: Border.all(color: wColor.black, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.w, right: 8.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(
                          fontSize: 18,
                          fontWeight: FontWeight.w100,
                          text: "Search by the name",
                          fontStyle: FontStyle.normal,
                          colorText: wColor.black,
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
