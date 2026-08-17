import 'package:flutter/material.dart';

class MyAppScaffold extends StatelessWidget {
  const MyAppScaffold({
    super.key,
    this.scrollDirection,
    required this.children,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.appBar,
    this.paddingColumn,
    this.backgroundColor,
    this.bottomSheet,
  });
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
        // Phase 7: the fallback used to be a hardcoded light grey, which is
        // exactly the value a `Scaffold` already takes from
        // `ThemeData.scaffoldBackgroundColor` — and the hardcoded one would have
        // stayed light in dark mode. Passing null defers to the theme.
        backgroundColor: backgroundColor,
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
