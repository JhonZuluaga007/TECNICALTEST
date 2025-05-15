import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tecnical_test_pragma/core/common_widgets/breed_characteristic_widget.dart';
import 'package:tecnical_test_pragma/core/common_widgets/network_image.dart';
import 'package:tecnical_test_pragma/core/common_widgets/text/text_widget.dart';
import 'package:tecnical_test_pragma/core/config/theme/app_cats_colors.dart';

class CardCatWidget extends StatelessWidget {
  const CardCatWidget(
      {super.key,
      required this.nameCat,
      required this.imageUrlCat,
      required this.countryOrigin,
      required this.intelligent,
      required this.onPressed});
  final String nameCat;
  final String imageUrlCat;
  final String countryOrigin;
  final int intelligent;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final wColor = AppCatsColor();
    return Card(
      elevation: 2,
      surfaceTintColor: wColor.mapColors["W"],
      color: wColor.mapColors["W"],
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: wColor.black, width: 1)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: nameCat,
                  fontSize: 18,
                  colorText: wColor.black,
                ),
                TextButton(
                  style: ButtonStyle(
                      overlayColor: MaterialStatePropertyAll(wColor.black[30])),
                  onPressed: onPressed,
                  child: TextWidget(
                    text: "More...",
                    fontSize: 18,
                    colorText: wColor.black,
                  ),
                )
              ],
            ),
            SizedBox(height: 5.h),
            NetworkImageWidget(imageUrl: imageUrlCat),
            SizedBox(height: 5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextWidget(
                    text: countryOrigin,
                    fontSize: 18,
                    colorText: wColor.black,
                  ),
                ),
                BreedCharacteristicWidget(
                  width: 190.w,
                  nameCharacteristic: "Intelligence:",
                  value: intelligent,
                  radius: 10,
                  fontSize: 20,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
