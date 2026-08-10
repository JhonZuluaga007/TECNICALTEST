import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tecnical_test_pragma/app_cats_responsive.dart';
import 'package:tecnical_test_pragma/core/injector/injector.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
import 'routers/app_route.dart';

void main() {
  Injector.setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => LandingCatsBloc())],
      child: ScreenUtilInit(
        minTextAdapt: true,
        // `useInheritedMediaQuery` se quitó en la Fase 1: era un workaround
        // para Flutter <3.10 y hoy es un no-op.
        designSize: AppCatsResponsiveApp.designSizeSmall,
        builder: ((context, child) => MaterialApp.router(
          // localizationsDelegates: const [
          //   GlobalMaterialLocalizations.delegate,
          //   GlobalWidgetsLocalizations.delegate,
          //   GlobalCupertinoLocalizations.delegate,
          // ],
          // supportedLocales: const [
          //   Locale('en', 'US'),
          //   Locale('es', 'ES'),
          // ],
          builder: (context, child) {
            // TODO(fase 8): `ScreenUtil.init` dentro de `build` es un
            // efecto secundario en el árbol de widgets; desaparece al
            // eliminar flutter_screenutil.
            ScreenUtil.init(context);
            // Aquí había un `MediaQuery(...copyWith(alwaysUse24HourFormat:
            // false))`. Se eliminó en la Fase 1: forzaba formato de 12
            // horas ignorando el locale del sistema, y la app no muestra
            // ninguna hora, así que era configuración muerta que además
            // sobreescribía un ajuste del usuario.
            return AppCatsResponsiveApp(child: child!);
          },

          title: 'Catbreeds',
          routeInformationParser: AppRoute.getGoRouter().routeInformationParser,
          routeInformationProvider:
              AppRoute.getGoRouter().routeInformationProvider,
          routerDelegate: AppRoute.getGoRouter().routerDelegate,
          debugShowCheckedModeBanner: false,
        )),
      ),
    );
  }
}
