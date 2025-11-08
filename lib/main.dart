import 'package:flutter/material.dart';
import 'widgets/cs2_background.dart';
import 'theme/glass_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'pages/home_page.dart';
import 'locale_controller.dart';
import 'utils/color_compat.dart'; // ignore: unused_import

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
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E5A8),
      brightness: Brightness.dark,
    );

    final theme = ThemeData(
      colorScheme: darkScheme,
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkScheme.primary.withValues(alpha: 0.18),
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkScheme.primary.withValues(alpha: 0.24),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        labelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: const [
        Glass(
          radius: 16,
          blurSigma: 14,
          background: Color(0x0FFFFFFF), // white with ~6% alpha
          border: Color(0x1FFFFFFF),     // white with ~12% alpha
        ),
      ],
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
          builder: (context, child) => Cs2Background(child: child ?? const SizedBox.shrink()),
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
