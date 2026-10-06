import 'package:flutter/material.dart';
import 'package:flutter_application/models/journal_mouvement.dart';
import 'package:flutter_application/theme/habibo.dart';
import 'package:flutter_application/widgets/pastille_statut.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Les journaux regroupés dans une seule carte arrondie, séparés par un trait
/// fin. [onOuvrir] reçoit le journal touché ; il n'est appelé que pour un
/// journal ouvrable, les autres sont atténués.
class GroupeJournaux extends StatelessWidget {
  const GroupeJournaux({
    super.key,
    required this.journaux,
    required this.onOuvrir,
  });

  final List<JournalMouvement> journaux;
  final ValueChanged<JournalMouvement> onOuvrir;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Habibo.surface,
        borderRadius: BorderRadius.circular(Habibo.rayonCarte),
        border: Border.all(color: Habibo.bordure),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < journaux.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Habibo.bordure),
            LigneJournal(
              journal: journaux[i],
              onOuvrir: journaux[i].estOuvrable
                  ? () => onOuvrir(journaux[i])
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

/// Une ligne de journal : icône du type, référence, résumé et statut.
class LigneJournal extends StatelessWidget {
  const LigneJournal({super.key, required this.journal, this.onOuvrir});

  final JournalMouvement journal;
  final VoidCallback? onOuvrir;

  @override
  Widget build(BuildContext context) {
    final (libelleType, icone, entree) = _type(journal.type);
    final produits = journal.nombreProduits;
    final resume = produits == 0
        ? libelleType
        : '$libelleType · $produits produit${produits > 1 ? 's' : ''}';

    // Un journal non ouvrable reste lisible : il ne réagit simplement pas au toucher.
    return InkWell(
      onTap: onOuvrir,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: entree ? Habibo.bleuDoux : Habibo.neutreDoux,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icone,
                size: 22,
                color: entree ? Habibo.bleu : Habibo.texteSecondaire,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          journal.reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Habibo.texte,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PastilleStatut(statut: journal.statut),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resume,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Habibo.texteSecondaire,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (String, IconData, bool) _type(String type) {
    switch (type) {
      case 'ENTREE':
        return ('Entrée', LucideIcons.arrowDownLeft, true);
      case 'SORTIE':
        return ('Sortie', LucideIcons.arrowUpRight, false);
      case 'INVENTAIRE':
        return ('Inventaire', LucideIcons.clipboardList, false);
      default:
        return (type, LucideIcons.fileText, false);
    }
  }
}
