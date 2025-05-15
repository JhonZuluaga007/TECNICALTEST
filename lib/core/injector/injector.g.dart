// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'injector.dart';

// **************************************************************************
// KiwiInjectorGenerator
// **************************************************************************

class _$Injector extends Injector {
  @override
  void _configureAuthFactoriesFactories() {
    final KiwiContainer container = KiwiContainer();
    container
      ..registerFactory((c) => LandingCatsDataSource())
      ..registerFactory<LandingCatsRepository>((c) => LandingCatsRepositoryImpl(
          landingCatsDataSource: c<LandingCatsDataSource>()))
      ..registerFactory((c) =>
          GetAllCatsUseCase(landingCatsRepository: c<LandingCatsRepository>()));
  }
}
