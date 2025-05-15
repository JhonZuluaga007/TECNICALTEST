import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tecnical_test_pragma/core/config/helpers/responsive/responsive.dart';

class AppCatsResponsiveApp extends StatelessWidget {
  const AppCatsResponsiveApp({super.key, required this.child});
  final Widget child;
  static const designSizeSmall = Size(390, 844);
  static const designSizeLarge = Size(1024, 800);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    if (isLargeScreen(screenSize.width)) {
      ScreenUtil.init(
        context,
        designSize: screenSize,
        splitScreenMode: kIsWeb,
      );
    }

    // DatePickerDialog(firstDate: ,lastDate: ,);

    return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaleFactor: 1.0,
          boldText: false,
        ),
        child: child);
  }
}
