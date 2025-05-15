import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:tecnical_test_pragma/cats_icons.dart';
import 'package:tecnical_test_pragma/core/common_widgets/my_app_scaffold.dart';
import 'package:tecnical_test_pragma/core/common_widgets/text/text_widget.dart';
import 'package:tecnical_test_pragma/core/config/theme/app_cats_colors.dart';
import 'package:tecnical_test_pragma/routers/routers.dart';

class SplashCatBreeds extends StatefulWidget {
  const SplashCatBreeds({super.key});

  @override
  State<SplashCatBreeds> createState() => _SplashCatBreedsState();
}

class _SplashCatBreedsState extends State<SplashCatBreeds> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  startTimer() async {
    var duration = const Duration(seconds: 5);
    return Timer(duration, route);
  }

  route() {
    context.goNamed(homePage);
  }

  @override
  Widget build(BuildContext context) {
    final wColor = AppCatsColor();
    return MyAppScaffold(
      backgroundColor: wColor.mapColors["W"],
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      paddingColumn: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      bottomSheet: Container(
        color: wColor.mapColors["W"],
        child: Image.asset(CatsIcons.imageCatSplash, width: 200.w, height: 300),
      ),
      children: [
        Center(
          child: TextWidget(
              text: "Catbreeds",
              fontSize: 42,
              fontWeight: FontWeight.bold,
              colorText: wColor.black),
        ),
        SizedBox(
          height: 170.h,
        )
      ],
    );
  }
}
