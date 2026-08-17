// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Catbreeds';

  @override
  String get searchHint => 'Search by the name';

  @override
  String get moreAction => 'More...';

  @override
  String countryLabel(String origin) {
    return 'Country: $origin';
  }

  @override
  String lifeSpanLabel(String lifeSpan) {
    return 'LifeSpan: $lifeSpan years';
  }

  @override
  String get intelligenceLabel => 'Intelligence:';

  @override
  String get adaptabilityLabel => 'Adaptability:';

  @override
  String get toggleTheme => 'Change theme';

  @override
  String get emptyBreeds => 'No cat breeds to show.';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String staleBanner(String reason) {
    return 'Showing saved breeds. $reason';
  }

  @override
  String get failureNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get failureTimeout => 'The request took too long. Try again.';

  @override
  String get failureAuth => 'Could not authenticate with the cat service.';

  @override
  String failureServer(int statusCode) {
    return 'The cat service failed ($statusCode). Try again later.';
  }

  @override
  String get failureUnexpected =>
      'The cat service returned something unexpected.';

  @override
  String get failureNotFound => 'We could not find that cat breed.';

  @override
  String get failureUnknown => 'Something went wrong. Try again.';
}
