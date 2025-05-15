import 'dart:io';

import 'package:flutter/foundation.dart';

bool get isMobile {
  if (kIsWeb) {
    return false;
  }
  return Platform.isAndroid || Platform.isIOS;
}

bool get isAppleDevice {
  return Platform.isMacOS || Platform.isIOS;
}

bool get isDesktop {
  return Platform.isMacOS || Platform.isWindows;
}

bool isSmallScreen(double width) {
  return width < 640;
}

bool isLargeScreen(double width) {
  return !isSmallScreen(width);
}
