import 'package:flutter/material.dart';
import 'package:tecnical_test_pragma/core/config/helpers/responsive/responsive.dart';

extension ResponsiveExtensions on BuildContext {
  ResponsiveScreenManager get screen => ResponsiveScreenManager(this);
}

class ResponsiveScreenManager {
  ResponsiveScreenManager(this.context);
  final BuildContext context;

  bool get isLarge {
    return isLargeScreen(MediaQuery.of(context).size.width);
  }

  bool get isSmall {
    return isSmallScreen(MediaQuery.of(context).size.width);
  }
}
