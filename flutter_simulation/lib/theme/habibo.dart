import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Couleurs et dimensions communes aux ecrans Habibo.
/// Memes valeurs que l'application reelle (lib/theme/habibo.dart).
class Habibo {
  const Habibo._();

  static const bleu = Color(0xFF064B9C);
  static const bleuDoux = Color(0xFFEAF2FA);
  static const bleuNuit = Color(0xFF05366F);

  static const fond = Color(0xFFF7F8FA);
  static const surface = Colors.white;
  static const bordure = Color(0xFFDFE4E8);
  static const neutreDoux = Color(0xFFEEF1F3);

  static const texte = Color(0xFF18212A);
  static const encre = Color(0xFF18212A);
  static const texteSecondaire = Color(0xFF667482);
  static const texteDiscret = Color(0xFF98A2AB);

  static const rouge = Color(0xFFD64545);
  static const rougeDoux = Color(0xFFFBECEC);
  static const vert = Color(0xFF1F9D62);
  static const vertDoux = Color(0xFFE8F7EF);
  static const orange = Color(0xFFB8770F);
  static const orangeDoux = Color(0xFFFFF5DF);

  static const rayon = 12.0;
  static const rayonCarte = 16.0;
  static const marge = 24.0;
}

ThemeData themeHabibo() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Habibo.bleu),
    scaffoldBackgroundColor: Habibo.fond,
    fontFamily: 'Inter',
    useMaterial3: true,
    // Pas d'ondulation Material au toucher : un simple voile gris.
    splashFactory: NoSplash.splashFactory,
    highlightColor: const Color(0x0F18212A),
    // Glissement lateral sur toutes les plateformes : sensation d'application mobile.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Habibo.encre,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Inter',
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Habibo.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Habibo.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
