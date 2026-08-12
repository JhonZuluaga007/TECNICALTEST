import 'package:http/http.dart' as http;
import 'package:kiwi/kiwi.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_data_source.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/repository/landing_cats_repository_impl.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/repository/landing_cats_repository.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_image_use_case.dart';

/// The app's composition root.
///
/// Registrations are hand-written. Phase 2 removed `kiwi_generator` (and with it
/// `build_runner`) because it pinned `analyzer ^6.0.0`, which is incompatible
/// with the `analyzer >=8.0.0 <13.0.0` required by the `test` package that
/// `bloc_test` depends on. The generator produced these same 4 lines.
///
/// Phase 5 replaces kiwi with `get_it` + `injectable`.
abstract final class Injector {
  static final KiwiContainer container = KiwiContainer();

  /// Registers the dependency graph. Idempotent on purpose: kiwi throws
  /// `KiwiError` when a type is registered twice, so the container has to be
  /// cleared first or a second `setup()` in the same isolate crashes — which is
  /// exactly what happens as soon as more than one test file touches it.
  ///
  /// [httpClient] exists so integration tests can inject a `MockClient` and boot
  /// the whole app without network access.
  static void setup({http.Client? httpClient}) {
    container.clear();
    container
      // Singleton: one connection pool for the whole app. With
      // `registerFactory` every resolve would build a brand new `http.Client`.
      ..registerSingleton<http.Client>((c) => httpClient ?? http.Client())
      ..registerSingleton(
        (c) => LandingCatsDataSource(client: c.resolve<http.Client>()),
      )
      // Singleton, and Phase 4 made that a **correctness** requirement rather
      // than a nicety: the repository holds the resolved image-URL cache and the
      // in-flight request map. As a factory, every `resolve()` handed out a fresh
      // empty cache, so nothing would ever be cached or de-duplicated.
      ..registerSingleton<LandingCatsRepository>(
        (c) => LandingCatsRepositoryImpl(
          landingCatsDataSource: c.resolve<LandingCatsDataSource>(),
        ),
      )
      ..registerFactory(
        (c) => GetAllCatsUseCase(
          landingCatsRepository: c.resolve<LandingCatsRepository>(),
        ),
      )
      ..registerFactory(
        (c) => GetBreedImageUseCase(
          landingCatsRepository: c.resolve<LandingCatsRepository>(),
        ),
      );
  }

  static T resolve<T>([String? name]) => container.resolve<T>(name);

  /// Empties the container. For test isolation.
  static void reset() => container.clear();
}
