import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_data_source.dart';

import 'injector.config.dart';

/// The service locator. Exposed for the generated `init()` extension; application
/// code goes through [Injector] instead.
final GetIt getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: false)
void _configure() => getIt.init();

/// Closes the HTTP client when the container is reset or the registration is
/// replaced.
///
/// **Public on purpose.** The generated `injector.config.dart` is a separate
/// library, so it cannot reference a private top-level function — a `_closeClient`
/// would not compile.
///
/// This callback is the concrete thing get_it bought over kiwi: kiwi has no
/// dispose hook at all, so the app's `http.Client` was never closed, in production
/// or between test files. Awaiting these callbacks is also why [Injector.setup] is
/// asynchronous.
/// A block body, not an arrow: `http.Client.close()` returns `void`, which cannot
/// be returned from a `FutureOr<void>` function.
FutureOr<void> closeHttpClient(http.Client client) {
  client.close();
}

/// Registrations that cannot be expressed as an annotation on their own class.
///
/// Everything else in the graph is annotated where it is declared, which is the
/// point of injectable: a missing binding becomes a build failure instead of a
/// runtime error on the screen that needed it.
@module
abstract class AppModule {
  /// One connection pool for the whole app.
  ///
  /// `http.Client` is a third-party type, so there is nothing to annotate.
  @LazySingleton(dispose: closeHttpClient)
  http.Client client() => http.Client();

  /// Deliberately registered here rather than annotated on the class.
  ///
  /// `LandingCatsDataSource`'s constructor also takes `timeout` and `retryDelays`.
  /// Those are **test seams**, not dependencies — injectable would try to resolve a
  /// `Duration` and a `List<Duration>` from the container and fail the build.
  /// Naming only `client` here keeps their production defaults intact.
  @lazySingleton
  LandingCatsDataSource dataSource(http.Client client) =>
      LandingCatsDataSource(client: client);
}

/// The app's composition root.
///
/// Phase 5 replaced `kiwi` with `get_it` + `injectable`. Phase 2 had removed
/// `kiwi_generator` because it pinned `analyzer ^6.0.0` and made `bloc_test`
/// impossible to install, leaving the registrations hand-written; that debt is
/// settled here with a generator that resolves alongside `freezed`.
///
/// The facade survives the migration so that `main.dart`, `app_test.dart` and
/// `injector_test.dart` keep the same three-method contract, and so that `get_it`
/// is imported in exactly one file of `lib/`.
abstract final class Injector {
  /// Builds the dependency graph.
  ///
  /// Idempotent on purpose. `getIt` is a process-wide singleton, so a second
  /// `setup()` in the same isolate — which happens as soon as two test files touch
  /// it — would throw on duplicate registration. kiwi needed the same guard, via
  /// `container.clear()`.
  ///
  /// [httpClient] exists so integration tests can inject a `MockClient` and boot
  /// the whole app without network access.
  static Future<void> setup({http.Client? httpClient}) async {
    await getIt.reset();
    _configure();

    if (httpClient == null) return;

    // Overriding AFTER `init()` is safe because every registration is a
    // `lazySingleton`: `init()` constructs nothing, so no consumer has captured
    // the real client yet. That invariant is load-bearing and has its own test —
    // a single `@singleton` anywhere in the graph would break it silently.
    //
    // `registerSingleton`, not `registerLazySingleton`: the caller already built
    // this instance, so there is nothing to defer. It also makes disposal
    // deterministic — get_it only runs a dispose callback for a singleton whose
    // instance exists, so a lazy registration that no test ever resolved would
    // never be closed.
    await getIt.unregister<http.Client>();
    getIt.registerSingleton<http.Client>(
      httpClient,
      // The same dispose as the real one: the container closes whatever client it
      // holds, whoever provided it. Closing an `http.Client` twice is harmless, so
      // a caller that also closes its own is fine.
      dispose: closeHttpClient,
    );
  }

  static T resolve<T extends Object>() => getIt<T>();

  /// Empties the container, running every registered dispose callback.
  ///
  /// For test isolation, and the reason this returns a `Future`.
  static Future<void> reset() => getIt.reset();
}
