import 'package:flutter/material.dart';
import 'package:flutter_application/theme/habibo.dart';

/// Statut d'un journal : un point coloré et son libellé.
class PastilleStatut extends StatelessWidget {
  const PastilleStatut({super.key, required this.statut});

  final String statut;

  @override
  Widget build(BuildContext context) {
    final (libelle, couleur, fond) = _apparence(statut);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            libelle,
            style: TextStyle(
              color: couleur,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static (String, Color, Color) _apparence(String statut) {
    switch (statut.trim().toUpperCase().replaceAll('_', ' ')) {
      case 'EN COURS':
        return ('En cours', Habibo.orange, Habibo.orangeDoux);
      case 'MODIFIE':
        return ('À corriger', Habibo.rouge, Habibo.rougeDoux);
      case 'EN ATTENTE':
        return ('En attente', Habibo.texteSecondaire, Habibo.neutreDoux);
      case 'VALIDE':
        return ('Validé', Habibo.vert, Habibo.vertDoux);
      case 'AFFECTEE':
        return ('Affecté', Habibo.vert, Habibo.vertDoux);
      case 'CLOTURE':
        return ('Clôturé', Habibo.vert, Habibo.vertDoux);
      default:
        return (statut, Habibo.texteSecondaire, Habibo.neutreDoux);
    }
  }
}
