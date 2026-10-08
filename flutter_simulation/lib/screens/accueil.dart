import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';
import 'fiche_produit.dart';
import 'navigation.dart';

/// Accueil : ce que l'operateur doit faire aujourd'hui, et un bouton pour
/// reprendre l'operation en cours.
class Accueil extends StatefulWidget {
  const Accueil({super.key, required this.onVoirOperations});

  final VoidCallback onVoirOperations;

  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    await magasin.rafraichir();
    if (mounted) setState(() => _chargement = false);
  }

  // L'accueil se redessine a chaque changement de la simulation.
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: magasin,
    builder: (context, _) => _construire(context),
  );

  Widget _construire(BuildContext context) {
    final utilisateur = magasin.utilisateur;
    if (utilisateur == null) return const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: Habibo.bleu,
        onRefresh: magasin.rafraichir,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          children: [
            _entete(utilisateur),
            const SizedBox(height: 24),
            if (_chargement) ..._squelettes() else ..._contenu(utilisateur),
          ],
        ),
      ),
    );
  }

  Widget _entete(Utilisateur utilisateur) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Habibo.marge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateDuJour(),
                  style: const TextStyle(
                    color: Habibo.texteSecondaire,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bonjour, ${utilisateur.prenom}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Habibo.texte,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Habibo.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Habibo.bordure),
            ),
            child: Text(
              utilisateur.initiales,
              style: const TextStyle(
                color: Habibo.texte,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _squelettes() {
    return const [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: Habibo.marge),
        child: Column(
          children: [
            Squelette(hauteur: 168, rayon: 20),
            SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: Squelette(hauteur: 92, rayon: 16)),
                SizedBox(width: 12),
                Expanded(child: Squelette(hauteur: 92, rayon: 16)),
              ],
            ),
            SizedBox(height: 28),
            Squelette(hauteur: 64, rayon: 16),
            SizedBox(height: 10),
            Squelette(hauteur: 64, rayon: 16),
          ],
        ),
      ),
    ];
  }

  List<Widget> _contenu(Utilisateur utilisateur) {
    final operation = magasin.operationEnCours;
    final inventoriste = utilisateur.role == Role.inventoriste;

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Habibo.marge),
        child: operation == null
            ? const Carte(
                child: EtatVide(
                  icone: LucideIcons.circleCheck,
                  titre: 'Rien en cours',
                  texte: 'Aucune opération ne vous attend pour le moment.',
                ),
              )
            : _CarteReprendre(journal: operation),
      ),
      const SizedBox(height: 28),
      TitreSection(
        'Aujourd’hui',
        action: 'Tout voir',
        onAction: widget.onVoirOperations,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Habibo.marge),
        child: Row(
          children: inventoriste
              ? [
                  _Compteur(
                    icone: LucideIcons.clipboardList,
                    valeur: magasin.compter(TypeJournal.inventaire),
                    libelle: 'Inventaires',
                    onTap: widget.onVoirOperations,
                  ),
                  const SizedBox(width: 12),
                  _Compteur(
                    icone: LucideIcons.layoutGrid,
                    valeur: magasin.emplacements.length,
                    libelle: 'Emplacements',
                    onTap: widget.onVoirOperations,
                  ),
                ]
              : [
                  _Compteur(
                    icone: LucideIcons.arrowDownLeft,
                    valeur: magasin.compter(TypeJournal.entree),
                    libelle: 'Entrées à recevoir',
                    onTap: widget.onVoirOperations,
                  ),
                  const SizedBox(width: 12),
                  _Compteur(
                    icone: LucideIcons.arrowUpRight,
                    valeur: magasin.compter(TypeJournal.sortie),
                    libelle: 'Sorties à préparer',
                    onTap: widget.onVoirOperations,
                  ),
                ],
        ),
      ),
      const SizedBox(height: 28),
      ..._alertes(),
      const TitreSection('Activité récente'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Habibo.marge),
        child: _activites(),
      ),
    ];
  }

  /// Produits a surveiller : un lot proche de sa date, un stock bas.
  List<Widget> _alertes() {
    final lignes = <Widget>[];

    for (final lot in magasin.lots) {
      final jours = joursAvant(lot.dlc);
      if (jours <= 15) {
        lignes.add(
          _LigneAlerte(
            article: lot.article,
            texte: 'Lot ${lot.emplacement.code} · expire dans $jours jours',
            couleur: Habibo.orange,
          ),
        );
      }
    }
    for (final article in magasin.articles) {
      if (magasin.stockBas(article)) {
        lignes.add(
          _LigneAlerte(
            article: article,
            texte:
                'Stock bas · ${article.unites(magasin.stockDisponible(article))} '
                'disponible${magasin.stockDisponible(article) > 1 ? 's' : ''}',
            couleur: Habibo.rouge,
          ),
        );
      }
    }

    if (lignes.isEmpty) return const [];
    final affichees = lignes.take(3).toList();

    return [
      const TitreSection('À surveiller'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Habibo.marge),
        child: Container(
          decoration: BoxDecoration(
            color: Habibo.surface,
            borderRadius: BorderRadius.circular(Habibo.rayonCarte),
            border: Border.all(color: Habibo.bordure),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < affichees.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, thickness: 1, color: Habibo.bordure),
                affichees[i],
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 28),
    ];
  }

  Widget _activites() {
    final activites = magasin.activites.take(4).toList();
    if (activites.isEmpty) {
      return const Carte(
        child: Text(
          'Vos scans apparaîtront ici.',
          style: TextStyle(color: Habibo.texteSecondaire, fontSize: 14),
        ),
      );
    }

    return Column(
      children: [
        for (final activite in activites)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Habibo.neutreDoux,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    switch (activite.type) {
                      TypeActivite.reception => LucideIcons.arrowDownLeft,
                      TypeActivite.prelevement => LucideIcons.arrowUpRight,
                      TypeActivite.comptage => LucideIcons.clipboardCheck,
                      TypeActivite.parcours => LucideIcons.route,
                    },
                    size: 18,
                    color: Habibo.texteSecondaire,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activite.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Habibo.texte,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activite.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Habibo.texteSecondaire,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ilYA(activite.date),
                  style: const TextStyle(
                    color: Habibo.texteDiscret,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// La seule grande zone bleue de l'accueil : reprendre l'operation en cours.
class _CarteReprendre extends StatelessWidget {
  const _CarteReprendre({required this.journal});

  final Journal journal;

  @override
  Widget build(BuildContext context) {
    final commencee =
        journal.parcours != null ||
        journal.receptions.isNotEmpty ||
        journal.emplacementsComptes.isNotEmpty;

    final resume = switch (journal.type) {
      TypeJournal.sortie =>
        journal.parcours == null
            ? '${journal.commandes.length} articles à préparer'
            : '${journal.parcours!.where((e) => e.terminee).length} sur '
                  '${journal.parcours!.length} emplacements prélevés',
      TypeJournal.entree =>
        '${journal.receptions.length} produit'
            '${journal.receptions.length > 1 ? 's' : ''} déjà reçu'
            '${journal.receptions.length > 1 ? 's' : ''}',
      TypeJournal.inventaire =>
        '${journal.emplacementsComptes.length} emplacement'
            '${journal.emplacementsComptes.length > 1 ? 's' : ''} compté'
            '${journal.emplacementsComptes.length > 1 ? 's' : ''}',
    };

    return Material(
      color: Habibo.bleu,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          retourLeger();
          ouvrirJournal(context, journal);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${journal.libelleType.toUpperCase()} '
                    '${commencee ? 'EN COURS' : 'À COMMENCER'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    switch (journal.type) {
                      TypeJournal.entree => LucideIcons.arrowDownLeft,
                      TypeJournal.sortie => LucideIcons.arrowUpRight,
                      TypeJournal.inventaire => LucideIcons.clipboardList,
                    },
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                journal.reference,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                journal.tiers ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              if (journal.type == TypeJournal.sortie &&
                  journal.parcours != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: journal.avancement),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, valeur, _) => LinearProgressIndicator(
                      value: valeur,
                      minHeight: 6,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      resume,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          commencee ? 'Reprendre' : 'Commencer',
                          style: const TextStyle(
                            color: Habibo.bleu,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          LucideIcons.arrowRight,
                          size: 16,
                          color: Habibo.bleu,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Compteur extends StatelessWidget {
  const _Compteur({
    required this.icone,
    required this.valeur,
    required this.libelle,
    required this.onTap,
  });

  final IconData icone;
  final int valeur;
  final String libelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Carte(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 20, color: Habibo.texteSecondaire),
            const SizedBox(height: 12),
            Text(
              '$valeur',
              style: const TextStyle(
                color: Habibo.texte,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              libelle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Habibo.texteSecondaire,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneAlerte extends StatelessWidget {
  const _LigneAlerte({
    required this.article,
    required this.texte,
    required this.couleur,
  });

  final Article article;
  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => FicheProduit(article: article))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            VignetteArticle(article: article, taille: 44),
            const SizedBox(width: 12),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    texte,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: couleur, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: Habibo.texteDiscret,
            ),
          ],
        ),
      ),
    );
  }
}
