import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';
import 'parcours.dart';
import 'parcours_termine.dart';

/// Commandes d'un bon de sortie. Reprend « Liste des commandes » de
/// l'application reelle : consulter les emplacements, generer le parcours.
/// Ajout propose : le reste a servir quand le stock ne suffit pas.
jwss EcranCommandes extends StatefulWidget {
  const EcranCommandes({super.key, required this.journal});

  /// Le bon de sortie dont on affiche les commandes.
  final Journal journal;

  @override
  State<EcranCommandes> createState() => _EcranCommandesState();
}

class _EcranCommandesState extends State<EcranCommandes> {
  /// Vrai pendant le "calcul" du parcours : affiche le voile de chargement.
  bool _generation = false;

  /// Bouton du bas : genere le parcours s'il n'existe pas encore, puis ouvre
  /// l'ecran du parcours (ou l'ecran de fin s'il est deja termine).
  Future<void> _ouvrirParcours() async {
    final journal = widget.journal;

    // Premiere fois : on genere le parcours avec un petit temps d'attente.
    if (journal.parcours == null) {
      setState(() => _generation = true);
      // Simule le calcul du serveur.
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      magasin.genererParcours(journal);
      retourSucces();
      setState(() => _generation = false);
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => journal.parcoursTermine
            ? EcranParcoursTermine(journal: journal)
            : EcranParcours(journal: journal),
      ),
    );
    // Au retour, on rafraichit (progression, libelle du bouton).
    if (mounted) setState(() {});
  }

  /// Ouvre la feuille du bas : emplacements proposes pour une commande.
  void _voirEmplacements(Commande commande) {
    retourLeger();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _FeuilleEmplacements(journal: widget.journal, commande: commande),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journal = widget.journal;
    // Nombre d'articles que le stock ne permet pas de servir en entier.
    final nombreRestes = journal.commandes
        .where((commande) => magasin.resteCommande(journal, commande) > 0)
        .length;

    // Le texte du bouton suit l'etat : generer, reprendre ou voir le resultat.
    final libelleBouton = journal.parcours == null
        ? 'Générer le meilleur parcours'
        : journal.parcoursTermine
        ? 'Voir le résultat'
        : 'Reprendre le parcours';

    return Scaffold(
      backgroundColor: Habibo.fond,
      body: SafeArea(
        // Stack : le voile de chargement se superpose a toute la page.
        child: Stack(
          children: [
            Column(
              children: [
                EnTetePage(titre: 'Commandes', sousTitre: journal.reference),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Habibo.marge,
                      12,
                      Habibo.marge,
                      24,
                    ),
                    children: [
                      // Client et nombre d'articles commandes.
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Habibo.neutreDoux,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.store,
                              size: 20,
                              color: Habibo.texteSecondaire,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  journal.tiers ?? 'Client',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Habibo.texte,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${journal.commandes.length} articles commandés',
                                  style: const TextStyle(
                                    color: Habibo.texteSecondaire,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Bandeau d'alerte, seulement si le stock est insuffisant.
                      if (nombreRestes > 0) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Habibo.orangeDoux,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                LucideIcons.triangleAlert,
                                size: 18,
                                color: Habibo.orange,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Stock insuffisant pour $nombreRestes article'
                                  '${nombreRestes > 1 ? 's' : ''}. On prélève ce '
                                  'qui existe ; le reste sera signalé à '
                                  'l’administrateur.',
                                  style: const TextStyle(
                                    color: Habibo.orange,
                                    fontSize: 13.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      // Une carte par article commande ; un appui montre
                      // ses emplacements.
                      for (final commande in journal.commandes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CarteCommande(
                            journal: journal,
                            commande: commande,
                            onTap: () => _voirEmplacements(commande),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Habibo.marge,
                    8,
                    Habibo.marge,
                    16,
                  ),
                  // Bouton fixe en bas : generer / reprendre le parcours.
                  child: BoutonPrincipal(
                    libelle: libelleBouton,
                    icone: LucideIcons.route,
                    onPressed: _ouvrirParcours,
                  ),
                ),
              ],
            ),
            if (_generation) const _VoileGeneration(),
          ],
        ),
      ),
    );
  }
}

/// Carte d'un article commande : photo, nom, quantite demandee, et a droite
/// l'etat (Prelevé, Reste N, ou simple fleche).
class _CarteCommande extends StatelessWidget {
  const _CarteCommande({
    required this.journal,
    required this.commande,
    required this.onTap,
  });

  final Journal journal;
  final Commande commande;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final article = commande.article;
    // Quantite non servable faute de stock.
    final reste = magasin.resteCommande(journal, commande);
    // Etapes du parcours qui concernent cette commande.
    final etapes = (journal.parcours ?? const <EtapePicking>[]).where(
      (etape) => etape.commande.id == commande.id,
    );
    // Prelevee = au moins une etape et toutes terminees.
    final terminee = etapes.isNotEmpty && etapes.every((e) => e.terminee);

    return Carte(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          VignetteArticle(article: article, taille: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Habibo.texte,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${article.unites(commande.quantiteDemandee)} demandés',
                  style: const TextStyle(
                    color: Habibo.texteSecondaire,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (terminee)
            const Etiquette(
              texte: 'Prélevé',
              couleur: Habibo.vert,
              fond: Habibo.vertDoux,
              icone: LucideIcons.check,
            )
          else if (reste > 0)
            Etiquette(
              texte: 'Reste $reste',
              couleur: Habibo.orange,
              fond: Habibo.orangeDoux,
            )
          else
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: Habibo.texteDiscret,
            ),
        ],
      ),
    );
  }
}

/// Emplacements proposes pour une commande : premier perime, premier sorti.
class _FeuilleEmplacements extends StatelessWidget {
  const _FeuilleEmplacements({required this.journal, required this.commande});

  final Journal journal;
  final Commande commande;

  @override
  Widget build(BuildContext context) {
    final article = commande.article;
    final etapes = (journal.parcours ?? const <EtapePicking>[])
        .where((etape) => etape.commande.id == commande.id)
        .toList();
    // Parcours genere : on montre ses etapes reelles. Sinon, on affiche
    // les emplacements que le magasin proposerait (FIFO par DLC).
    final lignes = etapes.isNotEmpty
        ? [
            for (final e in etapes)
              Proposition(lot: e.lot, quantite: e.quantite),
          ]
        : magasin.proposerEmplacements(commande);
    final reste = magasin.resteCommande(journal, commande);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Habibo.marge, 12, Habibo.marge, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Habibo.bordure,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                VignetteArticle(article: article, taille: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.titre,
                        style: const TextStyle(
                          color: Habibo.texte,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${article.unites(commande.quantiteDemandee)} à prélever',
                        style: const TextStyle(
                          color: Habibo.texteSecondaire,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Meilleurs emplacements',
              style: TextStyle(
                color: Habibo.texte,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Premier périmé, premier sorti.',
              style: TextStyle(color: Habibo.texteSecondaire, fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (lignes.isEmpty)
              const Text(
                'Aucun stock disponible pour cet article.',
                style: TextStyle(color: Habibo.texteSecondaire, fontSize: 14),
              ),
            // Une ligne par emplacement : code, rack/etage, DLC, quantite.
            for (final ligne in lignes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Habibo.bleuDoux,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ligne.lot.emplacement.code,
                        style: const TextStyle(
                          color: Habibo.bleu,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ligne.lot.emplacement.nomRack} · étage '
                            '${ligne.lot.emplacement.etage}',
                            style: const TextStyle(
                              color: Habibo.texte,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'DLC ${formaterDate(ligne.lot.dlc)}',
                            style: TextStyle(
                              color: joursAvant(ligne.lot.dlc) <= 15
                                  ? Habibo.orange
                                  : Habibo.texteSecondaire,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      article.unites(ligne.quantite),
                      style: const TextStyle(
                        color: Habibo.texte,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            // Quantite que le stock ne couvre pas.
            if (reste > 0) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Habibo.orangeDoux,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Reste à servir : ${article.unites(reste)}',
                  style: const TextStyle(
                    color: Habibo.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ecran de chargement plein page affiche pendant la generation du parcours.
class _VoileGeneration extends StatelessWidget {
  const _VoileGeneration();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: const ColoredBox(
        color: Habibo.fond,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Habibo.bleu,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Calcul du meilleur parcours…',
                style: TextStyle(
                  color: Habibo.texte,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tri des emplacements par rack',
                style: TextStyle(color: Habibo.texteSecondaire, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
