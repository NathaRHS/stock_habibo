import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/models/detail_journal.dart';
import 'package:flutter_application/screens/ecran_scanner_code_barres.dart';
import 'package:flutter_application/services/scan_service.dart';

class EcranScanSession extends StatefulWidget {
  const EcranScanSession({
    super.key,
    required this.journalId,
    required this.referenceJournal,
    required this.baseUrl,
    required this.accessToken,
  });

  final int journalId;
  final String referenceJournal;
  final String baseUrl;
  final String accessToken;

  @override
  State<EcranScanSession> createState() => _EcranScanSessionState();
}

class _EcranScanSessionState extends State<EcranScanSession> {
  final _formKey = GlobalKey<FormState>();
  final _codeBarresController = TextEditingController();
  final _nomArticleController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _quantiteFocusNode = FocusNode();
  late final ScanService _scanService;

  bool _enregistrementEnCours = false;
  String? _erreur;
  DetailJournal? _dernierDetail;

  @override
  void initState() {
    super.initState();
    _scanService = ScanService(
      baseUrl: widget.baseUrl,
      accessToken: widget.accessToken,
    );
  }

  @override
  void dispose() {
    _codeBarresController.dispose();
    _nomArticleController.dispose();
    _quantiteController.dispose();
    _quantiteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _ouvrirScanner() async {
    final codeBarres = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const EcranScannerCodeBarres()),
    );

    if (!mounted || codeBarres == null) return;
    setState(() {
      _codeBarresController.text = codeBarres;
      _erreur = null;
    });
    _quantiteFocusNode.requestFocus();
  }

  Future<void> _ajouterProduit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enregistrementEnCours = true;
      _erreur = null;
    });

    try {
      final detail = await _scanService.enregistrerScan(
        journalId: widget.journalId,
        codeBarres: _codeBarresController.text.trim(),
        quantite: int.parse(_quantiteController.text.trim()),
      );

      if (!mounted) return;
      setState(() {
        _dernierDetail = detail;
        _nomArticleController.text = detail.nomArticle;
        _codeBarresController.clear();
        _quantiteController.clear();
      });
    } on ScanException catch (erreur) {
      if (mounted) setState(() => _erreur = erreur.message);
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = 'Impossible de joindre le serveur.');
      }
    } finally {
      if (mounted) setState(() => _enregistrementEnCours = false);
    }
  }

  Future<void> _soumettreSession() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer le comptage ?'),
        content: const Text(
          'La session sera envoyée au responsable et ne pourra plus recevoir de scans.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );

    if (confirmation != true || !mounted) return;
    setState(() {
      _enregistrementEnCours = true;
      _erreur = null;
    });

    try {
      await _scanService.soumettreSession(journalId: widget.journalId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session envoyée au responsable.')),
      );
      Navigator.pop(context);
    } on ScanException catch (erreur) {
      if (mounted) setState(() => _erreur = erreur.message);
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = 'Impossible de joindre le serveur.');
      }
    } finally {
      if (mounted) setState(() => _enregistrementEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        title: const Text('Enregistrer un produit'),
        backgroundColor: const Color(0xFF063D77),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _enteteSession(),
                    const SizedBox(height: 22),
                    _champCodeBarres(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomArticleController,
                      readOnly: true,
                      decoration: _decorationChamp(
                        label: 'Produit reconnu',
                        hint: 'Le produit apparaîtra après l’ajout',
                        icon: Icons.local_drink_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantiteController,
                      focusNode: _quantiteFocusNode,
                      enabled: !_enregistrementEnCours,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _ajouterProduit(),
                      decoration: _decorationChamp(
                        label: 'Quantité réelle',
                        hint: 'Ex. 200',
                        icon: Icons.inventory_2_outlined,
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
                      _messageErreur(),
                    ],
                    if (_dernierDetail != null) ...[
                      const SizedBox(height: 16),
                      _confirmation(_dernierDetail!),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _enregistrementEnCours
                            ? null
                            : _ajouterProduit,
                        icon: _enregistrementEnCours
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(
                          _enregistrementEnCours
                              ? 'Enregistrement…'
                              : 'Ajouter le produit',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0752A7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _enregistrementEnCours
                          ? null
                          : _soumettreSession,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Terminer le comptage'),
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

  Widget _enteteSession() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF063D77),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SESSION ACTIVE',
            style: TextStyle(
              color: Color(0xFFB9D8F5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.referenceJournal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _champCodeBarres() {
    return TextFormField(
      controller: _codeBarresController,
      enabled: !_enregistrementEnCours,
      autofocus: true,
      textInputAction: TextInputAction.next,
      decoration: _decorationChamp(
        label: 'Code-barres',
        hint: 'Scannez ou saisissez le code',
        icon: Icons.qr_code_scanner,
        suffixIcon: IconButton(
          tooltip: 'Ouvrir la caméra',
          onPressed: _enregistrementEnCours ? null : _ouvrirScanner,
          icon: const Icon(Icons.qr_code_scanner),
        ),
      ),
      validator: (valeur) => valeur == null || valeur.trim().isEmpty
          ? 'Le code-barres est obligatoire.'
          : null,
    );
  }

  InputDecoration _decorationChamp({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon ?? Icon(icon, color: const Color(0xFF71808F)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD6DEE6)),
      ),
    );
  }

  Widget _messageErreur() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        border: Border.all(color: const Color(0xFFF0B5B5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(_erreur!, style: const TextStyle(color: Color(0xFF8E2525))),
    );
  }

  Widget _confirmation(DetailJournal detail) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        border: Border.all(color: const Color(0xFFA8D8BE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF1F8050)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${detail.nomArticle} — quantité totale : ${detail.quantite}',
              style: const TextStyle(
                color: Color(0xFF175F3D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
