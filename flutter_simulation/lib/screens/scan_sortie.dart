import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';
import 'scanner.dart';

/// Prelevement d'une etape : on scanne le conditionnement, puis on saisit la
/// quantite au pave numerique. Renvoie la quantite prelevee.
class EcranScanSortie extends StatefulWidget {
  const EcranScanSortie({
    super.key,
    required this.journal,
    required this.etape,
  });

  final Journal journal;
  final EtapePicking etape;

  @override
  State<EcranScanSortie> createState() => _EcranScanSortieState();
}

class _EcranScanSortieState extends State<EcranScanSortie> {
  bool _produitVerifie = false;
  String _quantite = '';
  String? _erreur;
  bool _enregistrement = false;

  int get _maximum => widget.etape.restant;

  Future<void> _scanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EcranScanner(
          consigne:
              'Scannez ${widget.etape.article.nom} à '
              '${widget.etape.emplacement.code}.',
          attendu: widget.etape.article,
        ),
      ),
    );
    if (!mounted || code == null) return;

    final bonProduit = code == widget.etape.article.codeBarres;
    if (!bonProduit) retourErreur();

    setState(() {
      _produitVerifie = bonProduit;
      _erreur = bonProduit
          ? null
          : 'Ce n’est pas le bon produit. Attendu : '
                '${widget.etape.article.titre}.';
    });
  }

  void _saisir(String touche) {
    retourLeger();
    setState(() {
      _erreur = null;
      if (touche == 'effacer') {
        if (_quantite.isNotEmpty) {
          _quantite = _quantite.substring(0, _quantite.length - 1);
        }
      } else if (touche == 'max') {
        _quantite = '$_maximum';
      } else if (_quantite.length < 4) {
        _quantite = _quantite == '0' ? touche : '$_quantite$touche';
      }
    });
  }

  Future<void> _confirmer() async {
    final quantite = int.tryParse(_quantite);

    String? erreur;
    if (!_produitVerifie) {
      erreur = 'Scannez d’abord le conditionnement.';
    } else if (quantite == null || quantite <= 0) {
      erreur = 'Saisissez une quantité valide.';
    } else if (quantite > _maximum) {
      erreur = 'Maximum prévu : ${widget.etape.article.unites(_maximum)}.';
    }

    if (erreur != null) {
      retourErreur();
      setState(() => _erreur = erreur);
      return;
    }

    setState(() => _enregistrement = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    magasin.prelever(widget.journal, widget.etape, quantite!);
    retourSucces();
    Navigator.of(context).pop(quantite);
  }

  @override
  Widget build(BuildContext context) {
    final etape = widget.etape;
    final article = etape.article;

    return Scaffold(
      backgroundColor: Habibo.fond,
      body: SafeArea(
        child: Column(
          children: [
            EnTetePage(
              titre: 'Prélèvement',
              sousTitre: 'Emplacement ${etape.emplacement.code}',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Habibo.marge,
                  8,
                  Habibo.marge,
                  16,
                ),
                children: [
                  Row(
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
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${etape.emplacement.nomRack} · '
                              '${etape.emplacement.code} · DLC '
                              '${formaterDate(etape.lot.dlc)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Habibo.texteSecondaire,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _zoneVerification(),
                  const SizedBox(height: 18),
                  _affichageQuantite(article),
                  const SizedBox(height: 12),
                  _pave(),
                  if (_erreur != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Habibo.rougeDoux,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.circleAlert,
                            color: Habibo.rouge,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _erreur!,
                              style: const TextStyle(
                                color: Habibo.rouge,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                libelle: 'Confirmer le prélèvement',
                icone: LucideIcons.check,
                chargement: _enregistrement,
                onPressed: _confirmer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoneVerification() {
    final verifie = _produitVerifie;

    return Material(
      color: verifie ? Habibo.vertDoux : Habibo.bleuDoux,
      borderRadius: BorderRadius.circular(Habibo.rayonCarte),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _enregistrement ? null : _scanner,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: verifie ? Habibo.vert : Habibo.bleu,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  verifie ? LucideIcons.check : LucideIcons.scanLine,
                  size: 21,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verifie
                          ? 'Produit vérifié'
                          : 'Scanner le conditionnement',
                      style: TextStyle(
                        color: verifie ? Habibo.vert : Habibo.bleu,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      verifie
                          ? widget.etape.article.codeBarres
                          : 'Pour vérifier que c’est le bon produit',
                      style: const TextStyle(
                        color: Habibo.texteSecondaire,
                        fontSize: 13,
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

  Widget _affichageQuantite(Article article) {
    final vide = _quantite.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Habibo.surface,
        borderRadius: BorderRadius.circular(Habibo.rayonCarte),
        border: Border.all(color: Habibo.bordure),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            vide ? '0' : _quantite,
            style: TextStyle(
              color: vide ? Habibo.texteDiscret : Habibo.texte,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '${article.unite}s prélevés',
              style: const TextStyle(
                color: Habibo.texteSecondaire,
                fontSize: 14,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              'sur $_maximum',
              style: const TextStyle(
                color: Habibo.texteSecondaire,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pave() {
    const touches = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'max',
      '0',
      'effacer',
    ];

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final touche in touches)
          Material(
            color: touche == 'max' || touche == 'effacer'
                ? Habibo.neutreDoux
                : Habibo.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Habibo.bordure),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _enregistrement ? null : () => _saisir(touche),
              child: Center(
                child: switch (touche) {
                  'effacer' => const Icon(
                    LucideIcons.delete,
                    size: 21,
                    color: Habibo.texte,
                  ),
                  'max' => const Text(
                    'Tout',
                    style: TextStyle(
                      color: Habibo.bleu,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _ => Text(
                    touche,
                    style: const TextStyle(
                      color: Habibo.texte,
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                },
              ),
            ),
          ),
      ],
    );
  }
}
