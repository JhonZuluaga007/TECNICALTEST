import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:tecnical_test_pragma/core/common_widgets/card/card_cat_widget.dart';
import 'package:tecnical_test_pragma/core/common_widgets/my_app_scaffold.dart';
import 'package:tecnical_test_pragma/core/common_widgets/text/text_widget.dart';
import 'package:tecnical_test_pragma/core/config/helpers/form_submission_status.dart';
import 'package:tecnical_test_pragma/core/config/theme/app_cats_colors.dart';
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
    BlocProvider.of<LandingCatsBloc>(context).add(AllCatsEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final wColor = AppCatsColor();
    return BlocBuilder<LandingCatsBloc, LandingCatsState>(
      builder: (context, state) {
        return MyAppScaffold(
          paddingColumn: EdgeInsets.symmetric(horizontal: 12.w),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: wColor.mapColors["W"],
            title: TextWidget(
                text: "Catbreeds", fontSize: 20, colorText: wColor.black),
            bottom: PreferredSize(
                preferredSize: Size(double.infinity, 40.h),
                child: Padding(
                  padding:
                      EdgeInsets.only(left: 12.w, right: 12.w, bottom: 5.h),
                  child: Container(
                    decoration: BoxDecoration(
                        color: wColor.mapColors["W"],
                        border: Border.all(color: wColor.black, width: 1),
                        borderRadius: BorderRadius.circular(8)),
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
                                        listCatBreedEntity:
                                            state.listAllCats ?? [],
                                        filterNamesSearched:
                                            state.namesAlreadySearched ?? []));
                              },
                              icon: const Icon(Icons.search_rounded))
                        ],
                      ),
                    ),
                  ),
                )),
          ),
          children: [
            SizedBox(height: 12.h),
            Expanded(
              child: state.formSubmissionStatusService is SubmissionSuccess
                  ? Scrollbar(
                      controller: scrollController,
                      child: ListView.separated(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.listAllCats?.length ?? 0,
                        itemBuilder: (context, index) {
                          return CardCatWidget(
                            nameCat: state.listAllCats![index].name,
                            imageUrlCat: state.listAllCats![index].urlImage,
                            countryOrigin: state.listAllCats![index].origin,
                            intelligent: state.listAllCats![index].intelligence,
                            onPressed: () {
                              context.goNamed(detailPage,
                                  extra: state.listAllCats![index]);
                            },
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            SizedBox(
                          height: 12.h,
                        ),
                      ),
                    )
                  : Center(
                      child: CircularProgressIndicator(
                        color: wColor.black,
                      ),
                    ),
            )
          ],
        );
      },
    );
  }
}
