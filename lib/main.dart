import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:tecnical_test_pragma/app_cats_responsive.dart';
import 'package:tecnical_test_pragma/core/injector/injector.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_image_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
import 'routers/app_route.dart';

/// Async as of Phase 5: `Injector.setup` awaits `getIt.reset()`, which runs the
/// registered dispose callbacks. The generated `init()` itself is synchronous, so
/// this does not make startup meaningfully slower — it makes teardown correct.
Future<void> main() async {
  await Injector.setup();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// One router for the lifetime of the widget.
  ///
  /// `AppRoute.getGoRouter()` used to be called three times inside `build`
  /// (parser, provider and delegate separately) and only worked because the
  /// getter memoized into a global static. With `routerConfig` it is one call.
  late final GoRouter _router = AppRoute.router();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LandingCatsBloc(
            // Resolution lives here, in the composition root, not inside the
            // bloc's constructor.
            getAllCatsUseCase: Injector.resolve<GetAllCatsUseCase>(),
          ),
        ),
        // Provided rather than resolved from the container inside `BreedImage`.
        // Each card builds its own `BreedImageCubit`, so the widget needs the use
        // case from somewhere; taking it from the tree instead of the service
        // locator keeps widget tests from having to boot the real DI graph.
        RepositoryProvider(
          create: (context) => Injector.resolve<GetBreedImageUseCase>(),
        ),
      ],
      child: ScreenUtilInit(
        minTextAdapt: true,
        // `useInheritedMediaQuery` was removed in Phase 1: it was a workaround
        // for Flutter <3.10 and is a no-op today.
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
            // TODO(phase 8): `ScreenUtil.init` inside `build` is a side effect
            // in the widget tree; it disappears when flutter_screenutil goes.
            ScreenUtil.init(context);
            // A `MediaQuery(...copyWith(alwaysUse24HourFormat: false))` used to
            // be here. Removed in Phase 1: it forced 12-hour formatting while
            // ignoring the system locale, and the app displays no times at all,
            // so it was dead configuration that also overrode a user setting.
            return AppCatsResponsiveApp(child: child!);
          },

          title: 'Catbreeds',
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        )),
      ),
    );
  }
}
