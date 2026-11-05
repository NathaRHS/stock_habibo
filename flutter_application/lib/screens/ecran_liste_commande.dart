import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/models/commande.dart';
import 'package:flutter_application/models/meilleur_emplacement.dart';
import 'package:flutter_application/screens/ecran_insertion_sortie.dart';
import 'package:flutter_application/screens/ecran_parcours_picking_maquette.dart';
import 'package:flutter_application/theme/habibo.dart';
import 'package:flutter_application/widgets/bouton_profil.dart';
import 'package:flutter_application/widgets/bouton_retour.dart';
import 'package:flutter_application/widgets/filtres_pastilles.dart';
import 'package:flutter_application/widgets/fond_degrade.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EcranListeCommande extends StatefulWidget {
  const EcranListeCommande({
    super.key,
    required this.journalId,
    required this.baseUrl,
    required this.accessToken,
    required this.userId,
  });
  final int journalId;
  final String baseUrl;
  final String accessToken;
  final int userId;

  @override
  State<EcranListeCommande> createState() => EcranListeCommandeState();
}

class EcranListeCommandeState extends State<EcranListeCommande> {
  /// Au-delà de cette quantité, une commande est « grosse ».
  static const _seuilGrosseCommande = 10;

  List<Commande> _commandes = [];
  String? _erreur;
  bool _chargement = true;
  bool _grossesSeulement = false;

  /// Commande dont on cherche les emplacements (le bouton affiche un chargement).
  int? _commandeEnChargement;

  @override
  void initState() {
    super.initState();
    _chargerCommandes();
  }

  Future<void> _chargerCommandes() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final uri = Uri.parse('${widget.baseUrl}/commande/${widget.journalId}');
      final response = await http.get(
        uri,
        headers: {
          'accept': "application/json",
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Impossible de charger les commandes (${response.statusCode})',
        );
      }
      final donnees = jsonDecode(utf8.decode(response.bodyBytes));

      if (donnees is! Map<String, dynamic>) {
        throw const FormatException('Réponse inattendue du serveur');
      }

      final listeCommandes = donnees['commandes'];

      if (listeCommandes is! List) {
        throw const FormatException('Liste des commandes absente');
      }

      final commandes = listeCommandes
          .map(
            (commande) => Commande.fromJson(commande as Map<String, dynamic>),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _commandes = commandes;
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

  Future<List<MeilleurEmplacement>> _chargerMeilleurEmplacement(
    int commandeId,
  ) async {
    final uri = Uri.parse(
      '${widget.baseUrl}/commande/proposerEmplacement/$commandeId',
    );

    final response = await http.get(
      uri,
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Impossible de charger les emplacements (${response.statusCode})',
      );
    }

    final donnees = jsonDecode(utf8.decode(response.bodyBytes));

    if (donnees is! List) {
      throw const FormatException('Liste des emplacements attendue');
    }

    return donnees
        .map(
          (element) =>
              MeilleurEmplacement.fromJson(element as Map<String, dynamic>),
        )
        .toList();
  }

  bool _estGrosse(Commande commande) =>
      commande.quantiteDemande > _seuilGrosseCommande;

  List<Commande> get _commandesAffichees =>
      _grossesSeulement ? _commandes.where(_estGrosse).toList() : _commandes;

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  void _ouvrirParcours() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EcranParcoursPickingMaquette(
          baseUrl: widget.baseUrl,
          accessToken: widget.accessToken,
          journalId: widget.journalId,
          userId: widget.userId,
        ),
      ),
    );
  }

  /// Cherche les meilleurs emplacements d'une commande, puis les affiche.
  Future<void> _consulterEmplacements(Commande commande) async {
    setState(() => _commandeEnChargement = commande.idCommande);

    try {
      final emplacements = await _chargerMeilleurEmplacement(
        commande.idCommande,
      );
      if (!mounted) return;
      setState(() => _commandeEnChargement = null);

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (contexteFeuille) =>
            _feuilleEmplacements(contexteFeuille, commande, emplacements),
      );
    } catch (erreur) {
      if (!mounted) return;
      setState(() => _commandeEnChargement = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erreur.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _ouvrirInsertion(Commande commande, MeilleurEmplacement emplacement) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EcranInsertionSortie(
          baseUrl: widget.baseUrl,
          idEmplacement: emplacement.emplacementId,
          idCommande: commande.idCommande,
          journalId: widget.journalId,
          articleId: commande.idArticle,
          nomArticle: commande.nomArticle,
          nomRack: emplacement.nomRack,
          nomEmplacement: emplacement.nomEmplacement,
          quantiteMaximale: emplacement.quantiteAPrelever,
          dlc: emplacement.dlc,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Affichage
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Habibo.fond,
        body: FondDegrade(
          child: SafeArea(
            child: RefreshIndicator(
              color: Habibo.bleu,
              onRefresh: _chargerCommandes,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  Habibo.marge,
                  12,
                  Habibo.marge,
                  32,
                ),
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [BoutonRetour(), BoutonProfil()],
                  ),
                  const SizedBox(height: 20),
                  _titre(),
                  const SizedBox(height: 20),
                  ..._contenu(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _titre() {
    final nombre = _commandes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Commandes',
          style: TextStyle(
            color: Habibo.texte,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _chargement
              ? 'Chargement…'
              : '$nombre commande${nombre > 1 ? 's' : ''} à préparer',
          style: const TextStyle(color: Habibo.texteSecondaire, fontSize: 15),
        ),
      ],
    );
  }

  List<Widget> _contenu() {
    if (_chargement && _commandes.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator(color: Habibo.bleu)),
        ),
      ];
    }

    if (_erreur != null) {
      return [
        _etatVide(
          icone: LucideIcons.triangleAlert,
          titre: 'Chargement impossible',
          texte: _erreur!,
          couleur: Habibo.rouge,
          fond: Habibo.rougeDoux,
          action: TextButton(
            onPressed: _chargerCommandes,
            style: TextButton.styleFrom(foregroundColor: Habibo.bleu),
            child: const Text('Réessayer'),
          ),
        ),
      ];
    }

    if (_commandes.isEmpty) {
      return [
        _etatVide(
          icone: LucideIcons.package,
          titre: 'Aucune commande',
          texte: 'Ce journal ne contient encore aucune commande.',
        ),
      ];
    }

    final commandes = _commandesAffichees;
    final grosses = _commandes.where(_estGrosse).length;

    return [
      _carteParcours(),
      const SizedBox(height: 20),
      FiltresPastilles(
        marge: 0,
        filtres: [
          FiltrePastille(libelle: 'Toutes', compteur: _commandes.length),
          FiltrePastille(libelle: 'Grosses commandes', compteur: grosses),
        ],
        selection: _grossesSeulement ? 1 : 0,
        onChange: (index) => setState(() => _grossesSeulement = index == 1),
      ),
      const SizedBox(height: 16),
      if (commandes.isEmpty)
        _etatVide(
          icone: LucideIcons.package,
          titre: 'Aucune grosse commande',
          texte: 'Aucune commande ne dépasse $_seuilGrosseCommande packs.',
        )
      else
        for (final commande in commandes) ...[
          _carteCommande(commande),
          const SizedBox(height: 12),
        ],
    ];
  }

  /// Le grand bouton qui lance le meilleur parcours de prélèvement.
  Widget _carteParcours() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: Habibo.carte(rayon: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Habibo.bleuDoux,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.route,
                  size: 22,
                  color: Habibo.bleu,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Prêt à prélever ?',
                  style: TextStyle(
                    color: Habibo.texte,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Toutes les commandes sont regroupées dans le meilleur ordre de '
            'passage entre les emplacements.',
            style: TextStyle(
              color: Habibo.texteSecondaire,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _ouvrirParcours,
              style: FilledButton.styleFrom(
                backgroundColor: Habibo.bleu,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(LucideIcons.route, size: 20),
              label: const Text(
                'Générer le meilleur parcours',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Une commande : article, quantité, et accès à ses meilleurs emplacements.
  Widget _carteCommande(Commande commande) {
    final grosse = _estGrosse(commande);
    final enChargement = _commandeEnChargement == commande.idCommande;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Habibo.carte(rayon: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Habibo.bleuDoux,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.package,
                  size: 22,
                  color: Habibo.bleu,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commande.nomArticle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Habibo.texte,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _pastille(
                          '${commande.quantiteDemande} pack'
                          '${commande.quantiteDemande > 1 ? 's' : ''}',
                          Habibo.bleu,
                          Habibo.bleuDoux,
                        ),
                        if (grosse)
                          _pastille(
                            'Grosse commande',
                            Habibo.orange,
                            Habibo.orangeDoux,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: enChargement
                  ? null
                  : () => _consulterEmplacements(commande),
              style: FilledButton.styleFrom(
                backgroundColor: Habibo.bleuDoux,
                foregroundColor: Habibo.bleu,
                disabledBackgroundColor: Habibo.bleuDoux,
                disabledForegroundColor: Habibo.bleu,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: enChargement
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Habibo.bleu,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.mapPin, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Voir les meilleurs emplacements',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Feuille qui monte du bas : les emplacements proposés pour une commande.
  Widget _feuilleEmplacements(
    BuildContext contexteFeuille,
    Commande commande,
    List<MeilleurEmplacement> emplacements,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(contexteFeuille).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Habibo.fond,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Habibo.bordure,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Text(
                'Meilleurs emplacements',
                style: TextStyle(
                  color: Habibo.texte,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${commande.nomArticle} · ${commande.quantiteDemande} '
                'pack${commande.quantiteDemande > 1 ? 's' : ''} à prélever',
                style: const TextStyle(
                  color: Habibo.texteSecondaire,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              if (emplacements.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Aucun emplacement disponible pour cet article.',
                    style: TextStyle(color: Habibo.texteSecondaire),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: emplacements.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final emplacement = emplacements[index];
                      return _ligneEmplacement(
                        emplacement,
                        onTap: () {
                          Navigator.of(contexteFeuille).pop();
                          _ouvrirInsertion(commande, emplacement);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ligneEmplacement(
    MeilleurEmplacement emplacement, {
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: Habibo.carte(rayon: 18),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Habibo.bleuDoux,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.mapPin,
                    size: 20,
                    color: Habibo.bleu,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emplacement.nomEmplacement,
                        style: const TextStyle(
                          color: Habibo.texte,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        emplacement.nomRack,
                        style: const TextStyle(
                          color: Habibo.texteSecondaire,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _pastille(
                  '${emplacement.quantiteAPrelever} packs',
                  Habibo.vert,
                  Habibo.vertDoux,
                ),
                const SizedBox(width: 6),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: Habibo.texteDiscret,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pastille(String texte, Color couleur, Color fond) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texte,
        style: TextStyle(
          color: couleur,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Message centré (vide, erreur) avec une icône dans une tuile.
  Widget _etatVide({
    required IconData icone,
    required String titre,
    required String texte,
    Color couleur = Habibo.bleu,
    Color fond = Habibo.bleuDoux,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: fond,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icone, size: 28, color: couleur),
          ),
          const SizedBox(height: 16),
          Text(
            titre,
            style: const TextStyle(
              color: Habibo.texte,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            texte,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Habibo.texteSecondaire,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }
}
