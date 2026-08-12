// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:tecnical_test_pragma/core/injector/injector.dart' as _i931;
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_data_source.dart'
    as _i65;
import 'package:tecnical_test_pragma/features/landing_cats/data/repository/landing_cats_repository_impl.dart'
    as _i100;
import 'package:tecnical_test_pragma/features/landing_cats/domain/repository/landing_cats_repository.dart'
    as _i308;
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_all_cats_use_case.dart'
    as _i1059;
import 'package:tecnical_test_pragma/features/landing_cats/domain/use_cases/get_breed_image_use_case.dart'
    as _i635;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.lazySingleton<_i519.Client>(
      () => appModule.client(),
      dispose: _i931.closeHttpClient,
    );
    gh.lazySingleton<_i65.LandingCatsDataSource>(
      () => appModule.dataSource(gh<_i519.Client>()),
    );
    gh.lazySingleton<_i308.LandingCatsRepository>(
      () => _i100.LandingCatsRepositoryImpl(
        landingCatsDataSource: gh<_i65.LandingCatsDataSource>(),
      ),
    );
    gh.factory<_i1059.GetAllCatsUseCase>(
      () => _i1059.GetAllCatsUseCase(
        landingCatsRepository: gh<_i308.LandingCatsRepository>(),
      ),
    );
    gh.factory<_i635.GetBreedImageUseCase>(
      () => _i635.GetBreedImageUseCase(
        landingCatsRepository: gh<_i308.LandingCatsRepository>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i931.AppModule {}
