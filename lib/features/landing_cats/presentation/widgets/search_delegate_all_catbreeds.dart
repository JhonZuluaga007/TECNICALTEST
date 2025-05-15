import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:tecnical_test_pragma/core/common_widgets/card/card_cat_widget.dart';
import 'package:tecnical_test_pragma/core/common_widgets/text/text_widget.dart';
import 'package:tecnical_test_pragma/core/config/theme/app_cats_colors.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
import 'package:tecnical_test_pragma/routers/routes_imports.dart';

class SearchDelegateAllCatbreeds extends SearchDelegate {
  final wColor = AppCatsColor();
  List<CatBreedEntity> filterCatBreedEntity = [];
  List<String> filterNamesSearched;

  final List<CatBreedEntity> listCatBreedEntity;
  final ScrollController scrollController = ScrollController();

  SearchDelegateAllCatbreeds(
      {required this.listCatBreedEntity, required this.filterNamesSearched});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: () => query = "",
          icon: Icon(Icons.clear, color: wColor.black)),
    ];
  }

  void callEventSaveNamesAlreadySearched(
      BuildContext context, List<String> listNamesAlreadySearched) {
    BlocProvider.of<LandingCatsBloc>(context).add(AddNameAlreadySearchedEvent(
        listNamesAlreadySearched: filterNamesSearched));
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () {
          close(context, filterCatBreedEntity);
        },
        icon: Icon(Icons.arrow_back, color: wColor.black));
  }

  Widget _emptyContainer(BuildContext context) {
    return SizedBox(
        child: SizedBox(
      width: 100.w,
      child: ListView.builder(
        itemCount: filterNamesSearched.length,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemBuilder: (context, index) {
          return TextButton(
              onPressed: () {
                query = filterNamesSearched[index];
              },
              child: TextWidget(
                  textAlign: TextAlign.start,
                  text: filterNamesSearched[index],
                  fontSize: 18,
                  colorText: wColor.black));
        },
      ),
    ));
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return _emptyContainer(context);
    }

    filterCatBreedEntity = listCatBreedEntity.where((listEvent) {
      return listEvent.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (filterNamesSearched.isEmpty) {
      filterNamesSearched.add(query);
    } else {
      if (!filterNamesSearched.contains(query)) {
        filterNamesSearched.add(query);
      }
    }

    callEventSaveNamesAlreadySearched(context, filterNamesSearched);

    return SizedBox(
      child: ListView.builder(
          controller: scrollController,
          itemCount: filterCatBreedEntity.length,
          itemBuilder: (_, int index) {
            return CardCatWidget(
              nameCat: filterCatBreedEntity[index].name,
              imageUrlCat: filterCatBreedEntity[index].urlImage,
              countryOrigin: filterCatBreedEntity[index].origin,
              intelligent: filterCatBreedEntity[index].intelligence,
              onPressed: () {
                context.goNamed(detailPage, extra: filterCatBreedEntity[index]);
              },
            );
          }),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _emptyContainer(context);
    }

    filterCatBreedEntity = listCatBreedEntity.where((customAlbum) {
      return customAlbum.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return SizedBox(
      child: ListView.builder(
          controller: scrollController,
          itemCount: filterCatBreedEntity.length,
          itemBuilder: (_, int index) {
            return CardCatWidget(
              nameCat: filterCatBreedEntity[index].name,
              imageUrlCat: filterCatBreedEntity[index].urlImage,
              countryOrigin: filterCatBreedEntity[index].origin,
              intelligent: filterCatBreedEntity[index].intelligence,
              onPressed: () {
                context.goNamed(detailPage, extra: filterCatBreedEntity[index]);
              },
            );
          }),
    );
  }
}
