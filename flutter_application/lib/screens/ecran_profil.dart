import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/screens/ecran_login.dart';
import 'package:flutter_application/services/session_utilisateur.dart';
import 'package:flutter_application/theme/habibo.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Profil de l'utilisateur connecté : identité, nombre d'opérations, déconnexion.
class EcranProfil extends StatefulWidget {
  const EcranProfil({
    super.key,
    required this.baseUrl,
    required this.accessToken,
    required this.userId,
  });

  final String baseUrl;
  final String accessToken;
  final int userId;

  @override
  State<EcranProfil> createState() => _EcranProfilState();
}

class _EcranProfilState extends State<EcranProfil> {
  // Les trois types d'opérations toujours affichés, dans cet ordre.
  static const _typesOperations = ['ENTREE', 'SORTIE', 'INVENTAIRE'];

  // Réponse du serveur : nom, matricule, nomRole, imageUser, operations.
  Map<String, dynamic>? _profil;
  String? _erreur;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '${widget.baseUrl}/user/nombreOperations/${widget.userId}',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${widget.accessToken}',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final donnees = jsonDecode(utf8.decode(response.bodyBytes));
      if (donnees is! Map<String, dynamic>) {
        throw const FormatException('Réponse inattendue du serveur.');
      }

      if (!mounted) return;
      setState(() {
        _profil = donnees;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Impossible de charger le profil.';
        _chargement = false;
      });
    }
  }

  /// Le serveur note le départ dans le journal d'activité ; même s'il ne
  /// répond pas, on se déconnecte quand même.
  Future<void> _seDeconnecter() async {
    try {
      await http
          .post(
            Uri.parse('${widget.baseUrl}/user/logout'),
            headers: {'Authorization': 'Bearer ${widget.accessToken}'},
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Rien à faire : la session locale est quand même fermée.
    }

    SessionUtilisateur.fermer();

    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => EcranLogin(baseUrl: widget.baseUrl)),
      (route) => false,
    );
  }

  // ------------------------------------------------------------------
  // Données prêtes à afficher
  // ------------------------------------------------------------------

  /// Nombre d'opérations par type : { 'ENTREE': 42, 'SORTIE': 71, ... }.
  Map<String, int> get _operationsParType {
    final resultat = <String, int>{};
    final liste = _profil?['operations'];
    if (liste is List) {
      for (final operation in liste.whereType<Map<String, dynamic>>()) {
        final nom = '${operation['nomOperation'] ?? ''}'.toUpperCase();
        resultat[nom] = (operation['nombreOperations'] as num?)?.toInt() ?? 0;
      }
    }
    return resultat;
  }

  int get _totalOperations =>
      _operationsParType.values.fold(0, (somme, valeur) => somme + valeur);

  /// "Jean Martin" donne "JM", "Jean" donne "JE".
  String _initiales(String nom) {
    final mots = nom
        .trim()
        .split(RegExp(r'\s+'))
        .where((mot) => mot.isNotEmpty)
        .toList();
    if (mots.isEmpty) return '?';
    if (mots.length == 1) {
      final mot = mots.first;
      return mot.substring(0, mot.length < 2 ? 1 : 2).toUpperCase();
    }
    return '${mots.first[0]}${mots.last[0]}'.toUpperCase();
  }

  /// Nom du rôle tel qu'on le dit à l'oral.
  String _libelleRole(String? role) {
    switch (role) {
      case 'ADMIN':
        return 'Administrateur';
      case 'AUDITEUR':
        return 'Auditeur';
      case 'OPERATEUR':
        return 'Opérateur';
      case 'INVENTORISTE':
        return 'Inventoriste';
      default:
        return role ?? '—';
    }
  }

  String _libelleOperation(String type) {
    switch (type) {
      case 'ENTREE':
        return 'Entrées';
      case 'SORTIE':
        return 'Sorties';
      case 'INVENTAIRE':
        return 'Inventaires';
      default:
        return type.isEmpty
            ? 'Autres'
            : '${type[0]}${type.substring(1).toLowerCase()}';
    }
  }

  IconData _iconeOperation(String type) {
    switch (type) {
      case 'ENTREE':
        return LucideIcons.logIn;
      case 'SORTIE':
        return LucideIcons.logOut;
      case 'INVENTAIRE':
        return LucideIcons.clipboardCheck;
      default:
        return LucideIcons.activity;
    }
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
        body: Container(
          // Léger dégradé bleu pâle en haut, qui se fond dans le fond de l'application.
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Habibo.bleuDoux, Habibo.fond],
              stops: [0, 0.5],
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              color: Habibo.bleu,
              onRefresh: _charger,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  Habibo.marge,
                  12,
                  Habibo.marge,
                  32,
                ),
                children: [
                  _boutonRetour(),
                  const SizedBox(height: 20),
                  const Text(
                    'Profil',
                    style: TextStyle(
                      color: Habibo.texte,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
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

  /// Rond blanc avec une flèche, comme sur les applications récentes.
  Widget _boutonRetour() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Habibo.surface,
        shape: const CircleBorder(side: BorderSide(color: Habibo.bordure)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(
            width: 46,
            height: 46,
            child: Icon(LucideIcons.arrowLeft, size: 20, color: Habibo.texte),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenu() {
    if (_chargement && _profil == null) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator(color: Habibo.bleu)),
        ),
      ];
    }

    if (_erreur != null) {
      return [
        Text(
          _erreur!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Habibo.rouge, fontSize: 15),
        ),
        Center(
          child: TextButton(
            onPressed: _charger,
            style: TextButton.styleFrom(foregroundColor: Habibo.bleu),
            child: const Text('Réessayer'),
          ),
        ),
      ];
    }

    // Les trois types habituels d'abord (même à 0), puis d'éventuels autres.
    final parType = _operationsParType;
    final types = [
      ..._typesOperations,
      ...parType.keys.where((type) => !_typesOperations.contains(type)),
    ];

    return [
      _carteIdentite(),
      const SizedBox(height: 16),
      _groupe([
        for (final type in types)
          _ligne(
            icone: _iconeOperation(type),
            libelle: _libelleOperation(type),
            valeur: '${parType[type] ?? 0}',
          ),
      ]),
      const SizedBox(height: 16),
      _groupe([
        _ligne(
          icone: LucideIcons.logOut,
          libelle: 'Se déconnecter',
          danger: true,
          avecFleche: true,
          onTap: _seDeconnecter,
        ),
      ]),
    ];
  }

  /// Photo, nom, rôle et matricule, puis la pastille du total d'opérations.
  Widget _carteIdentite() {
    final profil = _profil!;
    final nom = (profil['nom'] as String?) ?? '';
    final role = _libelleRole(profil['nomRole'] as String?);
    final matricule = profil['matricule'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: _decorationCarte(rayon: 28),
      child: Column(
        children: [
          _avatar(nom, profil['imageUser'] as String?),
          const SizedBox(height: 16),
          Text(
            nom,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Habibo.texte,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            matricule == null ? role : '$role  ·  Matricule $matricule',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Habibo.texteSecondaire, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Habibo.bleu,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.activity, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _totalOperations > 1
                      ? '$_totalOperations opérations'
                      : '$_totalOperations opération',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Photo de profil entourée d'un fin cercle bleu, ou les initiales.
  Widget _avatar(String nom, String? photo) {
    final initiales = Container(
      color: Habibo.bleuDoux,
      alignment: Alignment.center,
      child: Text(
        _initiales(nom),
        style: const TextStyle(
          color: Habibo.bleu,
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Habibo.bleu, width: 2),
      ),
      child: ClipOval(
        child: SizedBox(
          width: 88,
          height: 88,
          child: (photo == null || photo.isEmpty)
              ? initiales
              : Image.network(
                  '${widget.baseUrl}/$photo',
                  fit: BoxFit.cover,
                  errorBuilder: (contexte, erreur, pile) => initiales,
                ),
        ),
      ),
    );
  }

  /// Un bloc blanc arrondi qui regroupe plusieurs lignes séparées par un filet.
  Widget _groupe(List<Widget> lignes) {
    final enfants = <Widget>[];
    for (var i = 0; i < lignes.length; i++) {
      if (i > 0) {
        enfants.add(
          const Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: Habibo.neutreDoux,
          ),
        );
      }
      enfants.add(lignes[i]);
    }

    return Container(
      decoration: _decorationCarte(rayon: 22),
      clipBehavior: Clip.antiAlias,
      child: Column(children: enfants),
    );
  }

  /// Icône dans une tuile arrondie, libellé, puis une valeur ou une flèche.
  Widget _ligne({
    required IconData icone,
    required String libelle,
    String? valeur,
    bool danger = false,
    bool avecFleche = false,
    VoidCallback? onTap,
  }) {
    final couleur = danger ? Habibo.rouge : Habibo.bleu;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: danger ? Habibo.rougeDoux : Habibo.bleuDoux,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, size: 20, color: couleur),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                libelle,
                style: TextStyle(
                  color: danger ? Habibo.rouge : Habibo.texte,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (valeur != null)
              Text(
                valeur,
                style: const TextStyle(
                  color: Habibo.texte,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (avecFleche)
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: Habibo.texteDiscret,
              ),
          ],
        ),
      ),
    );
  }

  /// Carte blanche aux angles arrondis, avec une ombre très douce.
  BoxDecoration _decorationCarte({required double rayon}) {
    return BoxDecoration(
      color: Habibo.surface,
      borderRadius: BorderRadius.circular(rayon),
      border: Border.all(color: Habibo.bordure.withValues(alpha: 0.6)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
