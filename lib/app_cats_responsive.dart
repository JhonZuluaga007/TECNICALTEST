import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tecnical_test_pragma/core/config/helpers/responsive/responsive.dart';

class AppCatsResponsiveApp extends StatelessWidget {
  const AppCatsResponsiveApp({super.key, required this.child});
  final Widget child;
  static const designSizeSmall = Size(390, 844);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    if (isLargeScreen(screenSize.width)) {
      ScreenUtil.init(context, designSize: screenSize, splitScreenMode: kIsWeb);
    }

    // A `MediaQuery(data: ...copyWith(textScaleFactor: 1.0, boldText: false))`
    // used to live here. It was deliberately deleted in Phase 1 and NOT
    // migrated to `TextScaler`: the point of the original code was to cancel
    // the system's text scaling and bold-text settings, i.e. to disable two of
    // the user's accessibility preferences. Migrating it to
    // `TextScaler.noScaling` would have preserved the bug with newer syntax.
    //
    // Expected consequence: the app now respects the OS font size, which will
    // expose real layout overflows. Fixing those is Phase 8's job (tested at
    // 1.0 / 1.5 / 2.0).
    return child;
  }
}
