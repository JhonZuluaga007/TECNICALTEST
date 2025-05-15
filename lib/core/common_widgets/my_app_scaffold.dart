import 'package:flutter/material.dart';
import 'package:tecnical_test_pragma/core/config/theme/app_cats_colors.dart';

class MyAppScaffold extends StatelessWidget {
  const MyAppScaffold(
      {super.key,
      this.scrollDirection,
      required this.children,
      this.mainAxisAlignment,
      this.crossAxisAlignment,
      this.appBar,
      this.paddingColumn,
      this.backgroundColor,
      this.bottomSheet});
  final Axis? scrollDirection;
  final List<Widget> children;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final AppBar? appBar;
  final EdgeInsetsGeometry? paddingColumn;
  final Color? backgroundColor;
  final Widget? bottomSheet;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: backgroundColor ?? AppCatsColor().mapColors["BG"],
        appBar: appBar,
        body: Padding(
          padding: paddingColumn ?? EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.center,
            crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
            children: children,
          ),
        ),
        bottomSheet: bottomSheet,
      ),
    );
  }
}
