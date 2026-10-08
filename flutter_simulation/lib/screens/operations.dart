import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';
import 'navigation.dart';

/// Liste des journaux : c'est ici qu'on demarre une operation.
/// Reprend l'ecran « Journaux » de l'application reelle.
class Operations extends StatefulWidget {
  const Operations({super.key});

  @override
  State<Operations> createState() => _OperationsState();
}

class _OperationsState extends State<Operations> {
  final _rechercheController = TextEditingController();
  int _filtre = 0;
  String _recherche = '';
  bool _chargement = false;

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _rafraichir() async {
    setState(() => _chargement = true);
    await magasin.rafraichir();
    if (mounted) setState(() => _chargement = false);
  }

  bool _correspond(Journal journal, int filtre) => switch (filtre) {
    1 => journal.estOuvrable,
    2 => journal.estValide,
    _ => true,
  };

  // L'onglet se redessine a chaque changement de la simulation (role, statut).
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: magasin,
    builder: (context, _) => _construire(context),
  );

  Widget _construire(BuildContext context) {
    final tous = magasin.journauxVisibles;
    final texte = _recherche.trim().toLowerCase();
    final affiches = tous.where((journal) {
      if (!_correspond(journal, _filtre)) return false;
      if (texte.isEmpty) return true;
      return journal.reference.toLowerCase().contains(texte) ||
          (journal.tiers ?? '').toLowerCase().contains(texte);
    }).toList();

    int compter(int filtre) =>
        tous.where((journal) => _correspond(journal, filtre)).length;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: Habibo.bleu,
        onRefresh: _rafraichir,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Habibo.marge),
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
                  const Text(
                    'Journaux',
                    style: TextStyle(
                      color: Habibo.texte,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Habibo.marge),
              child: TextField(
                controller: _rechercheController,
                onChanged: (valeur) => setState(() => _recherche = valeur),
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: Habibo.texte, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Rechercher une référence',
                  hintStyle: const TextStyle(color: Habibo.texteDiscret),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 20,
                    color: Habibo.texteSecondaire,
                  ),
                  suffixIcon: _recherche.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Effacer',
                          onPressed: () {
                            _rechercheController.clear();
                            setState(() => _recherche = '');
                          },
                          icon: const Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Habibo.texteSecondaire,
                          ),
                        ),
                  filled: true,
                  fillColor: Habibo.neutreDoux,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FiltresPastilles(
              filtres: [
                FiltrePastille(libelle: 'Tous', compteur: compter(0)),
                FiltrePastille(libelle: 'En cours', compteur: compter(1)),
                FiltrePastille(libelle: 'Validés', compteur: compter(2)),
              ],
              selection: _filtre,
              onChange: (index) => setState(() => _filtre = index),
            ),
            const SizedBox(height: 20),
            if (_chargement)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Habibo.marge),
                child: Column(
                  children: [
                    Squelette(hauteur: 80, rayon: 16),
                    SizedBox(height: 10),
                    Squelette(hauteur: 80, rayon: 16),
                    SizedBox(height: 10),
                    Squelette(hauteur: 80, rayon: 16),
                  ],
                ),
              )
            else if (affiches.isEmpty)
              EtatVide(
                icone: LucideIcons.searchX,
                titre: tous.isEmpty ? 'Aucun journal' : 'Aucun résultat',
                texte: tous.isEmpty
                    ? 'Les opérations qui vous sont confiées apparaîtront ici.'
                    : 'Essayez une autre référence ou un autre filtre.',
              )
            else
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
                      for (var i = 0; i < affiches.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Habibo.bordure,
                          ),
                        _LigneJournal(journal: affiches[i]),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LigneJournal extends StatelessWidget {
  const _LigneJournal({required this.journal});

  final Journal journal;

  @override
  Widget build(BuildContext context) {
    final entree = journal.type == TypeJournal.entree;
    final icone = switch (journal.type) {
      TypeJournal.entree => LucideIcons.arrowDownLeft,
      TypeJournal.sortie => LucideIcons.arrowUpRight,
      TypeJournal.inventaire => LucideIcons.clipboardList,
    };
    final produits = journal.nombreProduits;
    final resume = journal.type == TypeJournal.inventaire
        ? (journal.tiers ?? journal.libelleType)
        : produits == 0
        ? journal.libelleType
        : '${journal.libelleType} · $produits produit${produits > 1 ? 's' : ''}';

    // Un journal non ouvrable reste lisible : il ne reagit pas au toucher.
    return Opacity(
      opacity: journal.estOuvrable ? 1 : 0.62,
      child: InkWell(
        onTap: journal.estOuvrable
            ? () {
                retourLeger();
                ouvrirJournal(context, journal);
              }
            : null,
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
      ),
    );
  }
}
