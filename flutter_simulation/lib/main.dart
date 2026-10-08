import 'package:flutter/material.dart';

import 'screens/ecran_demarrage.dart';
import 'theme/habibo.dart';
import 'widgets/cadre_telephone.dart';

void main() {
  runApp(const SimulationHabibo());
}

class SimulationHabibo extends StatelessWidget {
  const SimulationHabibo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habibo WMS',
      theme: themeHabibo(),
      builder: (context, child) => CadreTelephone(child: child!),
      home: const EcranDemarrage(),
    );
  }
}
