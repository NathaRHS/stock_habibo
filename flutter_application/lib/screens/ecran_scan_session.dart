import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/models/detail_journal.dart';
import 'package:flutter_application/screens/ecran_scanner_code_barres.dart';
import 'package:flutter_application/services/scan_service.dart';
import 'package:flutter_application/theme/habibo.dart';
import 'package:flutter_application/widgets/en_tete_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  final _codeBarresController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _quantiteFocusNode = FocusNode();
  late final ScanService _scanService;

  DateTime? _dlv;
  DateTime? _dlc;

  bool _enregistrementEnCours = false;
  String? _erreur;
  String? _erreurCodeBarres;
  String? _erreurDates;
  String? _erreurQuantite;
  DetailJournal? _dernierDetail;

  // Produits du journal (réception uniquement).
  List<DetailJournal> _details = [];
  bool _chargementDetails = false;
  String? _erreurDetails;

  bool get _estInventaire =>
      widget.typeJournal.trim().toUpperCase() == 'INVENTAIRE';

  @override
  void initState() {
    super.initState();
    _scanService = ScanService(
      baseUrl: widget.baseUrl,
      accessToken: widget.accessToken,
    );
    if (!_estInventaire) _chargerDetails();
  }

  @override
  void dispose() {
    _codeBarresController.dispose();
    _quantiteController.dispose();
    _quantiteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _chargerDetails() async {
    setState(() {
      _chargementDetails = true;
      _erreurDetails = null;
    });

    try {
      final details = await _scanService.chargerDetails(
        journalId: widget.journalId,
      );
      if (!mounted) return;
      setState(() => _details = details.reversed.toList());
    } on ScanException catch (erreur) {
      if (mounted) setState(() => _erreurDetails = erreur.message);
    } catch (_) {
      if (mounted) {
        setState(() => _erreurDetails = 'Impossible de charger les produits.');
      }
    } finally {
      if (mounted) setState(() => _chargementDetails = false);
    }
  }

  Future<void> _ouvrirScanner() async {
    final codeBarres = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const EcranScannerCodeBarres()),
    );

    if (!mounted || codeBarres == null) return;
    setState(() {
      _codeBarresController.text = codeBarres;
      _erreurCodeBarres = null;
      _erreur = null;
    });
    _quantiteFocusNode.requestFocus();
  }

  Future<void> _choisirDate({required bool dlc}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: (dlc ? _dlc : _dlv) ?? DateTime.now(),
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

  void _changerQuantite(int ecart) {
    final actuelle = int.tryParse(_quantiteController.text.trim()) ?? 0;
    final nouvelle = actuelle + ecart < 1 ? 1 : actuelle + ecart;
    setState(() {
      _quantiteController.text = '$nouvelle';
      _erreurQuantite = null;
    });
  }

  bool _valider() {
    final quantite = int.tryParse(_quantiteController.text.trim());
    String? erreurDates;
    if (!_estInventaire) {
      if (_dlv == null || _dlc == null) {
        erreurDates = 'Renseignez la DLV et la DLC.';
      } else if (_dlv!.isAfter(_dlc!)) {
        erreurDates = 'La DLV ne peut pas dépasser la DLC.';
      }
    }

    setState(() {
      _erreurCodeBarres = _codeBarresController.text.trim().isEmpty
          ? 'Scannez ou saisissez un code-barres.'
          : null;
      _erreurDates = erreurDates;
      _erreurQuantite = quantite == null || quantite <= 0
          ? 'Saisissez une quantité strictement positive.'
          : null;
    });

    return _erreurCodeBarres == null &&
        _erreurDates == null &&
        _erreurQuantite == null;
  }

  Future<void> _ajouterProduit() async {
    if (_estInventaire && widget.emplacementId == null) {
      setState(() => _erreur = 'Aucun emplacement n’a été sélectionné.');
      return;
    }
    if (!_valider()) return;

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
        dlc: _formaterIso(_dlc!),
        dlv: _formaterIso(_dlv!),
      );

      if (!mounted) return;
      setState(() {
        _dernierDetail = detail;
        // Le produit ajouté remonte en tête de liste.
        _details = [
          detail,
          ..._details.where((element) => element.id != detail.id),
        ];
        _codeBarresController.clear();
        _quantiteController.clear();
        _dlc = null;
        _dlv = null;
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
            style: FilledButton.styleFrom(backgroundColor: Habibo.bleu),
            child: const Text('Terminer'),
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

  String _formaterIso(DateTime date) {
    final mois = date.month.toString().padLeft(2, '0');
    final jour = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mois-$jour';
  }

  String _formaterFr(DateTime date) {
    final mois = date.month.toString().padLeft(2, '0');
    final jour = date.day.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year}';
  }

  /// "2027-03-29" devient "29/03/2027" ; toute autre forme est laissée telle quelle.
  String _isoVersFr(String iso) {
    final morceaux = iso.split('-');
    if (morceaux.length != 3) return iso;
    return '${morceaux[2]}/${morceaux[1]}/${morceaux[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Habibo.fond,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  EnTetePage(
                    titre: _estInventaire ? 'Comptage' : 'Réception',
                    sousTitre: widget.referenceJournal,
                    action: _estInventaire
                        ? null
                        : TextButton(
                            onPressed: _enregistrementEnCours
                                ? null
                                : _terminerParticipation,
                            style: TextButton.styleFrom(
                              foregroundColor: Habibo.bleu,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: const Size(0, 44),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            // Le style est sur le texte : il garde la police du thème.
                            child: const Text(
                              'Terminer',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
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
                        if (_estInventaire) ...[
                          _resumeEmplacementInventaire(),
                          const SizedBox(height: 24),
                        ],
                        _libelle('Code-barres'),
                        _champCodeBarres(),
                        _texteErreur(_erreurCodeBarres),
                        if (!_estInventaire) ...[
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
                        ],
                        const SizedBox(height: 20),
                        _libelle(
                          _estInventaire
                              ? 'Quantité comptée'
                              : 'Quantité reçue',
                        ),
                        _selecteurQuantite(),
                        _texteErreur(_erreurQuantite),
                        if (_erreur != null) ...[
                          const SizedBox(height: 16),
                          _message(
                            _erreur!,
                            icone: LucideIcons.circleAlert,
                            couleur: Habibo.rouge,
                            fond: Habibo.rougeDoux,
                          ),
                        ],
                        if (_dernierDetail != null) ...[
                          const SizedBox(height: 16),
                          _message(
                            '${_dernierDetail!.nomArticle} ajouté · total '
                            '${_dernierDetail!.quantite}',
                            icone: LucideIcons.circleCheck,
                            couleur: Habibo.vert,
                            fond: Habibo.vertDoux,
                          ),
                        ],
                        if (!_estInventaire) ...[
                          const SizedBox(height: 32),
                          _produitsDuJournal(),
                        ],
                      ],
                    ),
                  ),
                  _barreAction(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _barreAction() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Habibo.marge, 8, Habibo.marge, 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: _enregistrementEnCours ? null : _ajouterProduit,
          style: FilledButton.styleFrom(
            backgroundColor: Habibo.bleu,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Habibo.bleu.withValues(alpha: 0.6),
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Habibo.rayon),
            ),
          ),
          child: _enregistrementEnCours
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _estInventaire
                      ? 'Enregistrer le comptage'
                      : 'Ajouter le produit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
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

  OutlineInputBorder _bordure(Color couleur, {double epaisseur = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Habibo.rayon),
      borderSide: BorderSide(color: couleur, width: epaisseur),
    );
  }

  Widget _champCodeBarres() {
    final enErreur = _erreurCodeBarres != null;

    return TextField(
      controller: _codeBarresController,
      enabled: !_enregistrementEnCours,
      textInputAction: TextInputAction.next,
      onChanged: (_) {
        if (_erreurCodeBarres != null) setState(() => _erreurCodeBarres = null);
      },
      onSubmitted: (_) => _quantiteFocusNode.requestFocus(),
      style: const TextStyle(color: Habibo.texte, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Scannez ou saisissez le code',
        hintStyle: const TextStyle(color: Habibo.texteDiscret),
        filled: true,
        fillColor: Habibo.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        suffixIcon: IconButton(
          tooltip: 'Ouvrir la caméra',
          onPressed: _enregistrementEnCours ? null : _ouvrirScanner,
          icon: const Icon(
            LucideIcons.scanBarcode,
            size: 22,
            color: Habibo.bleu,
          ),
        ),
        enabledBorder: _bordure(enErreur ? Habibo.rouge : Habibo.bordure),
        disabledBorder: _bordure(Habibo.bordure),
        focusedBorder: _bordure(
          enErreur ? Habibo.rouge : Habibo.bleu,
          epaisseur: 1.5,
        ),
      ),
    );
  }

  Widget _champDate({
    required String libelle,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final enErreur = _erreurDates != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _libelle(libelle),
        Material(
          color: Habibo.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Habibo.rayon),
            side: BorderSide(color: enErreur ? Habibo.rouge : Habibo.bordure),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _enregistrementEnCours ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      date == null ? 'JJ/MM/AAAA' : _formaterFr(date),
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

  Widget _selecteurQuantite() {
    final quantite = int.tryParse(_quantiteController.text.trim()) ?? 0;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Habibo.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _erreurQuantite != null ? Habibo.rouge : Habibo.bordure,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _boutonQuantite(
            icone: LucideIcons.minus,
            libelle: 'Diminuer',
            onTap: quantite > 1 ? () => _changerQuantite(-1) : null,
          ),
          Container(width: 1, color: Habibo.bordure),
          Expanded(
            child: TextField(
              controller: _quantiteController,
              focusNode: _quantiteFocusNode,
              enabled: !_enregistrementEnCours,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _erreurQuantite = null),
              onSubmitted: (_) => _ajouterProduit(),
              style: const TextStyle(
                color: Habibo.texte,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Habibo.texteDiscret),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          Container(width: 1, color: Habibo.bordure),
          _boutonQuantite(
            icone: LucideIcons.plus,
            libelle: 'Augmenter',
            onTap: () => _changerQuantite(1),
          ),
        ],
      ),
    );
  }

  Widget _boutonQuantite({
    required IconData icone,
    required String libelle,
    required VoidCallback? onTap,
  }) {
    final actif = onTap != null && !_enregistrementEnCours;

    return InkWell(
      onTap: actif ? onTap : null,
      child: SizedBox(
        width: 72,
        height: double.infinity,
        child: Icon(
          icone,
          size: 22,
          color: actif ? Habibo.texte : Habibo.texteDiscret,
          semanticLabel: libelle,
        ),
      ),
    );
  }

  Widget _message(
    String texte, {
    required IconData icone,
    required Color couleur,
    required Color fond,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: TextStyle(
                color: couleur,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _produitsDuJournal() {
    final nombre = _details.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Dans ce journal',
                style: TextStyle(
                  color: Habibo.texte,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (nombre > 0)
              Text(
                '$nombre produit${nombre > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Habibo.texteSecondaire,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_chargementDetails && _details.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: Habibo.bleu)),
          )
        else if (_erreurDetails != null && _details.isEmpty)
          Text(
            _erreurDetails!,
            style: const TextStyle(color: Habibo.rouge, fontSize: 14),
          )
        else if (_details.isEmpty)
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
            child: Column(
              children: [
                for (var i = 0; i < _details.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color.fromARGB(44, 232, 223, 223),
                    ),
                  _ligneProduit(_details[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _ligneProduit(DetailJournal detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.nomArticle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Habibo.texte,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (detail.dlc != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'DLC ${_isoVersFr(detail.dlc!)}',
                    style: const TextStyle(
                      color: Habibo.texteSecondaire,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '× ${detail.quantite}',
            style: const TextStyle(
              color: Habibo.texte,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumeEmplacementInventaire() {
    final article = widget.nomArticleAttendu ?? 'Emplacement libre';
    final stock = widget.quantiteStockAttendue == null
        ? 'Aucun stock théorique'
        : 'Stock attendu : ${widget.quantiteStockAttendue} pièces';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Habibo.surface,
        border: Border.all(color: Habibo.bordure),
        borderRadius: BorderRadius.circular(Habibo.rayonCarte),
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 64),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Habibo.bleuDoux,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              widget.nomEmplacement ?? '--',
              style: const TextStyle(
                color: Habibo.bleu,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article,
                  style: const TextStyle(
                    color: Habibo.texte,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  // Deux lignes : le nom du rack n'est jamais coupé en deux.
                  '$stock\n${widget.nomRack ?? ''} · Niveau ${widget.numeroEtage ?? '-'}',
                  style: const TextStyle(
                    color: Habibo.texteSecondaire,
                    fontSize: 13,
                    height: 1.4,
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
