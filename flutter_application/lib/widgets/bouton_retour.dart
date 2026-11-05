import 'package:flutter/material.dart';
import 'package:flutter_application/theme/habibo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Rond blanc avec une flèche, pour revenir à l'écran précédent.
class BoutonRetour extends StatelessWidget {
  const BoutonRetour({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Habibo.surface,
      shape: const CircleBorder(side: BorderSide(color: Habibo.bordure)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            LucideIcons.arrowLeft,
            size: 20,
            color: Habibo.texte,
            semanticLabel: 'Retour',
          ),
        ),
      ),
    );
  }
}
