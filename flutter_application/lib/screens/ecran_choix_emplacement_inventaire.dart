import 'package:flutter/material.dart';
import 'package:flutter_application/models/comptage_inventaire.dart';
import 'package:flutter_application/screens/ecran_scan_session.dart';
import 'package:flutter_application/services/scan_service.dart';

class EcranChoixEmplacementInventaire extends StatefulWidget {
  const EcranChoixEmplacementInventaire({
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
  State<EcranChoixEmplacementInventaire> createState() =>
      _EcranChoixEmplacementInventaireState();
}

class _EcranChoixEmplacementInventaireState
    extends State<EcranChoixEmplacementInventaire> {
  static const _bleuNuit = Color(0xFF0B1F38);
  static const _bleuPrincipal = Color(0xFF97B1E4);
  static const _texte = Color(0xFF10243E);
  static const _texteSecondaire = Color(0xFF687991);

  final _rechercheController = TextEditingController();
  late final ScanService _scanService;

  List<EmplacementInventaire> _emplacements = [];
  List<StockInventaire> _stocks = [];
  Map<int, String> _nomsArticles = {};
  final Set<int> _emplacementsComptes = {};

  int? _emplacementSelectionneId;
  bool _chargement = true;
  bool _actionEnCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _scanService = ScanService(
      baseUrl: widget.baseUrl,
      accessToken: widget.accessToken,
    );
    _chargerDonnees();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final resultats = await Future.wait([
        _scanService.chargerEmplacements(),
        _scanService.chargerStocksParEmplacement(),
        _scanService.chargerArticles(),
      ]);

      if (!mounted) return;
      final emplacements = resultats[0] as List<EmplacementInventaire>;
      final articles = resultats[2] as List<ArticleInventaire>;
      setState(() {
        _emplacements = emplacements;
        _stocks = resultats[1] as List<StockInventaire>;
        _nomsArticles = {
          for (final article in articles) article.id: article.nomArticle,
        };
        if (emplacements.isNotEmpty) {
          _emplacementSelectionneId = emplacements.first.id;
        }
      });
    } on ScanException catch (erreur) {
      if (mounted) setState(() => _erreur = erreur.message);
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = 'Impossible de charger les emplacements.');
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _continuer() async {
    final emplacement = _emplacementSelectionne();
    if (emplacement == null) return;

    final stock = _stockEmplacement(emplacement.id);
    final comptageEnregistre = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EcranScanSession(
          journalId: widget.journalId,
          referenceJournal: widget.referenceJournal,
          typeJournal: 'INVENTAIRE',
          baseUrl: widget.baseUrl,
          accessToken: widget.accessToken,
          emplacementId: emplacement.id,
          nomEmplacement: emplacement.nomEmplacement,
          nomRack: emplacement.nomRack,
          numeroEtage: emplacement.numeroEtage,
          nomArticleAttendu: stock == null
              ? null
              : _nomsArticles[stock.articleId],
          quantiteStockAttendue: stock?.quantiteStock,
        ),
      ),
    );

    if (!mounted || comptageEnregistre != true) return;
    setState(() => _emplacementsComptes.add(emplacement.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Comptage enregistré pour ${emplacement.nomEmplacement}.',
        ),
      ),
    );
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
      _actionEnCours = true;
      _erreur = null;
    });
    try {
      await _scanService.terminerParticipation(journalId: widget.journalId);
      if (mounted) Navigator.pop(context);
    } on ScanException catch (erreur) {
      if (mounted) setState(() => _erreur = erreur.message);
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = 'Impossible de joindre le serveur.');
      }
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        toolbarHeight: 74,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INVENTAIRE EN COURS',
              style: TextStyle(
                color: Color(0xFFA9C7EB),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Choisir un emplacement',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              widget.referenceJournal,
              style: const TextStyle(
                color: Color(0xFFBCD4F1),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: _construireCorps(),
      bottomNavigationBar: _chargement || _emplacements.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFDCE4EE))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _actionEnCours ? null : _continuer,
                        style: FilledButton.styleFrom(
                          backgroundColor: _bleuPrincipal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Continuer avec ${_emplacementSelectionne()?.nomEmplacement ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _actionEnCours ? null : _terminerParticipation,
                      child: const Text('J’ai terminé ma partie'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _construireCorps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erreur != null && _emplacements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_erreur!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _chargerDonnees,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final recherche = _rechercheController.text.trim().toLowerCase();
    final filtres = _emplacements.where((emplacement) {
      final stock = _stockEmplacement(emplacement.id);
      final article = stock == null
          ? ''
          : (_nomsArticles[stock.articleId] ?? '');
      return emplacement.nomEmplacement.toLowerCase().contains(recherche) ||
          emplacement.nomRack.toLowerCase().contains(recherche) ||
          article.toLowerCase().contains(recherche);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _resumeSelection(),
          const SizedBox(height: 20),
          TextField(
            controller: _rechercheController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher un emplacement',
              suffixIcon: const Icon(Icons.search, color: Color(0xFF8291A6)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFDCE4EE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFDCE4EE)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _emplacementSelectionne()?.nomRack.toUpperCase() ??
                    'EMPLACEMENTS',
                style: const TextStyle(
                  color: _texte,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${filtres.length} emplacements',
                style: const TextStyle(color: _texteSecondaire, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtres.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) => _carteEmplacement(filtres[index]),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 14),
            Text(_erreur!, style: const TextStyle(color: Color(0xFFCA4453))),
          ],
          const SizedBox(height: 16),
          const Wrap(
            spacing: 15,
            runSpacing: 8,
            children: [
              _Legende(couleur: _bleuPrincipal, texte: 'Sélectionné'),
              _Legende(couleur: Color(0xFF138A61), texte: 'Déjà compté'),
              _Legende(couleur: Color(0xFFB9C5D4), texte: 'À compter'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumeSelection() {
    final emplacement = _emplacementSelectionne();
    final stock = emplacement == null
        ? null
        : _stockEmplacement(emplacement.id);
    final nomArticle = emplacement == null
        ? 'Aucun emplacement sélectionné'
        : stock == null
        ? 'Emplacement libre'
        : (_nomsArticles[stock.articleId] ?? 'Article inconnu');

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFEDF4FF)],
        ),
        border: Border.all(color: const Color(0xFFBAD1FB)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14215EEF),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 70, minHeight: 58),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _bleuPrincipal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              emplacement?.nomEmplacement ?? '--',
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
                  nomArticle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  emplacement == null
                      ? 'Choisissez une case dans la grille'
                      : stock == null
                      ? '${emplacement.nomRack} · Niveau ${emplacement.numeroEtage} · Libre'
                      : 'Stock attendu : ${stock.quantiteStock} pièces · ${emplacement.nomRack} · Niveau ${emplacement.numeroEtage}',
                  style: const TextStyle(
                    color: _texteSecondaire,
                    fontSize: 12,
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

  Widget _carteEmplacement(EmplacementInventaire emplacement) {
    final stock = _stockEmplacement(emplacement.id);
    final selectionne = emplacement.id == _emplacementSelectionneId;
    final dejaCompte = _emplacementsComptes.contains(emplacement.id);
    final article = stock == null
        ? 'Libre'
        : (_nomsArticles[stock.articleId] ?? 'Occupé');

    return Material(
      color: selectionne ? const Color(0xFFEDF4FF) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: selectionne ? 3 : 1,
      shadowColor: const Color(0x24000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _emplacementSelectionneId = emplacement.id),
        child: Container(
          padding: EdgeInsets.all(selectionne ? 8 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selectionne
                ? Border.all(color: _bleuPrincipal, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emplacement.nomEmplacement,
                style: const TextStyle(
                  color: _texte,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Text(
                  article,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _texteSecondaire,
                    fontSize: 9.5,
                    height: 1.25,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectionne
                        ? _bleuPrincipal
                        : dejaCompte
                        ? const Color(0xFF138A61)
                        : const Color(0xFFB9C5D4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  EmplacementInventaire? _emplacementSelectionne() {
    for (final emplacement in _emplacements) {
      if (emplacement.id == _emplacementSelectionneId) return emplacement;
    }
    return null;
  }

  StockInventaire? _stockEmplacement(int emplacementId) {
    for (final stock in _stocks) {
      if (stock.emplacementId == emplacementId && stock.quantiteStock > 0) {
        return stock;
      }
    }
    return null;
  }
}

class _Legende extends StatelessWidget {
  const _Legende({required this.couleur, required this.texte});

  final Color couleur;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          texte,
          style: const TextStyle(color: Color(0xFF687991), fontSize: 10),
        ),
      ],
    );
  }
}
