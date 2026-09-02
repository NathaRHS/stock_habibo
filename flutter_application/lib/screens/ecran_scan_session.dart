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
    required this.typeJournal,
    required this.baseUrl,
    required this.accessToken,
    this.emplacementId,
    this.nomEmplacement,
    this.nomRack,
    this.numeroEtage,
    this.nomArticleAttendu,
    this.quantiteStockAttendue,
  });

  final int journalId;
  final String referenceJournal;
  final String typeJournal;
  final String baseUrl;
  final String accessToken;
  final int? emplacementId;
  final String? nomEmplacement;
  final String? nomRack;
  final int? numeroEtage;
  final String? nomArticleAttendu;
  final int? quantiteStockAttendue;

  @override
  State<EcranScanSession> createState() => _EcranScanSessionState();
}

class _EcranScanSessionState extends State<EcranScanSession> {
  final _formKey = GlobalKey<FormState>();
  final _codeBarresController = TextEditingController();
  final _nomArticleController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _dlcController = TextEditingController();
  final _dlvController = TextEditingController();
  final _quantiteFocusNode = FocusNode();
  late final ScanService _scanService;

  bool _enregistrementEnCours = false;
  String? _erreur;
  DetailJournal? _dernierDetail;

  bool get _estInventaire =>
      widget.typeJournal.trim().toUpperCase() == 'INVENTAIRE';

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
    _dlcController.dispose();
    _dlvController.dispose();
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
    if (_estInventaire && widget.emplacementId == null) {
      setState(() => _erreur = 'Aucun emplacement n’a été sélectionné.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enregistrementEnCours = true;
      _erreur = null;
    });

    try {
      if (_estInventaire) {
        await _scanService.enregistrerScanInventaire(
          journalId: widget.journalId,
          emplacementId: widget.emplacementId!,
          codeBarres: _codeBarresController.text.trim(),
          quantite: int.parse(_quantiteController.text.trim()),
        );

        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      final detail = await _scanService.enregistrerScan(
        journalId: widget.journalId,
        codeBarres: _codeBarresController.text.trim(),
        quantite: int.parse(_quantiteController.text.trim()),
        dlc: _dlcController.text,
        dlv: _dlvController.text,
      );

      if (!mounted) return;
      setState(() {
        _dernierDetail = detail;
        _nomArticleController.text = detail.nomArticle;
        _codeBarresController.clear();
        _quantiteController.clear();
        _dlcController.clear();
        _dlvController.clear();
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

  Future<void> _terminerParticipation() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer votre partie ?'),
        content: const Text(
          'Vous ne pourrez plus scanner dans cette session. Elle restera ouverte si un autre opérateur travaille encore.',
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
      await _scanService.terminerParticipation(journalId: widget.journalId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre participation est terminée.')),
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
        title: Text(
          _estInventaire
              ? 'Compter dans ${widget.nomEmplacement ?? ''}'
              : 'Enregistrer un produit',
        ),
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
                    if (_estInventaire) ...[
                      _resumeEmplacementInventaire(),
                      const SizedBox(height: 16),
                    ],
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
                    if (!_estInventaire) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _champDate(
                              controller: _dlvController,
                              label: 'DLV',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _champDate(
                              controller: _dlcController,
                              label: 'DLC',
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    if (!_estInventaire) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _enregistrementEnCours
                            ? null
                            : _terminerParticipation,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('J’ai terminé ma partie'),
                      ),
                    ],
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

  Widget _champDate({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: !_enregistrementEnCours,
      decoration: _decorationChamp(
        label: label,
        hint: 'AAAA-MM-JJ',
        icon: Icons.calendar_today_outlined,
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          controller.text = _formaterDate(date);
        }
      },
      validator: (valeur) {
        if (!_estInventaire && (valeur == null || valeur.isEmpty)) {
          return '$label obligatoire';
        }
        return null;
      },
    );
  }

  String _formaterDate(DateTime date) {
    final mois = date.month.toString().padLeft(2, '0');
    final jour = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mois-$jour';
  }

  Widget _resumeEmplacementInventaire() {
    final article = widget.nomArticleAttendu ?? 'Emplacement libre';
    final stock = widget.quantiteStockAttendue == null
        ? 'Aucun stock théorique'
        : 'Stock attendu : ${widget.quantiteStockAttendue} pièces';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4FF),
        border: Border.all(color: const Color(0xFFBAD1FB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF97B1E4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.nomEmplacement ?? '--',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article,
                  style: const TextStyle(
                    color: Color(0xFF10243E),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$stock · ${widget.nomRack ?? ''} · Niveau ${widget.numeroEtage ?? '-'}',
                  style: const TextStyle(
                    color: Color(0xFF687991),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
