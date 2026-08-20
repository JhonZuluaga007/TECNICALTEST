import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_by_id_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_image_use_case.dart';
import 'package:tecnical_test_pragma/core/design_system/app_theme.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
import 'package:tecnical_test_pragma/features/settings/presentation/bloc/theme_mode_cubit.dart';
import 'package:tecnical_test_pragma/l10n/app_localizations.dart';
import 'package:tecnical_test_pragma/routers/app_route.dart';

import 'in_memory_key_value_store.dart';
import 'window_size.dart' as window;
import 'mocks.dart';

extension PumpApp on WidgetTester {
  /// Builds the bloc and schedules its closure.
  ///
  /// **Always use this in widget tests, and NEVER create the bloc in a
  /// `setUp`.** `setUp` runs outside `testWidgets`' `FakeAsync` zone, so the
  /// bloc's internal microtasks stay bound to the real zone and
  /// `pump`/`pumpAndSettle` never drain them: the state stays stuck on
  /// `FormSubmitting`, the `CircularProgressIndicator` animates forever, and
  /// `pumpAndSettle` ends in "timed out". It fails just as confusingly for any
  /// bloc with an `async` handler.
  ///
  /// Phase 6: a fresh [InMemoryStorage] per call unless one is passed, so no
  /// widget test touches a disk or shares a store with the test before it.
  ///
  /// [fetchOnBuild] dispatches `AllCatsEvent` the way `main.dart` does. It is
  /// **opt-in and explicit** because Phase 6 moved that dispatch out of
  /// `LandingPage.initState`, where it refetched the whole list on every return
  /// from the detail screen. A test that wants breeds now has to say so, which is
  /// also more honest than depending on a side effect of mounting a widget.
  LandingCatsBloc buildBloc(
    GetAllCatsUseCase getAllCatsUseCase, {
    Storage? storage,
    bool fetchOnBuild = false,
  }) {
    final bloc = LandingCatsBloc(
      getAllCatsUseCase: getAllCatsUseCase,
      storage: storage ?? InMemoryStorage(),
    );
    addTearDown(bloc.close);
    if (fetchOnBuild) bloc.add(const AllCatsEvent());
    return bloc;
  }

  /// The two use cases widgets look up from the tree, defaulting to network-free
  /// fakes.
  ///
  /// `BreedImage` needs the first (Phase 4) and `DetailCatPage` the second
  /// (Phase 6). Both come from a `RepositoryProvider` rather than from
  /// `Injector.resolve()` precisely so widget tests can supply them here instead of
  /// booting the real DI graph and the real network.
  Widget _withUseCases(
    Widget inner, {
    GetBreedImageUseCase? imageUseCase,
    GetBreedByIdUseCase? breedByIdUseCase,
  }) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<GetBreedImageUseCase>.value(
        value: imageUseCase ?? FakeGetBreedImageUseCase(),
      ),
      RepositoryProvider<GetBreedByIdUseCase>.value(
        value: breedByIdUseCase ?? FakeGetBreedByIdUseCase(),
      ),
      // Phase 7. The landing app bar reads this cubit, and it is cheap enough to
      // provide unconditionally rather than make every caller remember which
      // widgets need it.
      BlocProvider<ThemeModeCubit>(
        create: (_) => ThemeModeCubit(storage: InMemoryStorage()),
      ),
    ],
    child: inner,
  );

  /// The `MaterialApp` every pump goes through.
  ///
  /// Phase 7 put the theme and the localization delegates here, in one place. A
  /// widget calling `AppLocalizations.of(context)` or `Theme.of(context).cats`
  /// under a bare `MaterialApp` crashes — deliberately, see `CatsTokens` — so
  /// every widget test in the suite depends on this method rather than on each
  /// test remembering.
  ///
  /// [locale] is fixed to English by default so assertions can match on copy.
  /// Pass `Locale('es')` to prove a lookup is real rather than a hardcoded string
  /// that happens to be in the ARB.
  MaterialApp _app(
    Widget home, {
    required Locale locale,
    ThemeMode? themeMode,
  }) => MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: home,
  );

  /// Mounts [child] inside a bare `MaterialApp`.
  ///
  /// Phase 8: this used to carry a paragraph explaining why it deliberately
  /// avoided `ScreenUtilInit` and its two-phase startup. The package is gone, so
  /// there is nothing left to avoid — a `MaterialApp` renders on the first pump.
  ///
  /// [windowSize] defaults to a **phone**, not to `flutter_test`'s 800x600. That
  /// default is a `WindowSize.medium` window, so leaving it alone would have
  /// pointed the whole suite at the two-column grid and left the one-column list
  /// — what a phone shows — untested. See `window_size.dart`.
  Future<void> pumpAppWith(
    Widget child, {
    LandingCatsBloc? bloc,
    GetBreedImageUseCase? imageUseCase,
    GetBreedByIdUseCase? breedByIdUseCase,
    Locale locale = const Locale('en'),
    ThemeMode? themeMode,
    Size windowSize = window.phone,
  }) {
    window.setWindowSize(this, windowSize);

    Widget wrap(Widget inner) => _withUseCases(
      inner,
      imageUseCase: imageUseCase,
      breedByIdUseCase: breedByIdUseCase,
    );

    final app = _app(child, locale: locale, themeMode: themeMode);

    if (bloc == null) {
      return pumpWidget(wrap(app));
    }

    return pumpWidget(
      wrap(BlocProvider<LandingCatsBloc>.value(value: bloc, child: app)),
    );
  }

  /// Mounts the real app with go_router, for navigation tests.
  Future<void> pumpRouter({
    required LandingCatsBloc bloc,
    String initialLocation = '/',
    GetBreedImageUseCase? imageUseCase,
    GetBreedByIdUseCase? breedByIdUseCase,
    Locale locale = const Locale('en'),
    Size windowSize = window.phone,
  }) {
    window.setWindowSize(this, windowSize);
    final router = AppRoute.router(initialLocation: initialLocation);
    addTearDown(router.dispose);

    return pumpWidget(
      _withUseCases(
        BlocProvider<LandingCatsBloc>.value(
          value: bloc,
          // Phase 7: same theme and delegates as `_app`, but `MaterialApp.router`
          // takes a `routerConfig` instead of a `home`, so the two cannot share a
          // constructor call.
          child: MaterialApp.router(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            routerConfig: router,
          ),
        ),
        imageUseCase: imageUseCase,
        breedByIdUseCase: breedByIdUseCase,
      ),
    );
  }
}
