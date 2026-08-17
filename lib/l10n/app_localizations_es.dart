// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Catbreeds';

  @override
  String get searchHint => 'Busca por el nombre';

  @override
  String get moreAction => 'Ver más...';

  @override
  String countryLabel(String origin) {
    return 'País: $origin';
  }

  @override
  String lifeSpanLabel(String lifeSpan) {
    return 'Esperanza de vida: $lifeSpan años';
  }

  @override
  String get intelligenceLabel => 'Inteligencia:';

  @override
  String get adaptabilityLabel => 'Adaptabilidad:';

  @override
  String get toggleTheme => 'Cambiar tema';

  @override
  String get emptyBreeds => 'No hay razas de gato para mostrar.';

  @override
  String get retry => 'Reintentar';

  @override
  String get refresh => 'Actualizar';

  @override
  String staleBanner(String reason) {
    return 'Mostrando razas guardadas. $reason';
  }

  @override
  String get failureNetwork =>
      'Sin conexión a internet. Revisa tu red e inténtalo de nuevo.';

  @override
  String get failureTimeout =>
      'La solicitud tardó demasiado. Inténtalo de nuevo.';

  @override
  String get failureAuth => 'No se pudo autenticar con el servicio de gatos.';

  @override
  String failureServer(int statusCode) {
    return 'El servicio de gatos falló ($statusCode). Inténtalo más tarde.';
  }

  @override
  String get failureUnexpected =>
      'El servicio de gatos devolvió algo inesperado.';

  @override
  String get failureNotFound => 'No pudimos encontrar esa raza de gato.';

  @override
  String get failureUnknown => 'Algo salió mal. Inténtalo de nuevo.';
}
