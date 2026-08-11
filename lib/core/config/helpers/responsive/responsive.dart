/// Legacy single breakpoint, consumed only by [AppCatsResponsiveApp].
///
/// Phase 8 replaces it with `WindowSize` (Material 3 breakpoints:
/// compact/medium/expanded/large) in `core/design_system/breakpoints.dart`.
///
/// The `isMobile`/`isAppleDevice`/`isDesktop` getters were removed in Phase 0:
/// they had zero usages, and the last two called `Platform.isMacOS` without a
/// `kIsWeb` guard, so they would have thrown on web. Removing them also drops
/// the `dart:io` dependency from this file.
bool isSmallScreen(double width) {
  return width < 640;
}

bool isLargeScreen(double width) {
  return !isSmallScreen(width);
}
