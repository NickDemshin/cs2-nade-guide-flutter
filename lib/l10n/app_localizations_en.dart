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

  @override
  String get searchMapsHint => 'Search maps...';

  @override
  String get toggleGrid => 'Grid view';

  @override
  String get toggleList => 'List view';

  @override
  String get noResults => 'Nothing found';

  @override
  String get mapsTitle => 'Maps';

  @override
  String get langRussian => 'Russian';

  @override
  String get langEnglish => 'English';

  @override
  String get tabsTournament => 'Tournament';

  @override
  String get tabsOthers => 'Others';

  @override
  String get tabsFavorites => 'Favorites';

  @override
  String get languageTooltip => 'Language';

  @override
  String get addNade => 'Add grenade';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get newNadeTitle => 'New grenade';

  @override
  String get editNadeTitle => 'Edit grenade';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldType => 'Type';

  @override
  String get fieldSide => 'Side';

  @override
  String get fieldFrom => 'Throw from (text)';

  @override
  String get fieldTo => 'Lands at (text)';

  @override
  String get fieldToCoords => 'Landing coords';

  @override
  String get fieldFromCoords => 'Throw coords';

  @override
  String get pickOnMap => 'Pick on map';

  @override
  String get fieldTechnique => 'Technique (stand/run/jumpthrow...)';

  @override
  String get fieldVideoUrl => 'Video URL (optional)';

  @override
  String get fieldDescription => 'Description (optional)';

  @override
  String get save => 'Save';

  @override
  String infoFrom(Object from) {
    return 'Throw from: $from';
  }

  @override
  String infoTo(Object to) {
    return 'Lands at: $to';
  }

  @override
  String fromTo(Object from, Object to) {
    return 'From: $from → To: $to';
  }

  @override
  String get matchesTitle => 'Matches';

  @override
  String get importAction => 'Import';

  @override
  String invalidShareCode(Object error) {
    return 'Invalid share code: $error';
  }

  @override
  String get deleteMatchQuestion => 'Delete match?';

  @override
  String get irreversible => 'This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get matchAnalysisTitle => 'Match Analysis';

  @override
  String get shareCode => 'Share code';

  @override
  String get status => 'Status';

  @override
  String get matchDeleted => 'Match deleted';

  @override
  String nadeDeleted(Object title) {
    return 'Deleted: $title';
  }

  @override
  String deleteError(Object error) {
    return 'Delete error: $error';
  }

  @override
  String get analysisInsights => 'Insights';

  @override
  String get analysisSummary => 'Summary';

  @override
  String get analysisThrows => 'Throws';

  @override
  String get analysisUtility => 'Utility';

  @override
  String get analysisRounds => 'Rounds';

  @override
  String get filterType => 'Type';

  @override
  String get filterRound => 'Round';

  @override
  String get filterOnlyIneffective => 'Only ineffective';

  @override
  String get chartsTable => 'Table';

  @override
  String get chartsGraphs => 'Charts';

  @override
  String get chartDamageByRound => 'Damage by round';

  @override
  String get chartBlindByRound => 'Blind (ms) by round';

  @override
  String get chartImpactByRound => 'Impact by round';

  @override
  String get chartThrowsByType => 'Throws by type';

  @override
  String get chartHeatmap => 'Heatmap';

  @override
  String get heatmapNoPoints => 'No coordinates for heatmap';

  @override
  String get heatmapNoMap => 'Map is not specified';

  @override
  String get heatmapNoImage => 'No background image for the map';

  @override
  String kpiTeamFlashRatio(Object percent) {
    return 'Team flash ratio: $percent%';
  }

  @override
  String kpiSmokeLOS(Object seconds) {
    return 'Smoke LoS: ${seconds}s';
  }

  @override
  String kpiHeDmg(Object damage) {
    return 'HE dmg: $damage';
  }

  @override
  String badgeIneffective(Object percent) {
    return 'Ineffective: $percent%';
  }

  @override
  String insightsHighTeamFlashError(Object percent) {
    return 'Too many team flashes (≥$percent%)';
  }

  @override
  String insightsHighTeamFlashWarn(Object percent) {
    return 'Elevated team flashes (≥$percent%)';
  }

  @override
  String insightsSmokesLowLOSWarn(Object seconds) {
    return 'Low smoke effectiveness (LOS < ${seconds}s)';
  }

  @override
  String insightsSmokesShortLOSInfo(Object seconds) {
    return 'Short smoke line-of-sight block (LOS < ${seconds}s)';
  }

  @override
  String get insightsMolotovLowImpactWarn => 'Molotovs with almost no impact';

  @override
  String insightsHeLowAvgInfo(Object damage) {
    return 'Low average HE damage (<$damage)';
  }

  @override
  String insightsIneffectiveTypeWarn(Object percent, Object type) {
    return 'Many ineffective $type (≥$percent%)';
  }

  @override
  String insightsCriticalRoundsWarn(Object rounds) {
    return 'Critical rounds (team-flash): $rounds';
  }
}
