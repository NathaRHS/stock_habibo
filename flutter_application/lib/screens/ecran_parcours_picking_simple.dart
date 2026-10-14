import 'package:flutter/material.dart';
import 'package:flutter_application/models/ligne_picking.dart';
import 'package:flutter_application/models/scan_ligne_response.dart';
import 'package:flutter_application/screens/ecran_scan_sortie_maquette.dart';
import 'package:flutter_application/services/picking_service.dart';

/// Version simplifiee de l'ecran "Parcours picking".
///
/// Meme aspect et meme comportement que EcranParcoursPickingMaquette, mais
/// avec peu de widgets : Column, Row, Container, Text et boutons.
/// Pas de Stack, pas de Positioned, pas d'animation.
///
/// La page se lit de haut en bas, dans l'ordre de l'ecran :
///   entete  ->  introduction  ->  parcours  ->  fiche de l'etape choisie
class EcranParcoursPickingSimple extends StatefulWidget {
  const EcranParcoursPickingSimple({
    super.key,
    required this.baseUrl,
    required this.accessToken,
    required this.journalId,
    required this.userId,
    this.rackDepartId = 1,
  });

  // Ce que l'ecran doit connaitre pour commencer.
  final String baseUrl;
  final String accessToken;
  final int journalId;
  final int userId;
  final int rackDepartId;

  @override
  State<EcranParcoursPickingSimple> createState() =>
      _EcranParcoursPickingSimpleState();
}

class _EcranParcoursPickingSimpleState
    extends State<EcranParcoursPickingSimple> {
  // ---------- Les couleurs (les memes que l'ecran d'origine) ----------
  static const _bleu = Color(0xFF5A91D0);
  static const _bleuTexte = Color(0xFF1970DF);
  static const _bleuPale = Color(0xFFE5F0FD);
  static const _texteFonce = Color(0xFF303030);

  // ---------- La memoire de l'ecran ----------
  // Quand une de ces variables change (avec setState), l'ecran se redessine.

  late final PickingService _service;
  List<LignePicking> _etapes = []; // les emplacements a visiter
  int _indexChoisi = 0; // quelle etape est selectionnee
  bool _chargement = true; // vrai pendant l'appel au serveur
  bool _actionEnCours = false; // vrai pendant un scan ou un "aucun produit"
  String? _erreur; // message d'erreur, ou null s'il n'y en a pas

  // ---------- 1. Au demarrage ----------

  @override
  void initState() {
    super.initState();
    _service = PickingService(
      baseUrl: widget.baseUrl,
      accessToken: widget.accessToken,
    );
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      // On reprend le parcours deja commence, sinon on en demande un nouveau.
      var lignes = await _service.chargerParcoursActif(
        journalId: widget.journalId,
      );
      lignes ??= await _service.genererMeilleurParcours(
        journalId: widget.journalId,
        userId: widget.userId,
        rackDepartId: widget.rackDepartId,
      );

      // Si l'utilisateur a quitte l'ecran entre-temps, on ne fait rien.
      if (!mounted) return;

      setState(() {
        _etapes = lignes!;
        _indexChoisi = _prochaineEtape();
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

  // ---------- Petites fonctions utiles ----------

  /// Une etape est terminee quand il n'y a plus rien a faire dessus.
  bool _estTerminee(String statut) =>
      statut == 'PRELEVEE' || statut == 'IMPOSSIBLE' || statut == 'ANNULEE';

  /// Index de la premiere etape pas encore terminee (0 si tout est fini).
  int _prochaineEtape() {
    final index = _etapes.indexWhere((e) => !_estTerminee(e.statut));
    return index >= 0 ? index : 0;
  }

  /// Texte du gros bouton, selon l'etat de l'etape.
  String _texteBouton(String statut) {
    switch (statut) {
      case 'PRELEVEE':
        return 'Prélevé';
      case 'IMPOSSIBLE':
        return 'Aucun produit';
      case 'ANNULEE':
        return 'Annulée';
      default:
        return 'Scanner +';
    }
  }

  String _formaterDate(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year}';
  }

  void _afficherMessage(String texte) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  // ---------- 2. Quand l'operateur appuie sur "Scanner" ----------

  Future<void> _scanner() async {
    final etape = _etapes[_indexChoisi];
    setState(() => _actionEnCours = true);

    // On ouvre l'ecran de scan et on attend qu'il se ferme avec un resultat.
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
      _actionEnCours = false;
      if (resultat?.ligneTerminee == true) {
        // On marque l'etape comme faite, puis on passe a la suivante.
        _etapes[_indexChoisi] = etape.copierAvec(statut: 'PRELEVEE');
        _indexChoisi = _prochaineEtape();
      }
    });

    if (resultat != null) {
      _afficherMessage(
        resultat.ligneTerminee
            ? 'Prélèvement terminé.'
            : '${resultat.quantiteRestante} conditionnement(s) restant(s).',
      );
    }
  }

  // ---------- 3. Quand l'operateur appuie sur "Aucun produit ici" ----------

  Future<void> _declarerAucunProduit() async {
    final etape = _etapes[_indexChoisi];

    // On demande confirmation avant d'agir.
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aucun produit à ${etape.nomEmplacement} ?'),
        content: const Text(
          'Aucune quantité ne sera retirée du stock. Ce qui manque sera repris '
          'dans un nouveau bon quand l’administrateur validera la sortie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aucun produit'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    setState(() => _actionEnCours = true);
    try {
      final resultat = await _service.declarerImpossible(
        lignePickingId: etape.id,
      );
      if (!mounted) return;

      setState(() {
        // Si une partie a deja ete prelevee, la ligne compte comme prelevee.
        final statut = resultat.quantitePreleveeAuTotal > 0
            ? 'PRELEVEE'
            : 'IMPOSSIBLE';
        _etapes[_indexChoisi] = etape.copierAvec(statut: statut);
        _indexChoisi = _prochaineEtape();
      });
      _afficherMessage('Ligne fermée : aucun produit.');
    } catch (erreur) {
      if (!mounted) return;
      _afficherMessage(erreur.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  // ---------- 4. La liste des commandes (fenetre qui s'ouvre en haut) ----------

  void _ouvrirProgression() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.fromLTRB(40, 60, 40, 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(33)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 431),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre + bouton fermer.
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Liste des commandes',
                        style: TextStyle(fontSize: 19),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18),
                      color: _bleuTexte,
                    ),
                  ],
                ),
              ),
              // Une ligne par etape : nom, barre, quantite.
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  children: [
                    for (final etape in _etapes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                              child: LinearProgressIndicator(
                                value: _estTerminee(etape.statut) ? 1 : 0,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xFF3688ED),
                                backgroundColor: const Color(0xFFD7D7D7),
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

  // ---------- 5. Le dessin ----------

  @override
  Widget build(BuildContext context) {
    // Cas 1 : ca charge.
    if (_chargement) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Cas 2 : une erreur est survenue.
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
                  onPressed: _charger,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Cas 3 : le serveur n'a trouve aucun stock.
    if (_etapes.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Rien à prélever',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aucun stock n’est disponible pour ces commandes. '
                  'L’administrateur validera la sortie : le manque sera repris '
                  'dans un nouveau bon.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Cas 4 : le cas normal. On empile les blocs de haut en bas.
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 492),
          child: ColoredBox(
            color: _bleu,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _construireEntete(),
                  _construireIntroduction(),
                  // Le parcours prend la place qui reste ; il defile si besoin.
                  Expanded(
                    child: SingleChildScrollView(child: _construireParcours()),
                  ),
                  _construireFiche(_etapes[_indexChoisi]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Bandeau blanc du haut.
  Widget _construireEntete() {
    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 23, right: 34),
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

  // Bandeau bleu pale avec le titre.
  Widget _construireIntroduction() {
    return Container(
      width: double.infinity,
      height: 180,
      color: _bleuPale,
      padding: const EdgeInsets.only(left: 18, top: 72),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meilleur emplacement',
            style: TextStyle(
              color: _texteFonce,
              fontSize: 30,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Les emplacements sont triés par ordre',
            style: TextStyle(color: _texteFonce, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // Le parcours : des rangees de 5 cases reliees par un trait.
  Widget _construireParcours() {
    // On decoupe la liste des etapes en groupes de 5.
    final rangees = <Widget>[];
    for (var debut = 0; debut < _etapes.length; debut += 5) {
      var fin = debut + 5;
      if (fin > _etapes.length) fin = _etapes.length;
      rangees.add(_construireRangee(debut, fin));
      rangees.add(const SizedBox(height: 38));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(23, 10, 23, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lien vers la liste des commandes.
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _ouvrirProgression,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text(
                'Voir la progression globale',
                style: TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ...rangees,
        ],
      ),
    );
  }

  // Une rangee : case, trait, case, trait, case...
  Widget _construireRangee(int debut, int fin) {
    final elements = <Widget>[];
    for (var index = debut; index < fin; index++) {
      elements.add(_construireCase(index));
      if (index < fin - 1) elements.add(_construireTrait());
    }
    return Row(children: elements);
  }

  // Une case carree : blanche si c'est l'etape choisie.
  Widget _construireCase(int index) {
    final choisie = index == _indexChoisi;

    return SizedBox(
      width: 51,
      height: 51,
      child: Material(
        color: choisie ? Colors.white : Colors.white.withValues(alpha: 0.24),
        child: InkWell(
          onTap: () => setState(() => _indexChoisi = index),
          child: Center(
            child: Text(
              _etapes[index].nomEmplacement,
              style: TextStyle(
                fontSize: 12,
                color: choisie
                    ? _bleuTexte
                    : const Color(0xFF307FC7).withValues(alpha: 0.46),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Le trait entre deux cases, avec un petit rond au milieu.
  Widget _construireTrait() {
    return Expanded(
      child: Row(
        children: [
          Expanded(child: Container(height: 2, color: Colors.white54)),
          Container(
            width: 15,
            height: 15,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E5E5),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Container(height: 2, color: Colors.white54)),
        ],
      ),
    );
  }

  // Le panneau blanc du bas : le detail de l'etape choisie.
  Widget _construireFiche(LignePicking etape) {
    final peutAgir = !_actionEnCours && !_estTerminee(etape.statut);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(34, 24, 34, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Emplacement ${etape.nomEmplacement}',
            style: const TextStyle(
              color: _texteFonce,
              fontSize: 29,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 15),

          // Quantite.
          Row(
            children: [
              const Text('Quantité à prélever :',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(width: 13),
              Text(
                '${etape.quantiteConditionnementsAPrelever} packs',
                style: const TextStyle(color: _bleuTexte, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Emplacement et ordre de passage.
          Row(
            children: [
              const Icon(Icons.push_pin_outlined, color: _bleuTexte, size: 16),
              const SizedBox(width: 7),
              Text(
                etape.nomEmplacement,
                style: const TextStyle(color: _bleuTexte, fontSize: 12),
              ),
              const SizedBox(width: 16),
              Text(
                'Ordre ${etape.ordrePassage}',
                style: const TextStyle(color: _bleuTexte, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Dates limites.
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 26),
              const SizedBox(width: 9),
              Text(
                'DLC : ${_formaterDate(etape.dlc)}\n'
                'DLV : ${_formaterDate(etape.dlv)}',
                style: const TextStyle(fontSize: 12, height: 1.25),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bouton principal : onPressed null = bouton desactive.
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: peutAgir ? _scanner : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF76A9D6),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
              ),
              child: Text(
                _texteBouton(etape.statut),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // Lien secondaire, seulement tant que l'etape attend l'operateur.
          if (!_estTerminee(etape.statut)) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: peutAgir ? _declarerAucunProduit : null,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B6B6B),
                ),
                child: const Text(
                  'Aucun produit ici',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
