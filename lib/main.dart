import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tecnical_test_pragma/core/design_system/app_theme.dart';
import 'package:tecnical_test_pragma/core/injector/injector.dart';
import 'package:tecnical_test_pragma/features/settings/presentation/bloc/theme_mode_cubit.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_by_id_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_image_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
import 'routers/app_route.dart';

/// Async as of Phase 5: `Injector.setup` awaits `getIt.reset()`, which runs the
/// registered dispose callbacks. The generated `init()` itself is synchronous, so
/// this does not make startup meaningfully slower — it makes teardown correct.
///
/// Phase 6 adds the one piece of real startup I/O: opening the storage box.
Future<void> main() async {
  // Required before `path_provider`: it is a plugin, and plugin channels need the
  // binding. It has to come before `HydratedStorage.build`, not before `runApp`.
  WidgetsFlutterBinding.ensureInitialized();

  await Injector.setup(storage: await _buildStorage());
  runApp(const MyApp());
}

/// The app's persistent storage: the bloc's search history, and the breeds cache.
///
/// `getApplicationDocumentsDirectory`, **not** `getTemporaryDirectory` — which is
/// what hydrated_bloc's own example uses. The search history is something the user
/// created, and the OS is free to empty the temp directory whenever it wants
/// space. The breeds cache living in the same box is fine either way: it carries a
/// TTL and rebuilds itself in one request.
Future<Storage> _buildStorage() async => HydratedStorage.build(
  storageDirectory: kIsWeb
      ? HydratedStorageDirectory.web
      : HydratedStorageDirectory(
          (await getApplicationDocumentsDirectory()).path,
        ),
);

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
          // `lazy: false` is load-bearing, and it was not obvious: `BlocProvider`
          // defaults to building on first read, so with the default the `add`
          // below would not run until `LandingPage` first looked the bloc up —
          // i.e. after the splash, which is exactly the timing this phase set out
          // to improve. Measured in `app_test.dart`, which asserts the request has
          // happened while the splash is still on screen.
          lazy: false,
          create: (context) =>
              LandingCatsBloc(
                  // Resolution lives here, in the composition root, not inside the
                  // bloc's constructor.
                  getAllCatsUseCase: Injector.resolve<GetAllCatsUseCase>(),
                  storage: Injector.resolve<Storage>(),
                )
                // Phase 6: the fetch is dispatched **once, here**, instead of in
                // `LandingPage.initState`. go_router rebuilds that page on every
                // return from the detail screen, so the old placement refetched the
                // whole list every time the user pressed back. Here it runs once per
                // app launch — during the splash, so the five seconds are no longer
                // dead time.
                //
                // Cheap by design: the repository answers from the disk cache when it
                // is fresh, so this is usually zero requests, not one.
                ..add(const AllCatsEvent()),
        ),
        // Provided rather than resolved from the container inside `BreedImage`.
        // Each card builds its own `BreedImageCubit`, so the widget needs the use
        // case from somewhere; taking it from the tree instead of the service
        // locator keeps widget tests from having to boot the real DI graph.
        RepositoryProvider(
          create: (context) => Injector.resolve<GetBreedImageUseCase>(),
        ),
        // Same reasoning, for the detail screen's cubit. Phase 6.
        RepositoryProvider(
          create: (context) => Injector.resolve<GetBreedByIdUseCase>(),
        ),
        // Phase 7. Above the `MaterialApp`, because the theme it decides is an
        // argument to it — a provider inside the app could not change it.
        //
        // It shares the one storage box the app already opens: a second
        // `HydratedStorage` would mean a second thing to initialise and close,
        // and this is one enum.
        BlocProvider(
          create: (context) =>
              ThemeModeCubit(storage: Injector.resolve<Storage>()),
        ),
      ],
      // Phase 8 removed the two wrappers that used to sit here. `ScreenUtilInit`
      // is gone with the package, and so is the `builder:` below it, which
      // existed only to call `ScreenUtil.init(context)` — a side effect run from
      // inside a `build`, on every frame, to configure a global.
      //
      // What replaced them is nothing: layout now reads `MediaQuery.sizeOf`
      // where it needs to, through `WindowSize`. A `MaterialApp.builder` that
      // wraps every route is the wrong place for a decision only one screen
      // makes.
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          // Phase 7. This block sat here commented out since before Phase 0; the
          // list it named by hand is exactly what `AppLocalizations` now exposes,
          // with the app's own delegate added and the supported locales derived
          // from the ARB files rather than restated.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          // `onGenerateTitle`, not `title`: the value now comes from the ARBs, so
          // it needs a context that has the delegates above it. That is exactly
          // what this callback provides, and it re-runs on a locale change.
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
