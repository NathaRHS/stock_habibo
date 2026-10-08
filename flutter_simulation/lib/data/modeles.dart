/// Modeles de la simulation. Ils reprennent les notions de l'application
/// reelle (journal, commande, ligne de picking, emplacement, lot) sans serveur.
library;

enum TypeJournal { entree, sortie, inventaire }

enum Role { operateur, inventoriste }

class Utilisateur {
  const Utilisateur({
    required this.nom,
    required this.matricule,
    required this.role,
  });

  final String nom;
  final String matricule;
  final Role role;

  String get libelleRole =>
      role == Role.operateur ? 'Opérateur' : 'Inventoriste';

  String get prenom => nom.split(' ').first;

  String get initiales {
    final mots = nom.trim().split(RegExp(r'\s+'));
    if (mots.length == 1) return mots.first.substring(0, 1).toUpperCase();
    return '${mots.first[0]}${mots.last[0]}'.toUpperCase();
  }
}

class Article {
  const Article({
    required this.id,
    required this.nom,
    required this.famille,
    required this.contenance,
    required this.codeBarres,
    required this.typeProduit,
    required this.piecesParUnite,
    required this.unite,
    this.photo,
  });

  final int id;
  final String nom;
  final String famille;

  /// Contenance d'une piece : « 33 cL », « 1 L », « 500 g ».
  final String contenance;
  final String codeBarres;
  final String typeProduit;

  /// Nombre de pieces dans une unite de conditionnement.
  final int piecesParUnite;

  /// Nom de l'unite de conditionnement : « pack », « carton ».
  final String unite;

  /// Chemin de l'image dans les assets, ou null s'il n'y a pas de photo.
  final String? photo;

  String get titre => contenance.isEmpty ? nom : '$nom · $contenance';

  String unites(int quantite) => '$quantite $unite${quantite > 1 ? 's' : ''}';
}

class Emplacement {
  const Emplacement({
    required this.id,
    required this.rack,
    required this.etage,
    required this.position,
  });

  final int id;
  final String rack; // A, B, C, D
  final int etage;
  final int position;

  /// Code court affiche partout : A12 = rack A, etage 1, position 2.
  String get code => '$rack$etage$position';

  String get nomRack => 'Rack $rack';

  /// Ordre de passage dans l'entrepot (rack, puis etage, puis position).
  int get ordre => rack.codeUnitAt(0) * 100 + etage * 10 + position;
}

/// Un lot : un article dans un emplacement, avec ses dates.
class Lot {
  Lot({
    required this.article,
    required this.emplacement,
    required this.pieces,
    required this.dlc,
    required this.dlv,
  });

  final Article article;
  final Emplacement emplacement;
  int pieces;
  final DateTime dlc;
  final DateTime dlv;

  int get unites => pieces ~/ article.piecesParUnite;
}

class DetailReception {
  DetailReception({
    required this.article,
    required this.quantite,
    required this.dlc,
    required this.dlv,
  });

  final Article article;
  int quantite;
  final DateTime dlc;
  final DateTime dlv;
}

/// Une ligne d'un bon de sortie : un article et une quantite demandee.
class Commande {
  const Commande({
    required this.id,
    required this.article,
    required this.quantiteDemandee,
  });

  final int id;
  final Article article;

  /// En unites de conditionnement (packs, cartons).
  final int quantiteDemandee;
}

/// Une etape du parcours de picking (= ligne de picking).
class EtapePicking {
  EtapePicking({
    required this.id,
    required this.commande,
    required this.lot,
    required this.quantite,
  });

  final int id;
  final Commande commande;
  final Lot lot;
  final int quantite;
  int quantitePrelevee = 0;
  int ordre = 0;

  Article get article => commande.article;
  Emplacement get emplacement => lot.emplacement;
  bool get terminee => quantitePrelevee >= quantite;
  int get restant => quantite - quantitePrelevee;
  String get statut => terminee
      ? 'PRELEVEE'
      : quantitePrelevee > 0
      ? 'EN_COURS'
      : 'RESERVEE';
}

/// Proposition d'emplacement pour une commande (premier perime, premier sorti).
class Proposition {
  const Proposition({required this.lot, required this.quantite});

  final Lot lot;
  final int quantite;
}

class Journal {
  Journal({
    required this.id,
    required this.reference,
    required this.type,
    required this.statut,
    required this.date,
    this.tiers,
    List<DetailReception>? receptions,
    List<Commande>? commandes,
  }) : receptions = receptions ?? [],
       commandes = commandes ?? [];

  final int id;
  final String reference;
  final TypeJournal type;
  String statut;
  final DateTime date;

  /// Fournisseur (entree) ou client (sortie).
  final String? tiers;
  final List<DetailReception> receptions;
  final List<Commande> commandes;

  /// Parcours de picking, genere a la demande (sorties).
  List<EtapePicking>? parcours;

  /// Emplacements deja comptes (inventaires).
  final Set<int> emplacementsComptes = {};

  String get libelleType => switch (type) {
    TypeJournal.entree => 'Entrée',
    TypeJournal.sortie => 'Sortie',
    TypeJournal.inventaire => 'Inventaire',
  };

  /// Une session ne s'ouvre que tant qu'elle est en cours ou a corriger.
  bool get estOuvrable => statut == 'EN COURS' || statut == 'MODIFIE';

  bool get estValide =>
      statut == 'VALIDE' || statut == 'AFFECTEE' || statut == 'CLOTURE';

  int get nombreProduits => switch (type) {
    TypeJournal.entree => receptions.length,
    TypeJournal.sortie => commandes.length,
    TypeJournal.inventaire => emplacementsComptes.length,
  };

  bool get parcoursTermine =>
      parcours != null &&
      parcours!.isNotEmpty &&
      parcours!.every((etape) => etape.terminee);

  /// Avancement entre 0 et 1, pour la carte « Reprendre ».
  double get avancement {
    if (type == TypeJournal.sortie) {
      final etapes = parcours;
      if (etapes == null || etapes.isEmpty) return 0;
      return etapes.where((etape) => etape.terminee).length / etapes.length;
    }
    return 0;
  }
}

class Mouvement {
  const Mouvement({
    required this.article,
    required this.date,
    required this.entree,
    required this.pieces,
    required this.reference,
  });

  final Article article;
  final DateTime date;
  final bool entree;
  final int pieces;
  final String reference;
}

enum TypeActivite { reception, prelevement, comptage, parcours }

class Activite {
  const Activite({
    required this.date,
    required this.type,
    required this.titre,
    required this.detail,
  });

  final DateTime date;
  final TypeActivite type;
  final String titre;
  final String detail;
}
