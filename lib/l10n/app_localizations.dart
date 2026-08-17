import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The application name, shown in the splash, the landing app bar and the detail app bar. A proper noun: not translated.
  ///
  /// In en, this message translates to:
  /// **'Catbreeds'**
  String get appTitle;

  /// Placeholder inside the search field on the landing screen.
  ///
  /// In en, this message translates to:
  /// **'Search by the name'**
  String get searchHint;

  /// Action on a breed card that opens the detail screen.
  ///
  /// In en, this message translates to:
  /// **'More...'**
  String get moreAction;

  /// Country of origin of a breed, on the detail screen.
  ///
  /// In en, this message translates to:
  /// **'Country: {origin}'**
  String countryLabel(String origin);

  /// Life expectancy range of a breed, on the detail screen. The value is a range as sent by the API, not a number.
  ///
  /// In en, this message translates to:
  /// **'LifeSpan: {lifeSpan} years'**
  String lifeSpanLabel(String lifeSpan);

  /// Label of the intelligence rating meter, on the detail screen.
  ///
  /// In en, this message translates to:
  /// **'Intelligence:'**
  String get intelligenceLabel;

  /// Label of the adaptability rating meter, on the detail screen.
  ///
  /// In en, this message translates to:
  /// **'Adaptability:'**
  String get adaptabilityLabel;

  /// Tooltip of the app-bar button that cycles system -> light -> dark. A tooltip rather than visible copy, so it is also what a screen reader announces for the button.
  ///
  /// In en, this message translates to:
  /// **'Change theme'**
  String get toggleTheme;

  /// Shown when the request succeeded but returned zero breeds.
  ///
  /// In en, this message translates to:
  /// **'No cat breeds to show.'**
  String get emptyBreeds;

  /// Button on the full-screen error view.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Button on the stale-data banner, next to the reason the list is old.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Banner above a list served from an expired cache. Deliberately says the list is old before saying why: what the user needs to know first is that what they are looking at is still usable.
  ///
  /// In en, this message translates to:
  /// **'Showing saved breeds. {reason}'**
  String staleBanner(String reason);

  /// The request never reached the server.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get failureNetwork;

  /// The request was sent but did not answer in time.
  ///
  /// In en, this message translates to:
  /// **'The request took too long. Try again.'**
  String get failureTimeout;

  /// The server answered 401 or 403. Split from the general server failure so an auth problem does not read as 'our servers are down'.
  ///
  /// In en, this message translates to:
  /// **'Could not authenticate with the cat service.'**
  String get failureAuth;

  /// The server answered with a status other than 200, 401 or 403.
  ///
  /// In en, this message translates to:
  /// **'The cat service failed ({statusCode}). Try again later.'**
  String failureServer(int statusCode);

  /// The server answered 200 with a body we cannot read.
  ///
  /// In en, this message translates to:
  /// **'The cat service returned something unexpected.'**
  String get failureUnexpected;

  /// The breed id does not exist. The id is deliberately absent from the copy: it is an internal key the user never typed, and retrying is pointless.
  ///
  /// In en, this message translates to:
  /// **'We could not find that cat breed.'**
  String get failureNotFound;

  /// Anything not anticipated. Its existence is what lets the repository be a total function.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get failureUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
