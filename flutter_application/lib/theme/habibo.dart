import 'package:flutter/material.dart';

/// Couleurs et dimensions communes aux écrans Habibo.
class Habibo {
  const Habibo._();

  static const bleu = Color(0xFF064B9C);
  static const bleuDoux = Color(0xFFEAF2FA);

  static const fond = Color(0xFFF7F8FA);
  static const surface = Colors.white;
  static const bordure = Color(0xFFDFE4E8);
  static const neutreDoux = Color(0xFFEEF1F3);

  // Encre : quasi noir, pour le texte et l'élément actif (filtres).
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
