import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_image_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
import 'package:tecnical_test_pragma/routers/app_route.dart';

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
  LandingCatsBloc buildBloc(GetAllCatsUseCase getAllCatsUseCase) {
    final bloc = LandingCatsBloc(getAllCatsUseCase: getAllCatsUseCase);
    addTearDown(bloc.close);
    return bloc;
  }

  /// Mounts [child] inside a bare `MaterialApp`.
  ///
  /// Deliberately does NOT use `ScreenUtilInit`: `ScreenUtil` is already
  /// configured globally in `flutter_test_config.dart`, and `ScreenUtilInit`'s
  /// two-phase startup (it returns `SizedBox.shrink()` until a
  /// `didChangeDependencies` and a `FutureBuilder` both resolve) would only
  /// complicate every pump.
  /// The image use case every card needs, defaulting to a network-free fake.
  ///
  /// Phase 4 made this necessary: each card paints a `BreedImage`, which builds a
  /// `BreedImageCubit` from the `GetBreedImageUseCase` it finds in the tree. It
  /// comes from a `RepositoryProvider` rather than from `Injector.resolve()`
  /// precisely so that tests can supply it here instead of booting the real DI
  /// graph and the real network.
  Future<void> pumpAppWith(
    Widget child, {
    LandingCatsBloc? bloc,
    GetBreedImageUseCase? imageUseCase,
  }) {
    Widget withImageUseCase(Widget inner) =>
        RepositoryProvider<GetBreedImageUseCase>.value(
          value: imageUseCase ?? FakeGetBreedImageUseCase(),
          child: inner,
        );

    if (bloc == null) {
      return pumpWidget(withImageUseCase(MaterialApp(home: child)));
    }

    return pumpWidget(
      withImageUseCase(
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
  }) {
    final router = AppRoute.router(initialLocation: initialLocation);
    addTearDown(router.dispose);

    return pumpWidget(
      RepositoryProvider<GetBreedImageUseCase>.value(
        value: imageUseCase ?? FakeGetBreedImageUseCase(),
        child: BlocProvider<LandingCatsBloc>.value(
          value: bloc,
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
  }
}
