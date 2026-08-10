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

    // Aquí vivía un `MediaQuery(data: ...copyWith(textScaleFactor: 1.0,
    // boldText: false))`. Se eliminó a propósito en la Fase 1, y NO se migró a
    // `TextScaler`: el objetivo del código original era anular el escalado de
    // texto y la negrita del sistema, o sea desactivar dos ajustes de
    // accesibilidad del usuario. Migrarlo a `TextScaler.noScaling` habría
    // conservado el bug con sintaxis nueva.
    //
    // Consecuencia esperada: la app ahora respeta el tamaño de fuente del SO,
    // lo que expondrá desbordes reales de layout. Arreglarlos es trabajo de la
    // Fase 8 (se prueba a 1.0 / 1.5 / 2.0).
    return child;
  }
}
