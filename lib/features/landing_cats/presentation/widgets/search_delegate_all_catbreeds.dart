import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:tecnical_test_pragma/core/common_widgets/card/card_cat_widget.dart';
import 'package:tecnical_test_pragma/core/common_widgets/text/text_widget.dart';
import 'package:tecnical_test_pragma/core/config/theme/app_cats_colors.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/search_cat_breeds_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/breed_image.dart';
import 'package:tecnical_test_pragma/routers/routes_imports.dart';

class SearchDelegateAllCatbreeds extends SearchDelegate<List<CatBreedEntity>?> {
  SearchDelegateAllCatbreeds({
    required this.listCatBreedEntity,
    this.search = const SearchCatBreedsUseCase(),
  });

  final List<CatBreedEntity> listCatBreedEntity;
  final SearchCatBreedsUseCase search;

  final wColor = AppCatsColor();

  /// Kept because `buildLeading` returns it when the search is closed.
  List<CatBreedEntity> filterCatBreedEntity = const [];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = "",
        icon: Icon(Icons.clear, color: wColor.black),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, filterCatBreedEntity),
      icon: Icon(Icons.arrow_back, color: wColor.black),
    );
  }

  /// Saving to the history happens here, not in `buildResults`.
  ///
  /// `buildResults` *is* a build method: dispatching an event from there only
  /// survived because `bloc.add` is asynchronous. `showResults` is the public
  /// hook `_SearchPageState` calls on text submit or suggestion tap, and its
  /// `context` sits under the Navigator, hence under the app's `BlocProvider`.
  @override
  void showResults(BuildContext context) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      BlocProvider.of<LandingCatsBloc>(
        context,
      ).add(AddNameAlreadySearchedEvent(name: trimmed));
    }
    super.showResults(context);
  }

  // With the side effect moved to `showResults`, results and suggestions became
  // identical: a single `_body`.
  @override
  Widget buildResults(BuildContext context) => _body(context);

  @override
  Widget buildSuggestions(BuildContext context) => _body(context);

  Widget _body(BuildContext context) {
    if (query.isEmpty) return _searchHistory(context);

    filterCatBreedEntity = search(listCatBreedEntity, query);

    return ListView.builder(
      // `primary: false` with no controller: each list owns its own scroll
      // position.
      //
      // There used to be ONE `ScrollController` shared by both lists (which
      // coexist during the 300 ms `AnimatedSwitcher` cross-fade in
      // `_SearchPageState`) and it was never released: `SearchDelegate` has no
      // dispose hook, so one controller leaked per tap on the search icon.
      //
      // And `primary: false` is not cosmetic: without it `ScrollView` computes
      // `primary ?? controller == null && shouldInherit(...)`, every
      // `ModalRoute` provides a `PrimaryScrollController`, and both lists would
      // go right back to sharing it.
      primary: false,
      itemCount: filterCatBreedEntity.length,
      itemBuilder: (_, int index) {
        final breed = filterCatBreedEntity[index];
        return CardCatWidget(
          nameCat: breed.name,
          image: BreedImage(referenceImageId: breed.referenceImageId),
          countryOrigin: breed.origin,
          intelligent: breed.intelligence,
          onPressed: () =>
              context.goNamed(detailPage, pathParameters: {'id': breed.id}),
        );
      },
    );
  }

  /// The history is read from the bloc, not from a list passed in by the caller.
  ///
  /// It previously arrived as a constructor parameter, so the rendered list was
  /// frozen at the moment the search opened: searching for something and then
  /// clearing the query did not show the term just searched.
  Widget _searchHistory(BuildContext context) {
    return BlocBuilder<LandingCatsBloc, LandingCatsState>(
      buildWhen: (previous, current) =>
          previous.searchHistory != current.searchHistory,
      builder: (context, state) {
        final history = state.searchHistory;
        return ListView.builder(
          primary: false,
          itemCount: history.length,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          itemBuilder: (context, index) {
            return TextButton(
              onPressed: () => query = history[index],
              child: TextWidget(
                textAlign: TextAlign.start,
                text: history[index],
                fontSize: 18,
                colorText: wColor.black,
              ),
            );
          },
        );
      },
    );
  }
}
