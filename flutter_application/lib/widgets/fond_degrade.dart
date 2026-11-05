import 'package:flutter/material.dart';
import 'package:flutter_application/theme/habibo.dart';

/// Fond des écrans : un léger dégradé bleu pâle en haut, qui se fond dans le
/// gris clair de l'application.
class FondDegrade extends StatelessWidget {
  const FondDegrade({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Habibo.bleuDoux, Habibo.fond],
          stops: [0, 0.5],
        ),
      ),
      child: child,
    );
  }
}
