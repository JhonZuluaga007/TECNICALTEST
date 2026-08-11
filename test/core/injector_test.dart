import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kiwi/kiwi.dart';
import 'package:tecnical_test_pragma/core/injector/injector.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_data_source.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/repository/landing_cats_repository_impl.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/repository/landing_cats_repository.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart';

/// A registration mistake is a runtime-only crash that no other kind of test
/// catches. Cheap and high value: these assertions are also the contract Phase 5
/// (get_it + injectable) has to preserve.
void main() {
  tearDown(Injector.reset);

  group('Injector', () {
    test('resolves the whole graph without throwing', () {
      Injector.setup();

      expect(Injector.resolve<http.Client>(), isNotNull);
      expect(Injector.resolve<LandingCatsDataSource>(), isNotNull);
      expect(Injector.resolve<LandingCatsRepository>(), isNotNull);
      expect(Injector.resolve<GetAllCatsUseCase>(), isNotNull);
    });

    test('binds the repository abstraction to its implementation', () {
      Injector.setup();

      expect(
        Injector.resolve<LandingCatsRepository>(),
        isA<LandingCatsRepositoryImpl>(),
      );
    });

    test('http.Client is a singleton and everything else is a factory', () {
      Injector.setup();

      // One connection pool for the whole app.
      expect(
        Injector.resolve<http.Client>(),
        same(Injector.resolve<http.Client>()),
      );

      // And everything else stays a factory, exactly as the generator
      // registered it. Phase 6 needs the REPOSITORY to become a singleton for its
      // TTL cache to ever hit; if this assertion changes there, it is deliberate.
      expect(
        Injector.resolve<GetAllCatsUseCase>(),
        isNot(same(Injector.resolve<GetAllCatsUseCase>())),
      );
      expect(
        Injector.resolve<LandingCatsRepository>(),
        isNot(same(Injector.resolve<LandingCatsRepository>())),
      );
    });

    test('injects the provided http.Client into the datasource', () {
      final client = http.Client();
      addTearDown(client.close);

      Injector.setup(httpClient: client);

      expect(Injector.resolve<http.Client>(), same(client));
    });

    test('setup() is idempotent', () {
      // kiwi throws `KiwiError` on duplicate registration, so without the
      // `clear()` that `setup()` performs, a second boot in the same isolate
      // crashes — which is exactly what happens with more than one test file.
      Injector.setup();
      expect(Injector.setup, returnsNormally);
      expect(Injector.resolve<GetAllCatsUseCase>(), isNotNull);
    });

    test('reset() leaves the container empty', () {
      Injector.setup();
      Injector.reset();

      expect(
        () => Injector.resolve<GetAllCatsUseCase>(),
        throwsA(isA<KiwiError>()),
      );
    });
  });
}
