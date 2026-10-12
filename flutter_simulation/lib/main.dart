import 'package:flutter/material.dart';

import 'screens/ecran_demarrage.dart';
import 'theme/habibo.dart';
import 'widgets/cadre_telephone.dart';

/// Point d'entree : lance l'application.
void main() {
  runApp(const SimulationHabibo());
}

/// Racine de l'application : configure le theme, le cadre telephone et la
/// premiere page.
class SimulationHabibo extends StatelessWidget {
  const SimulationHabibo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habibo WMS',
      // Couleurs, polices et transitions communes (theme/habibo.dart).
      theme: themeHabibo(),
      // Entoure toutes les pages d'un cadre de telephone (simulation).
      builder: (context, child) => CadreTelephone(child: child!),
      // Premiere page : logo, puis connexion ou accueil.
      home: const EcranDemarrage(),
    );
  }
}
