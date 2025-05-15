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
          useInheritedMediaQuery: true,
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
                  ScreenUtil.init(context);
                  final mediaQuery = MediaQuery.of(context);
                  return MediaQuery(
                      data: mediaQuery.copyWith(
                        alwaysUse24HourFormat: false,
                      ),
                      child: AppCatsResponsiveApp(child: child!));
                },

                title: 'enMedallo',
                routeInformationParser:
                    AppRoute.getGoRouter().routeInformationParser,
                routeInformationProvider:
                    AppRoute.getGoRouter().routeInformationProvider,
                routerDelegate: AppRoute.getGoRouter().routerDelegate,
                debugShowCheckedModeBanner: false,
              ))),
    );
  }
}
