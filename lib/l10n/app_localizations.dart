import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CS Nade Guide'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'CS2 Grenade Guides'**
  String get homeTitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String errorLoading(Object error);

  /// No description provided for @noMaps.
  ///
  /// In en, this message translates to:
  /// **'No maps yet'**
  String get noMaps;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @nadesForMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Nades — {map}'**
  String nadesForMapTitle(Object map);

  /// No description provided for @showOnlyFavorites.
  ///
  /// In en, this message translates to:
  /// **'Only favorites'**
  String get showOnlyFavorites;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @showGrid.
  ///
  /// In en, this message translates to:
  /// **'Show grid'**
  String get showGrid;

  /// No description provided for @hideGrid.
  ///
  /// In en, this message translates to:
  /// **'Hide grid'**
  String get hideGrid;

  /// No description provided for @resetZoom.
  ///
  /// In en, this message translates to:
  /// **'Reset zoom'**
  String get resetZoom;

  /// No description provided for @coordinatesOn.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: on'**
  String get coordinatesOn;

  /// No description provided for @coordinatesOff.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: off'**
  String get coordinatesOff;

  /// No description provided for @copiedCoords.
  ///
  /// In en, this message translates to:
  /// **'Copied: {coords}'**
  String copiedCoords(Object coords);

  /// No description provided for @colorBlindPalette.
  ///
  /// In en, this message translates to:
  /// **'Colorblind-friendly colors'**
  String get colorBlindPalette;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @sideAll.
  ///
  /// In en, this message translates to:
  /// **'Side: All'**
  String get sideAll;

  /// No description provided for @sideT.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get sideT;

  /// No description provided for @sideCT.
  ///
  /// In en, this message translates to:
  /// **'CT'**
  String get sideCT;

  /// No description provided for @sideBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get sideBoth;

  /// No description provided for @selectHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a point to see where to throw'**
  String get selectHint;

  /// No description provided for @coordModeHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press to copy coordinates (0..1)'**
  String get coordModeHint;

  /// No description provided for @typeSmoke.
  ///
  /// In en, this message translates to:
  /// **'Smoke'**
  String get typeSmoke;

  /// No description provided for @typeFlash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get typeFlash;

  /// No description provided for @typeMolotov.
  ///
  /// In en, this message translates to:
  /// **'Molotov'**
  String get typeMolotov;

  /// No description provided for @typeHE.
  ///
  /// In en, this message translates to:
  /// **'HE'**
  String get typeHE;

  /// No description provided for @sideLabel.
  ///
  /// In en, this message translates to:
  /// **'Side: {side}'**
  String sideLabel(Object side);

  /// No description provided for @techniqueLabel.
  ///
  /// In en, this message translates to:
  /// **'Technique: {technique}'**
  String techniqueLabel(Object technique);

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @openVideo.
  ///
  /// In en, this message translates to:
  /// **'Open video'**
  String get openVideo;

  /// No description provided for @openVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get openVideoFailed;

  /// No description provided for @openVideoError.
  ///
  /// In en, this message translates to:
  /// **'Error opening link'**
  String get openVideoError;

  /// No description provided for @nadeCount.
  ///
  /// In en, this message translates to:
  /// **'ID: {id} • Nades: {count}'**
  String nadeCount(Object count, Object id);

  /// No description provided for @searchMapsHint.
  ///
  /// In en, this message translates to:
  /// **'Search maps...'**
  String get searchMapsHint;

  /// No description provided for @toggleGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get toggleGrid;

  /// No description provided for @toggleList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get toggleList;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get noResults;

  /// No description provided for @mapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get mapsTitle;

  /// No description provided for @langRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get langRussian;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @addNade.
  ///
  /// In en, this message translates to:
  /// **'Add grenade'**
  String get addNade;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @newNadeTitle.
  ///
  /// In en, this message translates to:
  /// **'New grenade'**
  String get newNadeTitle;

  /// No description provided for @editNadeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit grenade'**
  String get editNadeTitle;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @fieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldType;

  /// No description provided for @fieldSide.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get fieldSide;

  /// No description provided for @fieldFrom.
  ///
  /// In en, this message translates to:
  /// **'Throw from (text)'**
  String get fieldFrom;

  /// No description provided for @fieldTo.
  ///
  /// In en, this message translates to:
  /// **'Lands at (text)'**
  String get fieldTo;

  /// No description provided for @fieldToCoords.
  ///
  /// In en, this message translates to:
  /// **'Landing coords'**
  String get fieldToCoords;

  /// No description provided for @fieldFromCoords.
  ///
  /// In en, this message translates to:
  /// **'Throw coords'**
  String get fieldFromCoords;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get pickOnMap;

  /// No description provided for @fieldTechnique.
  ///
  /// In en, this message translates to:
  /// **'Technique (stand/run/jumpthrow...)'**
  String get fieldTechnique;

  /// No description provided for @fieldVideoUrl.
  ///
  /// In en, this message translates to:
  /// **'Video URL (optional)'**
  String get fieldVideoUrl;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get fieldDescription;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
