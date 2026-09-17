import 'package:flutter/material.dart';
import 'package:flutter_application/models/ligne_picking.dart';
import 'package:flutter_application/models/scan_ligne_response.dart';
import 'package:flutter_application/screens/ecran_scanner_code_barres.dart';
import 'package:flutter_application/services/picking_service.dart';

class EcranScanSortieMaquette extends StatefulWidget {
  const EcranScanSortieMaquette({
    super.key,
    required this.baseUrl,
    required this.accessToken,
    required this.ligne,
  });

  final String baseUrl;
  final String accessToken;
  final LignePicking ligne;

  @override
  State<EcranScanSortieMaquette> createState() =>
      _EcranScanSortieMaquetteState();
}

class _EcranScanSortieMaquetteState extends State<EcranScanSortieMaquette> {
  static const _bleu = Color(0xFF5A91D0);
  late final PickingService _service;
  String? _codeBarres;
  String _quantite = '';
  String? _erreur;
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _service = PickingService(
      baseUrl: widget.baseUrl,
      accessToken: widget.accessToken,
    );
  }

  Future<void> _ouvrirScanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const EcranScannerCodeBarres()),
    );
    if (!mounted || code == null) return;
    setState(() {
      _codeBarres = code;
      _erreur = null;
    });
  }

  void _saisir(String touche) {
    setState(() {
      _erreur = null;
      if (touche == 'x') {
        if (_quantite.isNotEmpty) {
          _quantite = _quantite.substring(0, _quantite.length - 1);
        }
      } else if (_quantite.length < 4) {
        _quantite = '$_quantite$touche';
      }
    });
  }

  Future<void> _confirmer() async {
    final quantite = int.tryParse(_quantite);
    if (_codeBarres == null) {
      setState(() => _erreur = 'Scannez d’abord le conditionnement.');
      return;
    }
    if (quantite == null || quantite <= 0) {
      setState(() => _erreur = 'Saisissez une quantité valide.');
      return;
    }
    if (quantite > widget.ligne.quantiteConditionnementsAPrelever) {
      setState(
        () => _erreur =
            'Maximum prévu : ${widget.ligne.quantiteConditionnementsAPrelever} packs.',
      );
      return;
    }

    setState(() {
      _enregistrement = true;
      _erreur = null;
    });
    try {
      final resultat = await _service.scannerLigne(
        lignePickingId: widget.ligne.id,
        codeBarres: _codeBarres!,
        quantiteConditionnement: quantite,
        dlc: widget.ligne.dlc,
        dlv: widget.ligne.dlv,
      );
      if (mounted) Navigator.pop<ScanLigneResponse>(context, resultat);
    } catch (erreur) {
      if (!mounted) return;
      setState(
        () => _erreur = erreur.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  String _date(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year}';
  }

  String get _rack {
    final nom = widget.ligne.nomEmplacement.trim();
    return 'Rack ${nom.isEmpty ? '?' : nom.substring(0, 1).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final ligne = widget.ligne;
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: ColoredBox(
            color: _bleu,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _entete(),
                  Container(
                    height: 206,
                    width: double.infinity,
                    color: const Color(0xFFE5F0FD),
                    padding: const EdgeInsets.fromLTRB(20, 63, 20, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prélèvement à effectuer',
                          style: TextStyle(
                            fontSize: 21,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                ligne.nomArticle,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const Icon(Icons.calendar_month_outlined, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'DLC : ${_date(ligne.dlc)}\nDLV : ${_date(ligne.dlv)}',
                              style: const TextStyle(fontSize: 11, height: 1.3),
                            ),
                          ],
                        ),
                        const Divider(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 17),
                            const SizedBox(width: 4),
                            Text(
                              '$_rack - ${ligne.nomEmplacement}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 38, 24, 24),
                      child: Column(
                        children: [
                          _zoneScan(),
                          const SizedBox(height: 25),
                          _affichageQuantite(),
                          const SizedBox(height: 9),
                          _paveNumerique(),
                          if (_erreur != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _erreur!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF8B1515),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _entete() {
    return Container(
      height: 74,
      color: Colors.white,
      padding: const EdgeInsets.only(right: 24),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Sessions', style: TextStyle(fontSize: 8)),
          SizedBox(width: 17),
          Text('Se déconnecter', style: TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  Widget _zoneScan() {
    return Material(
      color: Colors.white,
      elevation: 2,
      child: InkWell(
        onTap: _enregistrement ? null : _ouvrirScanner,
        child: SizedBox(
          height: 145,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _codeBarres == null
                    ? Icons.qr_code_scanner
                    : Icons.check_circle_outline,
                size: 42,
                color: const Color(0xFF8CA6FF),
              ),
              const SizedBox(height: 9),
              Text(
                _codeBarres == null ? 'Cliquez pour scanner' : 'Code scanné',
                style: const TextStyle(color: Color(0xFF8CA6FF), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _affichageQuantite() {
    return Container(
      height: 34,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: Text(
        _quantite.isEmpty ? 'Quantité à prélever' : '$_quantite packs',
        style: TextStyle(
          fontSize: 11,
          color: _quantite.isEmpty ? Colors.grey.shade600 : Colors.black,
        ),
      ),
    );
  }

  Widget _paveNumerique() {
    const touches = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'x'];
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 9,
      crossAxisSpacing: 11,
      childAspectRatio: 2.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final touche in touches)
          Material(
            color: touche == 'x' ? Colors.black : Colors.white,
            child: InkWell(
              onTap: _enregistrement ? null : () => _saisir(touche),
              child: Center(
                child: Text(
                  touche,
                  style: TextStyle(
                    color: touche == 'x' ? Colors.white : Colors.black,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        Material(
          color: const Color(0xFF5369CE),
          child: InkWell(
            onTap: _enregistrement ? null : _confirmer,
            child: Center(
              child: _enregistrement
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white, size: 21),
            ),
          ),
        ),
      ],
    );
  }
}
