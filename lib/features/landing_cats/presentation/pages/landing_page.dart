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

  @override
  void initState() {
    super.initState();
    // Phase 6 moves this dispatch out of `initState` (where it re-fetches on
    // EVERY return from the detail page) and into the bloc's creation.
    BlocProvider.of<LandingCatsBloc>(context).add(const AllCatsEvent());
  }

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
        // The breed list now exists on exactly one variant, so the app bar has to
        // ask for it rather than assume it is always there.
        final breeds = switch (state) {
          CatsLoaded(:final breeds) => breeds,
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
                CatsError(:final failure) => CatsErrorView(
                  failure: failure,
                  onRetry: () =>
                      context.read<LandingCatsBloc>().add(const AllCatsEvent()),
                ),
              },
            ),
          ],
        );
      },
    );
  }

  Widget _breedList(BuildContext context, List<CatBreedEntity> breeds) {
    return Scrollbar(
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
              context.goNamed(detailPage, extra: breed);
            },
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(height: 12.h),
      ),
    );
  }
}
