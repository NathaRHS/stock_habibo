import 'package:flutter/material.dart';

class EcranParcoursPickingMaquette extends StatefulWidget {
  const EcranParcoursPickingMaquette({super.key});

  @override
  State<EcranParcoursPickingMaquette> createState() =>
      _EcranParcoursPickingMaquetteState();
}

class _EcranParcoursPickingMaquetteState
    extends State<EcranParcoursPickingMaquette> {
  static const _bleu = Color(0xFF5A91D0);
  static const _bleuTexte = Color(0xFF1970DF);

  final List<_EtapePicking> _etapes = const [
    _EtapePicking(
      code: 'A004',
      rack: 'Rack A',
      etage: 2,
      article: 'Lait Candia UHT',
      quantite: 24,
      dlc: '14/12/2026',
      dlv: '17/12/2026',
    ),
    _EtapePicking(
      code: 'A001',
      rack: 'Rack A',
      etage: 1,
      article: 'Lait Candia UHT',
      quantite: 18,
      dlc: '20/12/2026',
      dlv: '12/12/2026',
    ),
    _EtapePicking(
      code: 'A006',
      rack: 'Rack A',
      etage: 1,
      article: 'Coca-Cola 30 cl',
      quantite: 15,
      dlc: '15/02/2027',
      dlv: '01/02/2027',
    ),
    _EtapePicking(
      code: 'A009',
      rack: 'Rack A',
      etage: 2,
      article: 'Coca-Cola 30 cl',
      quantite: 10,
      dlc: '15/02/2027',
      dlv: '01/02/2027',
    ),
    _EtapePicking(
      code: 'A011',
      rack: 'Rack A',
      etage: 3,
      article: 'Eau Vive 1,5 L',
      quantite: 8,
      dlc: '30/04/2027',
      dlv: '15/04/2027',
    ),
    _EtapePicking(
      code: 'B004',
      rack: 'Rack B',
      etage: 2,
      article: 'Eau Vive 1,5 L',
      quantite: 12,
      dlc: '30/04/2027',
      dlv: '15/04/2027',
    ),
    _EtapePicking(
      code: 'B001',
      rack: 'Rack B',
      etage: 1,
      article: 'Farine T45',
      quantite: 6,
      dlc: '04/11/2027',
      dlv: '20/10/2027',
    ),
    _EtapePicking(
      code: 'B006',
      rack: 'Rack B',
      etage: 2,
      article: 'Riz long grain',
      quantite: 9,
      dlc: '18/08/2027',
      dlv: '04/08/2027',
    ),
    _EtapePicking(
      code: 'B009',
      rack: 'Rack B',
      etage: 3,
      article: 'Café moulu',
      quantite: 14,
      dlc: '11/06/2027',
      dlv: '28/05/2027',
    ),
    _EtapePicking(
      code: 'B011',
      rack: 'Rack B',
      etage: 1,
      article: 'Sucre en poudre',
      quantite: 20,
      dlc: '03/02/2028',
      dlv: '20/01/2028',
    ),
  ];

  bool _overlayOuvert = false;
  int _etapeSelectionnee = 0;

  void _ouvrirProgression() {
    setState(() => _overlayOuvert = true);
  }

  void _fermerProgression() {
    setState(() => _overlayOuvert = false);
  }

  void _selectionnerEtape(int index) {
    setState(() => _etapeSelectionnee = index);
  }

  void _simulerScan() {
    final etape = _etapes[_etapeSelectionnee];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulation : ouverture du scanner pour ${etape.code}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _construirePage(_EtapePicking etape) {
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
    final premiereLigne = _etapes.take(5).toList();
    final deuxiemeLigne = _etapes.skip(5).take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(23, 62, 23, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LigneParcours(
            etapes: premiereLigne,
            indexDepart: 0,
            indexSelectionne: _etapeSelectionnee,
            onSelection: _selectionnerEtape,
          ),
          const SizedBox(height: 38),
          _LigneParcours(
            etapes: deuxiemeLigne,
            indexDepart: 5,
            indexSelectionne: _etapeSelectionnee,
            onSelection: _selectionnerEtape,
          ),
        ],
      ),
    );
  }

  Widget _construireFiche(
    _EtapePicking etape,
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
              'Emplacement ${etape.code}',
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
                  '${etape.quantite} packs',
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
                  '${etape.rack} , ${etape.code}',
                  style: const TextStyle(color: _bleuTexte, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(width: 20, height: 1, color: const Color(0xFF909090)),
                const SizedBox(width: 8),
                Text(
                  'Etage ${etape.etage}',
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
                  'DLC : ${etape.dlc}\nDLV : ${etape.dlv}',
                  style: const TextStyle(fontSize: 12, height: 1.25),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _simulerScan,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF76A9D6),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Scanner',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 9),
                    Text('+', style: TextStyle(fontSize: 22)),
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
                itemCount: 8,
                itemBuilder: (context, index) {
                  return const SizedBox(
                    height: 43,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 108,
                          child: Text(
                            'Lait Candia UHT',
                            maxLines: 1,
                            style: TextStyle(color: _bleuTexte, fontSize: 13),
                          ),
                        ),
                        Expanded(child: _ProgressionCommande()),
                        SizedBox(width: 8),
                        Text(
                          '150 boîtes',
                          style: TextStyle(color: _bleuTexte, fontSize: 13),
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

  final List<_EtapePicking> etapes;
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
              code: etapes[index].code,
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
  const _ProgressionCommande();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: const SizedBox(
        height: 6,
        child: LinearProgressIndicator(
          value: 0.4,
          color: Color(0xFF3688ED),
          backgroundColor: Color(0xFFD7D7D7),
        ),
      ),
    );
  }
}

class _EtapePicking {
  const _EtapePicking({
    required this.code,
    required this.rack,
    required this.etage,
    required this.article,
    required this.quantite,
    required this.dlc,
    required this.dlv,
  });

  final String code;
  final String rack;
  final int etage;
  final String article;
  final int quantite;
  final String dlc;
  final String dlv;
}
