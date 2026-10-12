import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/cadre_telephone.dart';
import '../widgets/commun.dart';
import 'parcours_termine.dart';
import 'scan_sortie.dart';

/// Parcours de picking : les emplacements dans l'ordre de passage.
/// Reprend la maquette existante (chemin en haut, fiche en bas), dans le
/// bleu Habibo et avec la photo du produit.
class EcranParcours extends StatefulWidget {
  const EcranParcours({super.key, required this.journal});

  /// La sortie (bon de commande) dont on prelève les articles.
  final Journal journal;

  @override
  State<EcranParcours> createState() => _EcranParcoursState();
}

class _EcranParcoursState extends State<EcranParcours> {
  /// Les etapes du parcours, dans l'ordre de passage (triees par rack).
  late List<EtapePicking> _etapes;

  /// Index de l'etape affichee dans la fiche du bas.
  int _selection = 0;

  @override
  void initState() {
    super.initState();
    // Genere le parcours, ou renvoie celui deja cree si on reprend.
    _etapes = magasin.genererParcours(widget.journal);
    // On se place sur la premiere etape non terminee.
    final premiere = _etapes.indexWhere((etape) => !etape.terminee);
    _selection = premiere >= 0 ? premiere : 0;
  }

  /// Ouvre l'ecran de scan pour l'etape selectionnee. Au retour, passe a
  /// l'etape suivante si celle-ci est terminee et affiche un message.
  Future<void> _scanner() async {
    final etape = _etapes[_selection];
    final quantite = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => EcranScanSortie(journal: widget.journal, etape: etape),
      ),
    );
    // Ecran ferme sans scan valide : rien a mettre a jour.
    if (!mounted || quantite == null) return;

    setState(() {
      if (etape.terminee) {
        final prochaine = _etapes.indexWhere((e) => !e.terminee);
        if (prochaine >= 0) _selection = prochaine;
      }
    });

    afficherMessage(
      context,
      etape.terminee
          ? 'Prélèvement terminé à ${etape.emplacement.code}.'
          : '${etape.article.unites(etape.restant)} restant'
                '${etape.restant > 1 ? 's' : ''} à ${etape.emplacement.code}.',
      icone: etape.terminee ? LucideIcons.circleCheck : LucideIcons.info,
      decalageBas: 96,
    );

    // Toutes les etapes sont faites : on passe a l'ecran de fin.
    if (widget.journal.parcoursTermine) _terminer();
  }

  /// Remplace l'ecran par celui de fin de parcours (pas de retour possible).
  void _terminer() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EcranParcoursTermine(journal: widget.journal),
      ),
    );
  }

  /// Ouvre la feuille du bas avec la progression de chaque article commande.
  void _voirProgression() {
    retourLeger();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FeuilleProgression(journal: widget.journal),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Aucun stock disponible : message "Rien a prelever".
    if (_etapes.isEmpty) {
      return Scaffold(
        backgroundColor: Habibo.fond,
        body: SafeArea(
          child: Column(
            children: [
              EnTetePage(
                titre: 'Parcours',
                sousTitre: widget.journal.reference,
              ),
              const EtatVide(
                icone: LucideIcons.packageX,
                titre: 'Rien à prélever',
                texte:
                    'Aucun stock n’est disponible pour ce bon. Il sera signalé '
                    'à l’administrateur.',
              ),
            ],
          ),
        ),
      );
    }

    final etape = _etapes[_selection];
    final faites = _etapes.where((e) => e.terminee).length;

    // Haut de page bleu (compteur, barre, chemin) + fiche blanche en bas.
    return FondFonce(
      child: Scaffold(
        backgroundColor: Habibo.bleu,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // En-tete : titre, reference du bon, bouton "Progression".
              EnTetePage(
                titre: 'Parcours',
                sousTitre: widget.journal.reference,
                clair: true,
                action: BoutonRond(
                  icone: LucideIcons.listChecks,
                  libelle: 'Progression',
                  clair: true,
                  onTap: _voirProgression,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Habibo.marge,
                  8,
                  Habibo.marge,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compteur : "3 sur 8 emplacements".
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$faites',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 6, bottom: 3),
                          child: Text(
                            'sur ${_etapes.length} emplacements',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Barre de progression animee (etapes faites / total).
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: faites / _etapes.length),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, valeur, _) =>
                            LinearProgressIndicator(
                              value: valeur,
                              minHeight: 6,
                              color: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _chemin(),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              // Fiche detaillee de l'etape selectionnee.
              Expanded(child: _fiche(etape)),
            ],
          ),
        ),
      ),
    );
  }

  /// Le chemin : une case par emplacement, dans l'ordre de passage.
  Widget _chemin() {
    final lignes = <Widget>[];
    for (var debut = 0; debut < _etapes.length; debut += 5) {
      final fin = (debut + 5).clamp(0, _etapes.length);
      lignes.add(
        Row(
          children: [
            // Toujours cinq cases par ligne : une ligne incomplete garde le
            // meme espacement que les autres.
            for (var i = debut; i < debut + 5; i++) ...[
              if (i < fin)
                _Noeud(
                  etape: _etapes[i],
                  selectionne: i == _selection,
                  // Toucher une case affiche la fiche de cet emplacement.
                  onTap: () {
                    retourLeger();
                    setState(() => _selection = i);
                  },
                )
              else
                const SizedBox(width: 50),
              // Trait entre deux cases (invisible apres la derniere etape).
              if (i < debut + 4)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < fin - 1
                        ? Colors.white.withValues(alpha: 0.28)
                        : Colors.transparent,
                  ),
                ),
            ],
          ],
        ),
      );
      if (fin < _etapes.length) lignes.add(const SizedBox(height: 12));
    }
    return Column(children: lignes);
  }

  /// La fiche du bas : produit, emplacement, quantite, dates, et le bouton
  /// d'action ("Scanner" ou "Emplacement suivant").
  Widget _fiche(EtapePicking etape) {
    final article = etape.article;
    final emplacement = etape.emplacement;
    // DLC a 15 jours ou moins : affichee en orange pour alerter.
    final dlcProche = joursAvant(etape.lot.dlc) <= 15;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Habibo.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              // Fondu entre deux fiches quand on change d'etape (la cle
              // ValueKey fait croire a Flutter que c'est un nouveau widget).
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: ListView(
                  key: ValueKey(etape.id),
                  padding: const EdgeInsets.fromLTRB(
                    Habibo.marge,
                    22,
                    Habibo.marge,
                    12,
                  ),
                  children: [
                    // Ligne produit : photo, numero d'etape, nom, statut.
                    Row(
                      children: [
                        VignetteArticle(article: article, taille: 64),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ÉTAPE ${etape.ordre}',
                                style: const TextStyle(
                                  color: Habibo.texteDiscret,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                article.nom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Habibo.texte,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Text(
                                article.contenance,
                                style: const TextStyle(
                                  color: Habibo.texteSecondaire,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PastilleStatut(statut: etape.statut),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Deux cartes : ou aller, et combien prelever.
                    Row(
                      children: [
                        Expanded(
                          child: _Info(
                            libelle: 'Emplacement',
                            valeur: emplacement.code,
                            detail:
                                '${emplacement.nomRack} · étage ${emplacement.etage}',
                            fort: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Info(
                            libelle: 'À prélever',
                            valeur: '${etape.quantite}',
                            // Prelevement partiel : on montre ce qui est deja
                            // pris, sinon le conditionnement (unite de N).
                            detail:
                                etape.quantitePrelevee > 0 && !etape.terminee
                                ? '${etape.quantitePrelevee} déjà prélevé'
                                      '${etape.quantitePrelevee > 1 ? 's' : ''}'
                                : '${article.unite}${etape.quantite > 1 ? 's' : ''}'
                                      ' de ${article.piecesParUnite}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Dates limites du lot (DLC / DLV).
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: dlcProche
                              ? Habibo.orange
                              : Habibo.texteSecondaire,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'DLC ${formaterDate(etape.lot.dlc)} · DLV '
                            '${formaterDate(etape.lot.dlv)}',
                            style: TextStyle(
                              color: dlcProche
                                  ? Habibo.orange
                                  : Habibo.texteSecondaire,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Habibo.marge,
                4,
                Habibo.marge,
                16,
              ),
              // Etape terminee : on propose la suivante (ou la fin du
              // parcours). Sinon : on lance le scan.
              child: etape.terminee
                  ? BoutonPrincipal(
                      libelle: 'Emplacement suivant',
                      icone: LucideIcons.arrowRight,
                      onPressed: () {
                        final prochaine = _etapes.indexWhere(
                          (e) => !e.terminee,
                        );
                        if (prochaine >= 0) {
                          setState(() => _selection = prochaine);
                        } else {
                          _terminer();
                        }
                      },
                    )
                  : BoutonPrincipal(
                      libelle: 'Scanner',
                      icone: LucideIcons.scanLine,
                      onPressed: _scanner,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une case du chemin : le code de l'emplacement, ou une coche si l'etape
/// est faite. Blanche quand elle est selectionnee.
class _Noeud extends StatelessWidget {
  const _Noeud({
    required this.etape,
    required this.selectionne,
    required this.onTap,
  });

  final EtapePicking etape;
  final bool selectionne;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final faite = etape.terminee;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selectionne
              ? Colors.white
              : Colors.white.withValues(alpha: faite ? 0.1 : 0.18),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selectionne
                ? Colors.white
                : Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: faite && !selectionne
            ? Icon(
                LucideIcons.check,
                size: 18,
                color: Colors.white.withValues(alpha: 0.9),
              )
            : Text(
                etape.emplacement.code,
                style: TextStyle(
                  color: selectionne ? Habibo.bleu : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

/// Petite carte d'information : libelle, grosse valeur, detail dessous.
/// `fort` la met en bleu pour la mettre en avant (l'emplacement).
class _Info extends StatelessWidget {
  const _Info({
    required this.libelle,
    required this.valeur,
    required this.detail,
    this.fort = false,
  });

  final String libelle;
  final String valeur;
  final String detail;
  final bool fort;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fort ? Habibo.bleuDoux : Habibo.fond,
        borderRadius: BorderRadius.circular(Habibo.rayonCarte),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            libelle,
            style: const TextStyle(color: Habibo.texteSecondaire, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            valeur,
            style: TextStyle(
              color: fort ? Habibo.bleu : Habibo.texte,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Habibo.texteSecondaire, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Progression globale : une ligne par article commande.
class _FeuilleProgression extends StatelessWidget {
  const _FeuilleProgression({required this.journal});

  final Journal journal;

  @override
  Widget build(BuildContext context) {
    final etapes = journal.parcours ?? const <EtapePicking>[];

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
            const Text(
              'Progression',
              style: TextStyle(
                color: Habibo.texte,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 18),
            for (final commande in journal.commandes)
              Builder(
                builder: (context) {
                  // Etapes de cette commande, et total deja prelevé.
                  final siennes = etapes
                      .where((etape) => etape.commande.id == commande.id)
                      .toList();
                  final preleve = siennes.fold(
                    0,
                    (total, etape) => total + etape.quantitePrelevee,
                  );
                  // Quantite que le stock ne permet pas de servir.
                  final reste = magasin.resteCommande(journal, commande);
                  final progression = commande.quantiteDemandee == 0
                      ? 0.0
                      : preleve / commande.quantiteDemandee;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        VignetteArticle(article: commande.article, taille: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      commande.article.titre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Habibo.texte,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$preleve / ${commande.quantiteDemandee}',
                                    style: const TextStyle(
                                      color: Habibo.texteSecondaire,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: progression.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  color: Habibo.bleu,
                                  backgroundColor: Habibo.neutreDoux,
                                ),
                              ),
                              if (reste > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Reste à servir : '
                                  '${commande.article.unites(reste)}',
                                  style: const TextStyle(
                                    color: Habibo.orange,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
