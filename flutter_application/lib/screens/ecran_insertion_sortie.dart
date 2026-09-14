import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/screens/ecran_scanner_code_barres.dart';

class EcranInsertionSortie extends StatefulWidget {
  const EcranInsertionSortie({
    super.key,
    required this.baseUrl,
    required this.idEmplacement,
    required this.idCommande,
    required this.journalId,
    required this.articleId,
    required this.nomArticle,
    required this.nomRack,
    required this.nomEmplacement,
    required this.quantiteMaximale,
    required this.dlc,
  });

  final String baseUrl;
  final int idEmplacement;
  final int idCommande;
  final int journalId;
  final int articleId;
  final String nomArticle;
  final String nomRack;
  final String nomEmplacement;
  final int quantiteMaximale;
  final DateTime dlc;

  @override
  State<EcranInsertionSortie> createState() => _EcranInsertionSortieState();
}

class _EcranInsertionSortieState extends State<EcranInsertionSortie> {
  final _formKey = GlobalKey<FormState>();
  final _codeBarresController = TextEditingController();
  final _quantiteController = TextEditingController(text: '1');
  final _quantiteFocusNode = FocusNode();

  String? _erreur;

  @override
  void dispose() {
    _codeBarresController.dispose();
    _quantiteController.dispose();
    _quantiteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _ouvrirScanner() async {
    final codeBarres = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const EcranScannerCodeBarres(),
      ),
    );

    if (!mounted || codeBarres == null) return;

    setState(() {
      _codeBarresController.text = codeBarres;
      _erreur = null;
    });
    _quantiteFocusNode.requestFocus();
  }

  void _verifierPrelevement() {
    if (!_formKey.currentState!.validate()) return;

    final quantite = int.parse(_quantiteController.text.trim());

    if (quantite > widget.quantiteMaximale) {
      setState(() {
        _erreur =
            'Vous pouvez prélever au maximum ${widget.quantiteMaximale} conditionnements depuis cet emplacement.';
      });
      return;
    }

    setState(() => _erreur = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$quantite conditionnement(s) prêts à être enregistrés depuis ${widget.nomEmplacement}.',
        ),
      ),
    );
  }

  String get _dlcFormatee {
    final jour = widget.dlc.day.toString().padLeft(2, '0');
    final mois = widget.dlc.month.toString().padLeft(2, '0');
    return '$jour/$mois/${widget.dlc.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        title: const Text('Prélever une commande'),
        backgroundColor: const Color(0xFF063D77),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _resumePrelevement(),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _codeBarresController,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Code-barres du conditionnement',
                        hintText: 'Scannez ou saisissez le code',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.qr_code_scanner),
                        suffixIcon: IconButton(
                          tooltip: 'Ouvrir la caméra',
                          onPressed: _ouvrirScanner,
                          icon: const Icon(Icons.camera_alt_outlined),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (valeur) {
                        if (valeur == null || valeur.trim().isEmpty) {
                          return 'Le code-barres est obligatoire.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantiteController,
                      focusNode: _quantiteFocusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _verifierPrelevement(),
                      decoration: InputDecoration(
                        labelText: 'Quantité à prélever',
                        helperText:
                            'Maximum : ${widget.quantiteMaximale} conditionnements',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (valeur) {
                        final quantite = int.tryParse(valeur?.trim() ?? '');
                        if (quantite == null || quantite <= 0) {
                          return 'Saisissez une quantité strictement positive.';
                        }
                        return null;
                      },
                    ),
                    if (_erreur != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFF0B5B5),
                          ),
                        ),
                        child: Text(
                          _erreur!,
                          style: const TextStyle(color: Color(0xFF8E2525)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _verifierPrelevement,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Vérifier le prélèvement'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0752A7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumePrelevement() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF063D77),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRÉLÈVEMENT À EFFECTUER',
            style: TextStyle(
              color: Color(0xFFB9D8F5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.nomArticle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '${widget.nomRack} · ${widget.nomEmplacement}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'DLC $_dlcFormatee',
                  style: const TextStyle(
                    color: Color(0xFFD9EBFF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
