import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';

/// Fiche produit (proposition) : photo, stock physique / reserve / disponible,
/// emplacements et mouvements sur une periode.
class FicheProduit extends StatefulWidget {
  const FicheProduit({super.key, required this.article});

  final Article article;

  @override
  State<FicheProduit> createState() => _FicheProduitState();
}

class _FicheProduitState extends State<FicheProduit> {
  static const _periodes = [(7, '7 jours'), (30, '30 jours'), (90, '3 mois')];
  int _periode = 1;

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final lots = magasin.lotsArticle(article);
    final mouvements = magasin.mouvementsArticle(
      article,
      _periodes[_periode].$1,
    );
    final entrees = mouvements.where((mouvement) => mouvement.entree).toList();
    final sorties = mouvements.where((mouvement) => !mouvement.entree).toList();
    int pieces(List<Mouvement> liste) =>
        liste.fold(0, (total, mouvement) => total + mouvement.pieces);

    return Scaffold(
      backgroundColor: Habibo.fond,
      body: SafeArea(
        child: Column(
          children: [
            const EnTetePage(titre: 'Fiche produit'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 32),
                children: [
                  Center(
                    child: VignetteArticle(
                      article: article,
                      taille: 148,
                      hero: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Habibo.marge,
                    ),
                    child: Column(
                      children: [
                        Text(
                          article.nom,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Habibo.texte,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${article.contenance} · ${article.famille}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Habibo.texteSecondaire,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Etiquette(
                              texte: article.codeBarres,
                              icone: LucideIcons.barcode,
                            ),
                            Etiquette(texte: article.typeProduit),
                            Etiquette(
                              texte:
                                  '${article.unite} de ${article.piecesParUnite}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Habibo.marge,
                    ),
                    child: _stock(article),
                  ),
                  const SizedBox(height: 28),
                  const TitreSection('Où le trouver'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Habibo.marge,
                    ),
                    child: lots.isEmpty
                        ? const Carte(
                            child: Text(
                              'Aucun stock en emplacement.',
                              style: TextStyle(
                                color: Habibo.texteSecondaire,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : _emplacements(article, lots),
                  ),
                  const SizedBox(height: 28),
                  const TitreSection('Mouvements'),
                  FiltresPastilles(
                    filtres: [
                      for (final periode in _periodes)
                        FiltrePastille(libelle: periode.$2),
                    ],
                    selection: _periode,
                    onChange: (index) => setState(() => _periode = index),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Habibo.marge,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Total(
                            icone: LucideIcons.arrowDownLeft,
                            libelle: 'Entrées',
                            pieces: pieces(entrees),
                            operations: entrees.length,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Total(
                            icone: LucideIcons.arrowUpRight,
                            libelle: 'Sorties',
                            pieces: pieces(sorties),
                            operations: sorties.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Habibo.marge,
                    ),
                    child: mouvements.isEmpty
                        ? const Text(
                            'Aucun mouvement sur cette période.',
                            style: TextStyle(
                              color: Habibo.texteSecondaire,
                              fontSize: 14,
                            ),
                          )
                        : Column(
                            children: [
                              for (final mouvement in mouvements.take(6))
                                _LigneMouvement(mouvement: mouvement),
                            ],
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

  Widget _stock(Article article) {
    final physique = magasin.stockPhysique(article);
    final reserve = magasin.stockReserve(article);
    final disponible = magasin.stockDisponible(article);

    Widget colonne(String libelle, int valeur, {bool fort = false}) {
      return Expanded(
        child: Column(
          children: [
            Text(
              '$valeur',
              style: TextStyle(
                color: fort ? Habibo.bleu : Habibo.texte,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              libelle,
              style: const TextStyle(
                color: Habibo.texteSecondaire,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    Widget trait() => Container(width: 1, height: 36, color: Habibo.bordure);

    return Carte(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              colonne('Physique', physique),
              trait(),
              colonne('Réservé', reserve),
              trait(),
              colonne('Disponible', disponible, fort: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'en ${article.unite}s · disponible = physique − réservé',
            style: const TextStyle(color: Habibo.texteDiscret, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _emplacements(Article article, List<Lot> lots) {
    return Container(
      decoration: BoxDecoration(
        color: Habibo.surface,
        borderRadius: BorderRadius.circular(Habibo.rayonCarte),
        border: Border.all(color: Habibo.bordure),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < lots.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Habibo.bordure),
            Padding(
              padding: const EdgeInsets.all(14),
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
                      lots[i].emplacement.code,
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
                          '${lots[i].emplacement.nomRack} · étage '
                          '${lots[i].emplacement.etage}',
                          style: const TextStyle(
                            color: Habibo.texte,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          joursAvant(lots[i].dlc) <= 15
                              ? 'Expire le ${formaterDate(lots[i].dlc)}'
                              : 'DLC ${formaterDate(lots[i].dlc)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: joursAvant(lots[i].dlc) <= 15
                                ? Habibo.orange
                                : Habibo.texteSecondaire,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    article.unites(lots[i].unites),
                    style: const TextStyle(
                      color: Habibo.texte,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.icone,
    required this.libelle,
    required this.pieces,
    required this.operations,
  });

  final IconData icone;
  final String libelle;
  final int pieces;
  final int operations;

  @override
  Widget build(BuildContext context) {
    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 17, color: Habibo.texteSecondaire),
              const SizedBox(width: 6),
              Text(
                libelle,
                style: const TextStyle(
                  color: Habibo.texteSecondaire,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '$pieces',
              key: ValueKey(pieces),
              style: const TextStyle(
                color: Habibo.texte,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'pièces · $operations opération${operations > 1 ? 's' : ''}',
            style: const TextStyle(color: Habibo.texteDiscret, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _LigneMouvement extends StatelessWidget {
  const _LigneMouvement({required this.mouvement});

  final Mouvement mouvement;

  @override
  Widget build(BuildContext context) {
    final entree = mouvement.entree;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: entree ? Habibo.bleuDoux : Habibo.neutreDoux,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              entree ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
              size: 17,
              color: entree ? Habibo.bleu : Habibo.texteSecondaire,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mouvement.reference,
                  style: const TextStyle(
                    color: Habibo.texte,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formaterDate(mouvement.date),
                  style: const TextStyle(
                    color: Habibo.texteSecondaire,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entree ? '+' : '−'}${mouvement.pieces}',
            style: TextStyle(
              color: entree ? Habibo.vert : Habibo.texte,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
