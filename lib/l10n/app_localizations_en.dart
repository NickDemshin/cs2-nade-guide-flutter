// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CS Nade Guide';

  @override
  String get homeTitle => 'CS2 Grenade Guides';

  @override
  String get refresh => 'Refresh';

  @override
  String errorLoading(Object error) {
    return 'Failed to load: $error';
  }

  @override
  String get noMaps => 'No maps yet';

  @override
  String get retry => 'Retry';

  @override
  String nadesForMapTitle(Object map) {
    return 'Nades — $map';
  }

  @override
  String get showOnlyFavorites => 'Only favorites';

  @override
  String get showAll => 'Show all';

  @override
  String get showGrid => 'Show grid';

  @override
  String get hideGrid => 'Hide grid';

  @override
  String get resetZoom => 'Reset zoom';

  @override
  String get coordinatesOn => 'Coordinates: on';

  @override
  String get coordinatesOff => 'Coordinates: off';

  @override
  String copiedCoords(Object coords) {
    return 'Copied: $coords';
  }

  @override
  String get colorBlindPalette => 'Colorblind-friendly colors';

  @override
  String get filterAll => 'All';

  @override
  String get sideAll => 'Side: All';

  @override
  String get sideT => 'T';

  @override
  String get sideCT => 'CT';

  @override
  String get sideBoth => 'Both';

  @override
  String get selectHint => 'Tap a point to see where to throw';

  @override
  String get coordModeHint => 'Long-press to copy coordinates (0..1)';

  @override
  String get typeSmoke => 'Smoke';

  @override
  String get typeFlash => 'Flash';

  @override
  String get typeMolotov => 'Molotov';

  @override
  String get typeHE => 'HE';

  @override
  String sideLabel(Object side) {
    return 'Side: $side';
  }

  @override
  String techniqueLabel(Object technique) {
    return 'Technique: $technique';
  }

  @override
  String get details => 'Details';

  @override
  String get openVideo => 'Open video';

  @override
  String get openVideoFailed => 'Could not open link';

  @override
  String get openVideoError => 'Error opening link';

  @override
  String nadeCount(Object count, Object id) {
    return 'ID: $id • Nades: $count';
  }
}
