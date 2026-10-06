import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/models/journal_mouvement.dart';
import 'package:flutter_application/screens/ecran_choix_emplacement_inventaire.dart';
import 'package:flutter_application/screens/ecran_liste_commande.dart';
import 'package:flutter_application/screens/ecran_scan_session.dart';
import 'package:flutter_application/theme/habibo.dart';
import 'package:flutter_application/widgets/carte_journal.dart';
import 'package:flutter_application/widgets/filtres_pastilles.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EcranListeJournaux extends StatefulWidget {
  const EcranListeJournaux({
    super.key,
    required this.baseUrl,
    required this.accessToken,
    required this.role,
    required this.userId,
    this.nomUtilisateur,
  });

  final String baseUrl;
  final String accessToken;
  final String role;
  final int userId;
  final String? nomUtilisateur;

  @override
  State<EcranListeJournaux> createState() => _EcranListeJournauxState();
}

enum _Filtre { tous, enCours, valides }

class _EcranListeJournauxState extends State<EcranListeJournaux> {
  static const _jours = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
  static const _mois = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  final _rechercheController = TextEditingController();

  List<JournalMouvement> _journaux = [];
  String? _erreur;
  bool _chargement = true;
  _Filtre _filtre = _Filtre.tous;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _chargerJournaux();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _chargerJournaux() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final uri = Uri.parse('${widget.baseUrl}/journaux-mouvements');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Impossible de charger les journaux (${response.statusCode})',
        );
      }

      final donnees = jsonDecode(utf8.decode(response.bodyBytes));

      if (donnees is! List) {
        throw const FormatException('Réponse inattendue du serveur');
      }

      final role = widget.role.trim().toUpperCase();
      final journaux =
          donnees
              .map(
                (element) =>
                    JournalMouvement.fromJson(element as Map<String, dynamic>),
              )
              // Chaque rôle ne voit que ses types de journaux.
              .where((journal) {
                if (role == 'INVENTORISTE') return journal.type == 'INVENTAIRE';
                if (role == 'OPERATEUR') {
                  return journal.type == 'ENTREE' || journal.type == 'SORTIE';
                }
                return false;
              })
              .toList()
            // Pas de date sur un journal : le plus récent est celui au plus grand id.
            ..sort((a, b) => b.id.compareTo(a.id));

      if (!mounted) return;

      setState(() {
        _journaux = journaux;
      });
    } catch (erreur) {
      if (!mounted) return;

      setState(() {
        _erreur = erreur.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _chargement = false;
        });
      }
    }
  }

  Future<void> _ouvrir(JournalMouvement journal) async {
    final Widget prochainePage;

    if (journal.type == 'INVENTAIRE') {
      prochainePage = EcranChoixEmplacementInventaire(
        journalId: journal.id,
        referenceJournal: journal.reference,
        baseUrl: widget.baseUrl,
        accessToken: widget.accessToken,
      );
    } else if (journal.type == 'SORTIE') {
      prochainePage = EcranListeCommande(
        journalId: journal.id,
        baseUrl: widget.baseUrl,
        accessToken: widget.accessToken,
        userId: widget.userId,
      );
    } else {
      prochainePage = EcranScanSession(
        journalId: journal.id,
        referenceJournal: journal.reference,
        typeJournal: journal.typeMouvementJournal,
        baseUrl: widget.baseUrl,
        accessToken: widget.accessToken,
      );
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => prochainePage));

    if (mounted) _chargerJournaux();
  }

  bool _correspondAuFiltre(JournalMouvement journal, _Filtre filtre) {
    switch (filtre) {
      case _Filtre.tous:
        return true;
      case _Filtre.enCours:
        return journal.estOuvrable;
      case _Filtre.valides:
        return journal.estValide;
    }
  }

  int _compter(_Filtre filtre) =>
      _journaux.where((journal) => _correspondAuFiltre(journal, filtre)).length;

  List<JournalMouvement> get _journauxAffiches {
    final texte = _recherche.trim().toLowerCase();

    return _journaux.where((journal) {
      if (!_correspondAuFiltre(journal, _filtre)) return false;
      if (texte.isEmpty) return true;
      return [
        journal.reference,
        journal.fournisseur,
        journal.nomClient,
      ].any((valeur) => valeur != null && valeur.toLowerCase().contains(texte));
    }).toList();
  }

  String get _dateDuJour {
    final maintenant = DateTime.now();
    return '${_jours[maintenant.weekday - 1]} ${maintenant.day} '
        '${_mois[maintenant.month - 1]}';
  }

  String? get _initiales {
    final mots = (widget.nomUtilisateur ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((mot) => mot.isNotEmpty)
        .toList();
    if (mots.isEmpty) return null;
    if (mots.length == 1) {
      final mot = mots.first;
      return mot.substring(0, mot.length < 2 ? 1 : 2).toUpperCase();
    }
    return '${mots.first[0]}${mots.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final journaux = _journauxAffiches;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Habibo.fond,
        body: SafeArea(
          child: RefreshIndicator(
            color: Habibo.bleu,
            onRefresh: _chargerJournaux,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              children: [
                _entete(),
                const SizedBox(height: 20),
                _champRecherche(),
                const SizedBox(height: 16),
                FiltresPastilles(
                  filtres: [
                    FiltrePastille(
                      libelle: 'Tous',
                      compteur: _compter(_Filtre.tous),
                    ),
                    FiltrePastille(
                      libelle: 'En cours',
                      compteur: _compter(_Filtre.enCours),
                    ),
                    FiltrePastille(
                      libelle: 'Validés',
                      compteur: _compter(_Filtre.valides),
                    ),
                  ],
                  selection: _filtre.index,
                  onChange: (index) =>
                      setState(() => _filtre = _Filtre.values[index]),
                ),
                const SizedBox(height: 20),
                ..._contenu(journaux),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenu(List<JournalMouvement> journaux) {
    if (_chargement && _journaux.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator(color: Habibo.bleu)),
        ),
      ];
    }

    if (_erreur != null) {
      return [
        _message(_erreur!, couleur: Habibo.rouge),
        Center(
          child: TextButton(
            onPressed: _chargerJournaux,
            style: TextButton.styleFrom(foregroundColor: Habibo.bleu),
            child: const Text('Réessayer'),
          ),
        ),
      ];
    }

    if (journaux.isEmpty) {
      return [
        _message(
          _journaux.isEmpty ? 'Aucun journal pour le moment.' : 'Aucun résultat.',
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Habibo.marge),
        child: GroupeJournaux(journaux: journaux, onOuvrir: _ouvrir),
      ),
    ];
  }

  Widget _entete() {
    final initiales = _initiales;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Habibo.marge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateDuJour,
                  style: const TextStyle(
                    color: Habibo.texteSecondaire,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Journaux',
                  style: TextStyle(
                    color: Habibo.texte,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Habibo.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Habibo.bordure),
            ),
            child: initiales == null
                ? const Icon(
                    LucideIcons.user,
                    size: 20,
                    color: Habibo.texteSecondaire,
                  )
                : Text(
                    initiales,
                    style: const TextStyle(
                      color: Habibo.texte,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _champRecherche() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Habibo.marge),
      child: TextField(
        controller: _rechercheController,
        onChanged: (valeur) => setState(() => _recherche = valeur),
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: Habibo.texte, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Rechercher une référence',
          hintStyle: const TextStyle(color: Habibo.texteDiscret),
          prefixIcon: const Icon(
            LucideIcons.search,
            size: 20,
            color: Habibo.texteSecondaire,
          ),
          suffixIcon: _recherche.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Effacer',
                  onPressed: () {
                    _rechercheController.clear();
                    setState(() => _recherche = '');
                  },
                  icon: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: Habibo.texteSecondaire,
                  ),
                ),
          filled: true,
          fillColor: Habibo.neutreDoux,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _message(String texte, {Color couleur = Habibo.texteSecondaire}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Habibo.marge, 48, Habibo.marge, 8),
      child: Text(
        texte,
        textAlign: TextAlign.center,
        style: TextStyle(color: couleur, fontSize: 15),
      ),
    );
  }
}
