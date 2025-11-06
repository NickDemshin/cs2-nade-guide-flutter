import 'package:flutter/widgets.dart';

class LocaleController {
  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  static void setSystem() => locale.value = null;
  static void setRu() => locale.value = const Locale('ru');
  static void setEn() => locale.value = const Locale('en');
}

