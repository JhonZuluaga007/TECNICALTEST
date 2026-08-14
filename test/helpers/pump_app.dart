import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_by_id_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_image_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
import 'package:tecnical_test_pragma/routers/app_route.dart';

import 'in_memory_key_value_store.dart';
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
    ],
    child: inner,
  );

  /// Mounts [child] inside a bare `MaterialApp`.
  ///
  /// Deliberately does NOT use `ScreenUtilInit`: `ScreenUtil` is already
  /// configured globally in `flutter_test_config.dart`, and `ScreenUtilInit`'s
  /// two-phase startup (it returns `SizedBox.shrink()` until a
  /// `didChangeDependencies` and a `FutureBuilder` both resolve) would only
  /// complicate every pump.
  Future<void> pumpAppWith(
    Widget child, {
    LandingCatsBloc? bloc,
    GetBreedImageUseCase? imageUseCase,
    GetBreedByIdUseCase? breedByIdUseCase,
  }) {
    Widget wrap(Widget inner) => _withUseCases(
      inner,
      imageUseCase: imageUseCase,
      breedByIdUseCase: breedByIdUseCase,
    );

    if (bloc == null) {
      return pumpWidget(wrap(MaterialApp(home: child)));
    }

    return pumpWidget(
      wrap(
        BlocProvider<LandingCatsBloc>.value(
          value: bloc,
          child: MaterialApp(home: child),
        ),
      ),
    );
  }

  /// Mounts the real app with go_router, for navigation tests.
  Future<void> pumpRouter({
    required LandingCatsBloc bloc,
    String initialLocation = '/',
    GetBreedImageUseCase? imageUseCase,
    GetBreedByIdUseCase? breedByIdUseCase,
  }) {
    final router = AppRoute.router(initialLocation: initialLocation);
    addTearDown(router.dispose);

    return pumpWidget(
      _withUseCases(
        BlocProvider<LandingCatsBloc>.value(
          value: bloc,
          child: MaterialApp.router(routerConfig: router),
        ),
        imageUseCase: imageUseCase,
        breedByIdUseCase: breedByIdUseCase,
      ),
    );
  }
}
