import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';
import 'fiche_produit.dart';
import 'scanner.dart';

/// Onglet Produits (proposition) : chercher un article, ou scanner un
/// code-barres pour le consulter. Ce scan ne modifie rien.
class Produits extends StatefulWidget {
  const Produits({super.key});

  @override
  State<Produits> createState() => _ProduitsState();
}

class _ProduitsState extends State<Produits> {
  final _rechercheController = TextEditingController();
  String _recherche = '';
  int _famille = 0;

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  void _ouvrir(Article article) {
    retourLeger();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => FicheProduit(article: article)));
  }

  Future<void> _scanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const EcranScanner(
          consigne: 'Scannez un produit pour voir sa fiche.',
        ),
      ),
    );
    if (!mounted || code == null) return;

    final article = magasin.articleParCode(code);
    if (article == null) {
      retourErreur();
      afficherMessage(
        context,
        'Aucun article ne correspond à $code.',
        icone: LucideIcons.circleAlert,
      );
      return;
    }
    _ouvrir(article);
  }

  // L'onglet se redessine quand le stock change (reservation, prelevement).
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: magasin,
    builder: (context, _) => _construire(context),
  );

  Widget _construire(BuildContext context) {
    final familles = ['Tous', ...magasin.familles];
    final texte = _recherche.trim().toLowerCase();

    final articles = magasin.articles.where((article) {
      if (_famille > 0 && article.famille != familles[_famille]) return false;
      if (texte.isEmpty) return true;
      return article.titre.toLowerCase().contains(texte) ||
          article.codeBarres.contains(texte) ||
          article.famille.toLowerCase().contains(texte);
    }).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Habibo.marge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${magasin.articles.length} références',
                  style: const TextStyle(
                    color: Habibo.texteSecondaire,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Produits',
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rechercheController,
                    onChanged: (valeur) => setState(() => _recherche = valeur),
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(color: Habibo.texte, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Nom ou code-barres',
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
                const SizedBox(width: 10),
                Material(
                  color: Habibo.bleu,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _scanner,
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        LucideIcons.scanLine,
                        size: 22,
                        color: Colors.white,
                        semanticLabel: 'Scanner un produit',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FiltresPastilles(
            filtres: [
              for (final famille in familles) FiltrePastille(libelle: famille),
            ],
            selection: _famille,
            onChange: (index) => setState(() => _famille = index),
          ),
          const SizedBox(height: 20),
          if (articles.isEmpty)
            const EtatVide(
              icone: LucideIcons.searchX,
              titre: 'Aucun produit',
              texte: 'Essayez un autre nom, ou scannez le code-barres.',
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
                    for (var i = 0; i < articles.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Habibo.bordure,
                        ),
                      _LigneProduit(
                        article: articles[i],
                        onTap: () => _ouvrir(articles[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LigneProduit extends StatelessWidget {
  const _LigneProduit({required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disponible = magasin.stockDisponible(article);
    final bas = magasin.stockBas(article);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            VignetteArticle(article: article, taille: 52, hero: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Habibo.texte,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${article.contenance} · ${article.famille}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Habibo.texteSecondaire,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$disponible',
                  style: TextStyle(
                    color: bas ? Habibo.rouge : Habibo.texte,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  bas ? 'stock bas' : 'dispo.',
                  style: TextStyle(
                    color: bas ? Habibo.rouge : Habibo.texteDiscret,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
