import 'package:flutter/material.dart';
import 'package:flutter_application/theme/habibo.dart';

class FiltrePastille {
  const FiltrePastille({required this.libelle, required this.compteur});

  final String libelle;
  final int compteur;
}

/// Rangée de filtres défilante : une pastille par filtre, avec son compteur.
class FiltresPastilles extends StatelessWidget {
  const FiltresPastilles({
    super.key,
    required this.filtres,
    required this.selection,
    required this.onChange,
    this.marge = Habibo.marge,
  });

  final List<FiltrePastille> filtres;
  final int selection;
  final ValueChanged<int> onChange;
  final double marge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: marge),
        itemCount: filtres.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtre = filtres[index];
          final actif = index == selection;

          return Material(
            color: actif ? Habibo.encre : Habibo.surface,
            shape: StadiumBorder(
              side: BorderSide(color: actif ? Habibo.encre : Habibo.bordure),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onChange(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filtre.libelle,
                      style: TextStyle(
                        color: actif ? Colors.white : Habibo.texte,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${filtre.compteur}',
                      style: TextStyle(
                        color: actif
                            ? Colors.white.withValues(alpha: 0.75)
                            : Habibo.texteDiscret,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
