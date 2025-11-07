// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'CS Nade Guide';

  @override
  String get homeTitle => 'Гайды по гранатам — CS2';

  @override
  String get refresh => 'Обновить';

  @override
  String errorLoading(Object error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get noMaps => 'Пока нет карт';

  @override
  String get retry => 'Повторить';

  @override
  String nadesForMapTitle(Object map) {
    return 'Гранаты — $map';
  }

  @override
  String get showOnlyFavorites => 'Только избранные';

  @override
  String get showAll => 'Показать все';

  @override
  String get showGrid => 'Показать сетку';

  @override
  String get hideGrid => 'Скрыть сетку';

  @override
  String get resetZoom => 'Сбросить зум';

  @override
  String get coordinatesOn => 'Координаты: вкл';

  @override
  String get coordinatesOff => 'Координаты: выкл';

  @override
  String copiedCoords(Object coords) {
    return 'Координаты скопированы: $coords';
  }

  @override
  String get colorBlindPalette => 'Цвета для дальтоников';

  @override
  String get filterAll => 'Все';

  @override
  String get sideAll => 'Сторона: Все';

  @override
  String get sideT => 'T';

  @override
  String get sideCT => 'CT';

  @override
  String get sideBoth => 'Both';

  @override
  String get selectHint =>
      'Нажмите на точку на карте, чтобы посмотреть откуда бросать';

  @override
  String get coordModeHint =>
      'Долгий тап по карте — скопировать координаты (0..1)';

  @override
  String get typeSmoke => 'Дым';

  @override
  String get typeFlash => 'Флеш';

  @override
  String get typeMolotov => 'Молотов';

  @override
  String get typeHE => 'Осколочная';

  @override
  String sideLabel(Object side) {
    return 'Сторона: $side';
  }

  @override
  String techniqueLabel(Object technique) {
    return 'Техника: $technique';
  }

  @override
  String get details => 'Подробнее';

  @override
  String get openVideo => 'Открыть видео';

  @override
  String get openVideoFailed => 'Не удалось открыть ссылку';

  @override
  String get openVideoError => 'Ошибка при открытии ссылки';

  @override
  String nadeCount(Object count, Object id) {
    return 'ID: $id • Гранат: $count';
  }

  @override
  String get searchMapsHint => 'Поиск карт...';

  @override
  String get toggleGrid => 'Сетка';

  @override
  String get toggleList => 'Список';

  @override
  String get noResults => 'Ничего не найдено';

  @override
  String get mapsTitle => 'Карты';

  @override
  String get langRussian => 'Русский';

  @override
  String get langEnglish => 'Английский';

  @override
  String get tabsTournament => 'Турнирные';

  @override
  String get tabsOthers => 'Остальные';

  @override
  String get tabsFavorites => 'Избранные';

  @override
  String get languageTooltip => 'Язык';

  @override
  String get addNade => 'Добавить гранату';

  @override
  String get edit => 'Редактировать';

  @override
  String get delete => 'Удалить';

  @override
  String get newNadeTitle => 'Новая граната';

  @override
  String get editNadeTitle => 'Редактировать гранату';

  @override
  String get fieldTitle => 'Название';

  @override
  String get fieldType => 'Тип';

  @override
  String get fieldSide => 'Сторона';

  @override
  String get fieldFrom => 'Откуда бросать (текст)';

  @override
  String get fieldTo => 'Куда прилетает (текст)';

  @override
  String get fieldToCoords => 'Коорд. приземления';

  @override
  String get fieldFromCoords => 'Коорд. броска';

  @override
  String get pickOnMap => 'Выбрать на карте';

  @override
  String get fieldTechnique => 'Техника (stand/run/jumpthrow...)';

  @override
  String get fieldVideoUrl => 'Видео URL (необязательно)';

  @override
  String get fieldDescription => 'Описание (необязательно)';

  @override
  String get save => 'Сохранить';

  @override
  String infoFrom(Object from) {
    return 'Откуда бросать: $from';
  }

  @override
  String infoTo(Object to) {
    return 'Куда прилетает: $to';
  }

  @override
  String fromTo(Object from, Object to) {
    return 'От: $from → К: $to';
  }
}
