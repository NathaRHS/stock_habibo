import 'package:flutter/material.dart';
import 'package:flutter_application/models/ligne_picking.dart';
import 'package:flutter_application/models/scan_ligne_response.dart';
import 'package:flutter_application/screens/ecran_scan_sortie_maquette.dart';
import 'package:flutter_application/services/picking_service.dart';

class EcranParcoursPickingMaquette extends StatefulWidget {
  const EcranParcoursPickingMaquette({
    super.key,
    required this.baseUrl,
    required this.accessToken,
    required this.journalId,
    required this.userId,
    this.rackDepartId = 1,
  });

  final String baseUrl;
  final String accessToken;
  final int journalId;
  final int userId;
  final int rackDepartId;

  @override
  State<EcranParcoursPickingMaquette> createState() =>
      _EcranParcoursPickingMaquetteState();
}

class _EcranParcoursPickingMaquetteState
    extends State<EcranParcoursPickingMaquette> {
  static const _bleu = Color(0xFF5A91D0);
  static const _bleuTexte = Color(0xFF1970DF);

  late final PickingService _pickingService;
  List<LignePicking> _etapes = [];
  bool _chargement = true;
  bool _scanEnCours = false;
  String? _erreur;

  bool _overlayOuvert = false;
  int _etapeSelectionnee = 0;

  @override
  void initState() {
    super.initState();
    _pickingService = PickingService(
      baseUrl: widget.baseUrl,
      accessToken: widget.accessToken,
    );
    _chargerParcours();
  }

  Future<void> _chargerParcours() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final parcoursActif = await _pickingService.chargerParcoursActif(
        journalId: widget.journalId,
      );

      final List<LignePicking> lignes;
      if (parcoursActif != null) {
        lignes = parcoursActif;
      } else {
        lignes = await _pickingService.genererMeilleurParcours(
          journalId: widget.journalId,
          userId: widget.userId,
          rackDepartId: widget.rackDepartId,
        );
      }
      if (!mounted) return;
      setState(() {
        _etapes = lignes;
        final premiereNonTerminee = lignes.indexWhere(
          (ligne) => ligne.statut != 'PRELEVEE',
        );
        _etapeSelectionnee = premiereNonTerminee >= 0 ? premiereNonTerminee : 0;
      });
    } catch (erreur) {
      if (!mounted) return;
      setState(() {
        _erreur = erreur.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _ouvrirProgression() {
    setState(() => _overlayOuvert = true);
  }

  void _fermerProgression() {
    setState(() => _overlayOuvert = false);
  }

  void _selectionnerEtape(int index) {
    setState(() => _etapeSelectionnee = index);
  }

  String _formaterDate(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year}';
  }

  Future<void> _scannerEtape() async {
    final etape = _etapes[_etapeSelectionnee];
    setState(() => _scanEnCours = true);
    final resultat = await Navigator.of(context).push<ScanLigneResponse>(
      MaterialPageRoute(
        builder: (_) => EcranScanSortieMaquette(
          baseUrl: widget.baseUrl,
          accessToken: widget.accessToken,
          ligne: etape,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _scanEnCours = false;
      if (resultat?.ligneTerminee == true) {
        _etapes[_etapeSelectionnee] = etape.copierAvec(statut: 'PRELEVEE');
        final prochaine = _etapes.indexWhere(
          (ligne) => ligne.statut != 'PRELEVEE',
        );
        if (prochaine >= 0) _etapeSelectionnee = prochaine;
      }
    });
    if (resultat != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultat.ligneTerminee
                ? 'Prélèvement terminé.'
                : '${resultat.quantiteRestante} conditionnement(s) restant(s).',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_erreur != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_erreur!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _chargerParcours,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_etapes.isEmpty) {
      return const Scaffold(body: Center(child: Text('Parcours vide.')));
    }
    final etape = _etapes[_etapeSelectionnee];

    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 492),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    _construirePage(etape),
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: !_overlayOuvert,
                        child: AnimatedOpacity(
                          opacity: _overlayOuvert ? 1 : 0,
                          duration: const Duration(milliseconds: 240),
                          child: GestureDetector(
                            onTap: _fermerProgression,
                            child: Container(color: Colors.black12),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 64,
                      right: 64,
                      child: IgnorePointer(
                        ignoring: !_overlayOuvert,
                        child: AnimatedSlide(
                          offset: _overlayOuvert
                              ? Offset.zero
                              : const Offset(0, -1.25),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeInOutCubic,
                          child: _construireOverlayCommandes(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _construirePage(LignePicking etape) {
    return ColoredBox(
      color: _bleu,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _construireEntete(),
                _construireIntroduction(),
                Expanded(child: _construireParcours()),
              ],
            ),
            Positioned(
              right: 28,
              top: 278,
              child: TextButton(
                onPressed: _ouvrirProgression,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),

                child: const Text('Voir la progression globale'),
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.38,
              minChildSize: 0.32,
              maxChildSize: 0.72,
              snap: true,
              snapSizes: const [0.38, 0.72],
              builder: (context, scrollController) {
                return _construireFiche(etape, scrollController);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _construireEntete() {
    return Container(
      height: 80,
      padding: const EdgeInsets.only(top: 23, right: 34),
      color: Colors.white,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sessions',
            style: TextStyle(color: Color(0xFFCECECE), fontSize: 11),
          ),
          SizedBox(width: 22),
          Text(
            'Se déconnecter',
            style: TextStyle(color: Color(0xFF3E3E3E), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _construireIntroduction() {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.only(left: 18, top: 72),
      color: const Color(0xFFE5F0FD),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meilleur emplacement',
            style: TextStyle(
              color: Color(0xFF303030),
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w400,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Les emplacements sont triés par ordre',
            style: TextStyle(color: Color(0xFF303030), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _construireParcours() {
    final lignes = <Widget>[];
    for (var debut = 0; debut < _etapes.length; debut += 5) {
      final fin = (debut + 5).clamp(0, _etapes.length);
      lignes.add(
        _LigneParcours(
          etapes: _etapes.sublist(debut, fin),
          indexDepart: debut,
          indexSelectionne: _etapeSelectionnee,
          onSelection: _selectionnerEtape,
        ),
      );
      if (fin < _etapes.length) lignes.add(const SizedBox(height: 38));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(23, 62, 23, 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: lignes),
    );
  }

  Widget _construireFiche(
    LignePicking etape,
    ScrollController scrollController,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(34, 10, 34, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2D2D2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'Emplacement ${etape.nomEmplacement}',
              style: const TextStyle(
                color: Color(0xFF303030),
                fontSize: 29,
                fontWeight: FontWeight.w400,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Text(
                  'Quantité à prélever :',
                  style: TextStyle(
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFBDBDBD),
                  ),
                ),
                const SizedBox(width: 13),
                Text(
                  '${etape.quantiteConditionnementsAPrelever} packs',
                  style: const TextStyle(color: _bleuTexte, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Icon(
                  Icons.push_pin_outlined,
                  color: _bleuTexte,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Text(
                  etape.nomEmplacement,
                  style: const TextStyle(color: _bleuTexte, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(width: 20, height: 1, color: const Color(0xFF909090)),
                const SizedBox(width: 8),
                Text(
                  'Ordre ${etape.ordrePassage}',
                  style: const TextStyle(color: _bleuTexte, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF222222),
                  size: 26,
                ),
                const SizedBox(width: 9),
                Text(
                  'DLC : ${_formaterDate(etape.dlc)}\nDLV : ${_formaterDate(etape.dlv)}',
                  style: const TextStyle(fontSize: 12, height: 1.25),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _scanEnCours || etape.statut == 'PRELEVEE'
                    ? null
                    : _scannerEtape,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF76A9D6),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      etape.statut == 'PRELEVEE' ? 'Prélevé' : 'Scanner',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text('+', style: TextStyle(fontSize: 22)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construireOverlayCommandes() {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(33)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 431,
        child: Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: Colors.white,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Liste des commandes',
                      style: TextStyle(fontSize: 19),
                    ),
                  ),
                  IconButton(
                    onPressed: _fermerProgression,
                    color: _bleuTexte,
                    iconSize: 15,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                itemCount: _etapes.length,
                itemBuilder: (context, index) {
                  final etape = _etapes[index];
                  final terminee = etape.statut == 'PRELEVEE';
                  return SizedBox(
                    height: 43,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 108,
                          child: Text(
                            etape.nomArticle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _bleuTexte,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _ProgressionCommande(
                            progression: terminee ? 1 : 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${etape.quantiteConditionnementsAPrelever} packs',
                          style: const TextStyle(
                            color: _bleuTexte,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneParcours extends StatelessWidget {
  const _LigneParcours({
    required this.etapes,
    required this.indexDepart,
    required this.indexSelectionne,
    required this.onSelection,
  });

  final List<LignePicking> etapes;
  final int indexDepart;
  final int indexSelectionne;
  final ValueChanged<int> onSelection;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < etapes.length; index++) ...[
          SizedBox(
            width: 51,
            height: 51,
            child: _NoeudParcours(
              code: etapes[index].nomEmplacement,
              selectionne: indexDepart + index == indexSelectionne,
              onTap: () => onSelection(indexDepart + index),
            ),
          ),
          if (index < etapes.length - 1)
            const Expanded(child: _ConnexionParcours()),
        ],
      ],
    );
  }
}

class _NoeudParcours extends StatelessWidget {
  const _NoeudParcours({
    required this.code,
    required this.selectionne,
    required this.onTap,
  });

  final String code;
  final bool selectionne;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: selectionne
            ? Colors.white
            : Colors.white.withValues(alpha: 0.24),
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              code,
              style: TextStyle(
                color: selectionne
                    ? const Color(0xFF1970DF)
                    : const Color(0xFF307FC7).withValues(alpha: 0.46),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnexionParcours extends StatelessWidget {
  const _ConnexionParcours();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(height: 2, color: Colors.white54),
          Container(
            width: 15,
            height: 15,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E5E5),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressionCommande extends StatelessWidget {
  const _ProgressionCommande({required this.progression});

  final double progression;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: LinearProgressIndicator(
          value: progression,
          color: const Color(0xFF3688ED),
          backgroundColor: const Color(0xFFD7D7D7),
        ),
      ),
    );
  }
}
