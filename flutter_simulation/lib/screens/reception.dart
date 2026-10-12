import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/magasin.dart';
import '../data/modeles.dart';
import '../theme/habibo.dart';
import '../widgets/commun.dart';
import 'scanner.dart';

/// Reception d'une entree : on scanne, on saisit les dates et la quantite.
/// Reprend l'ecran « Reception » (EcranScanSession) de l'application reelle,
/// avec en plus la photo du produit reconnu.
class EcranReception extends StatefulWidget {
  const EcranReception({super.key, required this.journal});

  final Journal journal;

  @override
  State<EcranReception> createState() => _EcranReceptionState();
}

class _EcranReceptionState extends State<EcranReception> {
  Article? _article;
  DateTime? _dlv;
  DateTime? _dlc;
  int _quantite = 1;

  bool _enregistrement = false;
  String? _erreurCode;
  String? _erreurDates;
  DetailReception? _dernier;

  Future<void> _scanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            const EcranScanner(consigne: 'Scannez le conditionnement reçu.'),
      ),
    );
    if (!mounted || code == null) return;

    final article = magasin.articleParCode(code);
    setState(() {
      _article = article;
      _erreurCode = article == null ? 'Code-barres inconnu : $code' : null;
      _dernier = null;
    });
    if (article == null) retourErreur();
  }

  Future<void> _choisirDate({required bool dlc}) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          (dlc ? _dlc : _dlv) ??
          DateTime.now().add(Duration(days: dlc ? 180 : 160)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    setState(() {
      if (dlc) {
        _dlc = date;
      } else {
        _dlv = date;
      }
      _erreurDates = null;
    });
  }

  Future<void> _ajouter() async {
    String? erreurDates;
    if (_dlv == null || _dlc == null) {
      erreurDates = 'Renseignez la DLV et la DLC.';
    } else if (_dlv!.isAfter(_dlc!)) {
      erreurDates = 'La DLV ne peut pas dépasser la DLC.';
    }

    setState(() {
      _erreurCode = _article == null ? 'Scannez d’abord un produit.' : null;
      _erreurDates = erreurDates;
    });
    if (_erreurCode != null || _erreurDates != null) {
      retourErreur();
      return;
    }

    setState(() => _enregistrement = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final detail = magasin.recevoir(
      widget.journal,
      _article!,
      _quantite,
      _dlc!,
      _dlv!,
    );
    retourSucces();
    setState(() {
      _enregistrement = false;
      _dernier = detail;
      _article = null;
      _dlc = null;
      _dlv = null;
      _quantite = 1;
    });
  }

  Future<void> _terminer() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer votre partie ?'),
        content: const Text(
          'Vous ne pourrez plus scanner dans cette session. Elle sera envoyée '
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
            child: const Text('Terminer'),
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
      'Réception envoyée au contrôle.',
      icone: LucideIcons.circleCheck,
    );
  }

  @override
  Widget build(BuildContext context) {
    final journal = widget.journal;

    return Scaffold(
      backgroundColor: Habibo.fond,
      body: SafeArea(
        child: Column(
          children: [
            EnTetePage(
              titre: 'Réception',
              sousTitre: journal.reference,
              action: TextButton(
                onPressed: _enregistrement ? null : _terminer,
                style: TextButton.styleFrom(
                  foregroundColor: Habibo.bleu,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Terminer',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
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
                  _libelle('Produit'),
                  _zoneProduit(),
                  _texteErreur(_erreurCode),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _champDate(
                          libelle: 'DLV',
                          date: _dlv,
                          onTap: () => _choisirDate(dlc: false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _champDate(
                          libelle: 'DLC',
                          date: _dlc,
                          onTap: () => _choisirDate(dlc: true),
                        ),
                      ),
                    ],
                  ),
                  _texteErreur(_erreurDates),
                  const SizedBox(height: 20),
                  _libelle('Quantité reçue'),
                  SelecteurQuantite(
                    valeur: _quantite,
                    unite: _article?.unite ?? 'unité',
                    onChange: (valeur) => setState(() => _quantite = valeur),
                  ),
                  if (_dernier != null) ...[
                    const SizedBox(height: 16),
                    _confirmation(_dernier!),
                  ],
                  const SizedBox(height: 32),
                  _produitsDuJournal(journal),
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
                libelle: 'Ajouter le produit',
                chargement: _enregistrement,
                onPressed: _ajouter,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoneProduit() {
    final article = _article;

    if (article == null) {
      return ZoneScan(
        libelle: 'Scanner le code-barres',
        aide: 'Le produit sera reconnu automatiquement',
        onTap: _scanner,
      );
    }

    return Carte(
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
          const Icon(LucideIcons.scanLine, size: 20, color: Habibo.bleu),
        ],
      ),
    );
  }

  Widget _champDate({
    required String libelle,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _libelle(libelle),
        Material(
          color: Habibo.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Habibo.rayon),
            side: const BorderSide(color: Habibo.bordure),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      date == null ? 'Choisir' : formaterDate(date),
                      style: TextStyle(
                        color: date == null
                            ? Habibo.texteDiscret
                            : Habibo.texte,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(
                    LucideIcons.calendar,
                    size: 18,
                    color: Habibo.texteSecondaire,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _confirmation(DetailReception detail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Habibo.vertDoux,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleCheck, color: Habibo.vert, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${detail.article.titre} ajouté · total '
              '${detail.article.unites(detail.quantite)}',
              style: const TextStyle(color: Habibo.vert, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _produitsDuJournal(Journal journal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Produits du journal',
                style: TextStyle(
                  color: Habibo.texte,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${journal.receptions.length}',
              style: const TextStyle(color: Habibo.texteDiscret, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (journal.receptions.isEmpty)
          const Text(
            'Aucun produit pour le moment.',
            style: TextStyle(color: Habibo.texteSecondaire, fontSize: 14),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Habibo.surface,
              borderRadius: BorderRadius.circular(Habibo.rayonCarte),
              border: Border.all(color: Habibo.bordure),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < journal.receptions.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Habibo.bordure,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        VignetteArticle(
                          article: journal.receptions[i].article,
                          taille: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                journal.receptions[i].article.titre,
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
                                'DLC ${formaterDate(journal.receptions[i].dlc)}',
                                style: const TextStyle(
                                  color: Habibo.texteSecondaire,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          journal.receptions[i].article.unites(
                            journal.receptions[i].quantite,
                          ),
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
          ),
      ],
    );
  }

  Widget _libelle(String texte) {
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

  Widget _texteErreur(String? erreur) {
    if (erreur == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        erreur,
        style: const TextStyle(color: Habibo.rouge, fontSize: 13),
      ),
    );
  }
}

/// Grande zone a toucher pour ouvrir le scanner.
class ZoneScan extends StatelessWidget {
  const ZoneScan({
    super.key,
    required this.libelle,
    required this.aide,
    required this.onTap,
  });

  final String libelle;
  final String aide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Habibo.bleuDoux,
      borderRadius: BorderRadius.circular(Habibo.rayonCarte),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          retourLeger();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Habibo.bleu,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.scanLine,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libelle,
                      style: const TextStyle(
                        color: Habibo.bleu,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      aide,
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
}

/// Moins / valeur / plus, avec de grandes cibles pour le pouce.
class SelecteurQuantite extends StatelessWidget {
  const SelecteurQuantite({
    super.key,
    required this.valeur,
    required this.unite,
    required this.onChange,
    this.maximum,
  });

  final int valeur;
  final String unite;
  final ValueChanged<int> onChange;
  final int? maximum;

  @override
  Widget build(BuildContext context) {
    Widget bouton(IconData icone, int ecart) {
      final nouvelle = valeur + ecart;
      final actif = nouvelle >= 1 && (maximum == null || nouvelle <= maximum!);

      return Material(
        color: actif
            ? Habibo.neutreDoux
            : Habibo.neutreDoux.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: actif
              ? () {
                  retourLeger();
                  onChange(nouvelle);
                }
              : null,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              icone,
              size: 20,
              color: actif ? Habibo.texte : Habibo.texteDiscret,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Habibo.surface,
        borderRadius: BorderRadius.circular(Habibo.rayonCarte),
        border: Border.all(color: Habibo.bordure),
      ),
      child: Row(
        children: [
          bouton(LucideIcons.minus, -1),
          Expanded(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  transitionBuilder: (enfant, animation) =>
                      ScaleTransition(scale: animation, child: enfant),
                  child: Text(
                    '$valeur',
                    key: ValueKey(valeur),
                    style: const TextStyle(
                      color: Habibo.texte,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  '$unite${valeur > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Habibo.texteSecondaire,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          bouton(LucideIcons.plus, 1),
        ],
      ),
    );
  }
}
