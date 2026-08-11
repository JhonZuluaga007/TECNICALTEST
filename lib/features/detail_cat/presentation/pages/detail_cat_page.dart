import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tecnical_test_pragma/core/common_widgets/my_app_scaffold.dart';
import 'package:tecnical_test_pragma/core/common_widgets/network_image.dart';
import 'package:tecnical_test_pragma/core/common_widgets/text/text_widget.dart';
import 'package:tecnical_test_pragma/core/config/theme/app_cats_colors.dart';
import 'package:tecnical_test_pragma/features/detail_cat/presentation/widgets/list_characteristics_catbreeds_widget.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';

class DetailCatPage extends StatefulWidget {
  const DetailCatPage({super.key, required this.catBreedEntity});
  final CatBreedEntity catBreedEntity;

  @override
  State<DetailCatPage> createState() => _DetailCatPageState();
}

class _DetailCatPageState extends State<DetailCatPage> {
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wColor = AppCatsColor();
    return MyAppScaffold(
      paddingColumn: EdgeInsets.symmetric(horizontal: 15.w),
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: TextWidget(
          text: widget.catBreedEntity.name,
          fontSize: 24,
          colorText: wColor.black,
        ),
      ),
      children: [
        Center(
          child: NetworkImageWidget(
            height: (MediaQuery.of(context).size.height / 2).h,
            imageUrl: widget.catBreedEntity.urlImage,
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: widget.catBreedEntity.description,
                    fontSize: 20,
                    colorText: wColor.black,
                  ),
                  SizedBox(height: 8.h),
                  TextWidget(
                    textAlign: TextAlign.start,
                    text: "Country: ${widget.catBreedEntity.origin}",
                    fontSize: 20,
                    colorText: wColor.black,
                  ),
                  SizedBox(height: 8.h),
                  TextWidget(
                    text: "LifeSpan: ${widget.catBreedEntity.lifeSpan} years",
                    fontSize: 20,
                    colorText: wColor.black,
                  ),
                  SizedBox(height: 8.h),
                  ListCharacteristicsCatbreeds(
                    characteristics: [
                      (
                        label: "Intelligence:",
                        value: widget.catBreedEntity.intelligence,
                      ),
                      (
                        label: "Adaptability:",
                        value: widget.catBreedEntity.adaptability,
                      ),
                    ],
                    fontSize: 20,
                    radius: 12,
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
