import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';
import 'reception.dart';
import 'scanner.dart';

/// Inventaire : on choisit un emplacement sur le plan du rack, puis on compte.
/// Reprend « Choisir un emplacement » de l'application reelle.
class EcranInventaire extends StatefulWidget {
  const EcranInventaire({super.key, required this.journal});

  final Journal journal;

  @override
  State<EcranInventaire> createState() => _EcranInventaireState();
}

class _EcranInventaireState extends State<EcranInventaire> {
  static const _racks = ['A', 'B', 'C', 'D'];

  int _rack = 0;
  late Emplacement _selection = magasin.emplacements.first;

  Lot? _lot(Emplacement emplacement) {
    final lots = magasin.lotsEmplacement(emplacement);
    return lots.isEmpty ? null : lots.first;
  }

  Future<void> _compter() async {
    final emplacement = _selection;
    final enregistre = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EcranComptage(
          journal: widget.journal,
          emplacement: emplacement,
          lot: _lot(emplacement),
        ),
      ),
    );
    if (!mounted || enregistre != true) return;

    // Passe a l'emplacement suivant non compte du meme rack.
    final suivants = magasin.emplacements.where(
      (e) =>
          e.rack == emplacement.rack &&
          !widget.journal.emplacementsComptes.contains(e.id),
    );
    setState(() {
      if (suivants.isNotEmpty) _selection = suivants.first;
    });
    afficherMessage(
      context,
      'Comptage enregistré pour ${emplacement.code}.',
      icone: LucideIcons.circleCheck,
      decalageBas: 132,
    );
  }

  Future<void> _terminer() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer votre partie ?'),
        content: const Text(
          'Vous ne pourrez plus compter dans cette session. Elle sera envoyée '
          'au contrôle de l’administrateur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Habibo.bleu),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
    if (confirmation != true || !mounted) return;

    magasin.terminerParticipation(widget.journal);
    retourSucces();
    Navigator.of(context).pop();
    afficherMessage(
      context,
      'Inventaire envoyé au contrôle.',
      icone: LucideIcons.circleCheck,
    );
  }

  @override
  Widget build(BuildContext context) {
    final journal = widget.journal;
    final rack = _racks[_rack];
    final comptes = journal.emplacementsComptes.length;
    final total = magasin.emplacements.length;

    return Scaffold(
      backgroundColor: Habibo.fond,
      body: SafeArea(
        child: Column(
          children: [
            EnTetePage(titre: 'Inventaire', sousTitre: journal.reference),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Habibo.marge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$comptes sur $total emplacements comptés',
                          style: const TextStyle(
                            color: Habibo.texteSecondaire,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: comptes / total,
                            minHeight: 6,
                            color: Habibo.bleu,
                            backgroundColor: Habibo.neutreDoux,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FiltresPastilles(
                    filtres: [
                      for (final lettre in _racks)
                        FiltrePastille(
                          libelle: 'Rack $lettre',
                          compteur: magasin.emplacements
                              .where(
                                (e) =>
                                    e.rack == lettre &&
                                    journal.emplacementsComptes.contains(e.id),
                              )
                              .length,
                        ),
                    ],
                    selection: _rack,
                    onChange: (index) => setState(() {
                      _rack = index;
                      _selection = magasin.emplacements.firstWhere(
                        (e) => e.rack == _racks[index],
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Habibo.marge,
                    ),
                    child: _plan(rack),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Habibo.marge,
                    ),
                    child: _resume(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Habibo.marge,
                8,
                Habibo.marge,
                4,
              ),
              child: BoutonPrincipal(
                libelle: 'Compter ${_selection.code}',
                icone: LucideIcons.scanLine,
                onPressed: _compter,
              ),
            ),
            TextButton(
              onPressed: _terminer,
              style: TextButton.styleFrom(foregroundColor: Habibo.bleu),
              child: const Text(
                'J’ai terminé ma partie',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  /// Plan du rack : les etages du haut vers le bas, quatre positions.
  Widget _plan(String rack) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Habibo.surface,
        borderRadius: BorderRadius.circular(Habibo.rayonCarte),
        border: Border.all(color: Habibo.bordure),
      ),
      child: Column(
        children: [
          for (var etage = 3; etage >= 1; etage--) ...[
            Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    'É$etage',
                    style: const TextStyle(
                      color: Habibo.texteDiscret,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final emplacement in magasin.emplacements.where(
                  (e) => e.rack == rack && e.etage == etage,
                ))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _Case(
                        emplacement: emplacement,
                        occupe: _lot(emplacement) != null,
                        compte: widget.journal.emplacementsComptes.contains(
                          emplacement.id,
                        ),
                        selectionne: emplacement.id == _selection.id,
                        onTap: () {
                          retourLeger();
                          setState(() => _selection = emplacement);
                        },
                      ),
                    ),
                  ),
              ],
            ),
            if (etage > 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _resume() {
    final lot = _lot(_selection);
    final compte = widget.journal.emplacementsComptes.contains(_selection.id);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Carte(
        key: ValueKey(_selection.id),
        child: Row(
          children: [
            if (lot == null)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Habibo.neutreDoux,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.packageOpen,
                  size: 22,
                  color: Habibo.texteDiscret,
                ),
              )
            else
              VignetteArticle(article: lot.article, taille: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selection.code} · ${_selection.nomRack}, étage '
                    '${_selection.etage}',
                    style: const TextStyle(
                      color: Habibo.texteSecondaire,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lot == null ? 'Emplacement vide' : lot.article.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Habibo.texte,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (lot != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Stock attendu : ${lot.article.unites(lot.unites)}',
                      style: const TextStyle(
                        color: Habibo.texteSecondaire,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (compte)
              const Etiquette(
                texte: 'Compté',
                couleur: Habibo.vert,
                fond: Habibo.vertDoux,
                icone: LucideIcons.check,
              ),
          ],
        ),
      ),
    );
  }
}

class _Case extends StatelessWidget {
  const _Case({
    required this.emplacement,
    required this.occupe,
    required this.compte,
    required this.selectionne,
    required this.onTap,
  });

  final Emplacement emplacement;
  final bool occupe;
  final bool compte;
  final bool selectionne;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fond = selectionne
        ? Habibo.bleu
        : compte
        ? Habibo.vertDoux
        : occupe
        ? Habibo.bleuDoux
        : Habibo.fond;
    final couleur = selectionne
        ? Colors.white
        : compte
        ? Habibo.vert
        : occupe
        ? Habibo.bleu
        : Habibo.texteDiscret;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selectionne ? Habibo.bleu : Habibo.bordure),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emplacement.code,
              style: TextStyle(
                color: couleur,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (compte && !selectionne)
              const Icon(LucideIcons.check, size: 12, color: Habibo.vert),
          ],
        ),
      ),
    );
  }
}

/// Comptage d'un emplacement : produit scanne et quantite comptee.
class EcranComptage extends StatefulWidget {
  const EcranComptage({
    super.key,
    required this.journal,
    required this.emplacement,
    this.lot,
  });

  final Journal journal;
  final Emplacement emplacement;

  /// Ce que le systeme pense trouver a cet emplacement.
  final Lot? lot;

  @override
  State<EcranComptage> createState() => _EcranComptageState();
}

class _EcranComptageState extends State<EcranComptage> {
  Article? _article;
  late int _quantite = widget.lot?.unites ?? 1;
  String? _erreur;
  bool _enregistrement = false;

  Future<void> _scanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EcranScanner(
          consigne: 'Scannez le produit présent à ${widget.emplacement.code}.',
          attendu: widget.lot?.article,
        ),
      ),
    );
    if (!mounted || code == null) return;

    final article = magasin.articleParCode(code);
    setState(() {
      _article = article;
      _erreur = article == null ? 'Code-barres inconnu : $code' : null;
    });
    if (article == null) retourErreur();
  }

  Future<void> _enregistrer() async {
    final article = _article;
    if (article == null) {
      retourErreur();
      setState(() => _erreur = 'Scannez d’abord le produit.');
      return;
    }

    setState(() => _enregistrement = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    magasin.compterEmplacement(
      widget.journal,
      widget.emplacement,
      article,
      _quantite,
    );
    retourSucces();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final lot = widget.lot;
    final article = _article;

    return Scaffold(
      backgroundColor: Habibo.fond,
      body: SafeArea(
        child: Column(
          children: [
            EnTetePage(
              titre: 'Comptage',
              sousTitre:
                  '${widget.emplacement.code} · ${widget.emplacement.nomRack}',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Habibo.marge,
                  12,
                  Habibo.marge,
                  24,
                ),
                children: [
                  const _Libelle('Produit trouvé'),
                  if (article == null)
                    ZoneScan(
                      libelle: 'Scanner le produit',
                      aide: lot == null
                          ? 'Aucun stock n’est attendu ici'
                          : 'Attendu : ${lot.article.titre}',
                      onTap: _scanner,
                    )
                  else
                    Carte(
                      onTap: _scanner,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          VignetteArticle(article: article, taille: 56),
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
                                  article.codeBarres,
                                  style: const TextStyle(
                                    color: Habibo.texteSecondaire,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.scanLine,
                            size: 20,
                            color: Habibo.bleu,
                          ),
                        ],
                      ),
                    ),
                  if (_erreur != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _erreur!,
                        style: const TextStyle(
                          color: Habibo.rouge,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  const _Libelle('Quantité comptée'),
                  SelecteurQuantite(
                    valeur: _quantite,
                    unite: (article ?? lot?.article)?.unite ?? 'unité',
                    onChange: (valeur) => setState(() => _quantite = valeur),
                  ),
                  if (article != null) ...[
                    const SizedBox(height: 16),
                    _ecart(article),
                  ],
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
              child: BoutonPrincipal(
                libelle: 'Enregistrer le comptage',
                chargement: _enregistrement,
                onPressed: _enregistrer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compare le comptage au stock attendu, avant meme d'enregistrer.
  Widget _ecart(Article article) {
    final lot = widget.lot;
    final String texte;
    final bool conforme;

    if (lot == null) {
      texte = 'Produit non attendu à cet emplacement.';
      conforme = false;
    } else if (lot.article.id != article.id) {
      texte = 'Produit différent de celui attendu (${lot.article.titre}).';
      conforme = false;
    } else if (lot.unites == _quantite) {
      texte = 'Conforme au stock attendu.';
      conforme = true;
    } else {
      final ecart = _quantite - lot.unites;
      texte =
          'Écart : ${ecart > 0 ? '+' : ''}$ecart ${article.unite}'
          '${ecart.abs() > 1 ? 's' : ''} par rapport au stock attendu.';
      conforme = false;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: conforme ? Habibo.vertDoux : Habibo.orangeDoux,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            conforme ? LucideIcons.circleCheck : LucideIcons.triangleAlert,
            color: conforme ? Habibo.vert : Habibo.orange,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: TextStyle(
                color: conforme ? Habibo.vert : Habibo.orange,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Libelle extends StatelessWidget {
  const _Libelle(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texte,
        style: const TextStyle(
          color: Habibo.texte,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
