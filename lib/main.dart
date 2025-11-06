import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'pages/home_page.dart';
import 'locale_controller.dart';

void main() {
  runApp(const NadeGuideApp());
}

class NadeGuideApp extends StatefulWidget {
  const NadeGuideApp({super.key});

  static void setLocale(BuildContext context, Locale? locale) {
    LocaleController.locale.value = locale;
  }

  @override
  State<NadeGuideApp> createState() => _NadeGuideAppState();
}

class _NadeGuideAppState extends State<NadeGuideApp> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );

    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'CS Nade Guide',
          theme: theme,
          home: const HomePage(),
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ru'),
          ],
        );
      },
    );
  }
}
