import 'package:flutter/material.dart';
import 'package:flutter_application/models/journal_mouvement.dart';
import 'package:flutter_application/theme/habibo.dart';
import 'package:flutter_application/widgets/pastille_statut.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Les journaux, une carte par journal avec un petit espace entre elles.
/// [onOuvrir] reçoit le journal touché ; il n'est appelé que pour un journal
/// ouvrable, les autres sont légèrement atténués.
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
    return Column(
      children: [
        for (var i = 0; i < journaux.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          LigneJournal(
            journal: journaux[i],
            onOuvrir: journaux[i].estOuvrable
                ? () => onOuvrir(journaux[i])
                : null,
          ),
        ],
      ],
    );
  }
}

/// Une carte de journal : icône du type, référence, résumé, tiers et statut.
class LigneJournal extends StatelessWidget {
  const LigneJournal({super.key, required this.journal, this.onOuvrir});

  final JournalMouvement journal;
  final VoidCallback? onOuvrir;

  @override
  Widget build(BuildContext context) {
    final (libelleType, icone) = _type(journal.type);
    final produits = journal.nombreProduits;
    final resume = produits == 0
        ? libelleType
        : '$libelleType · $produits produit${produits > 1 ? 's' : ''}';

    // Le client (sortie) ou le fournisseur (entrée), quand il est connu.
    final tiers = _tiers();

    // Un journal non ouvrable reste lisible : il ne réagit simplement pas au toucher.
    return Opacity(
      opacity: onOuvrir == null ? 0.85 : 1,
      child: Container(
        decoration: Habibo.carte(rayon: 22),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOuvrir,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Habibo.bleuDoux,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icone, size: 23, color: Habibo.bleu),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                        const SizedBox(height: 4),
                        Text(
                          resume,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Habibo.texteSecondaire,
                            fontSize: 14,
                          ),
                        ),
                        if (tiers != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            tiers,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Habibo.texteDiscret,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PastilleStatut(statut: journal.statut),
                      if (onOuvrir != null) ...[
                        const SizedBox(height: 10),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 20,
                          color: Habibo.texteDiscret,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _tiers() {
    final client = journal.nomClient?.trim();
    if (client != null && client.isNotEmpty) return client;
    final fournisseur = journal.fournisseur?.trim();
    if (fournisseur != null && fournisseur.isNotEmpty) return fournisseur;
    return null;
  }

  static (String, IconData) _type(String type) {
    switch (type) {
      case 'ENTREE':
        return ('Entrée', LucideIcons.arrowDownLeft);
      case 'SORTIE':
        return ('Sortie', LucideIcons.arrowUpRight);
      case 'INVENTAIRE':
        return ('Inventaire', LucideIcons.clipboardList);
      default:
        return (type, LucideIcons.fileText);
    }
  }
}
