/// Breakpoint único heredado, consumido solo por [AppCatsResponsiveApp].
///
/// La Fase 8 lo reemplaza por `WindowSize` (breakpoints Material 3:
/// compact/medium/expanded/large) en `core/design_system/breakpoints.dart`.
///
/// Los getters `isMobile`/`isAppleDevice`/`isDesktop` se eliminaron en la
/// Fase 0: no tenían un solo uso y los dos últimos llamaban `Platform.isMacOS`
/// sin guard `kIsWeb`, así que habrían lanzado en web. Quitarlos también saca
/// la dependencia de `dart:io` de este archivo.
bool isSmallScreen(double width) {
  return width < 640;
}

bool isLargeScreen(double width) {
  return !isSmallScreen(width);
}
