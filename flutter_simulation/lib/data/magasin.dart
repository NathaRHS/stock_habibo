import 'package:flutter/foundation.dart';

import 'modeles.dart';

/// Etat de la simulation : tout est en memoire, rien n'est envoye a un serveur.
/// Les regles suivent celles du projet (premier perime premier sorti, stock
/// reserve par les parcours, prelevement partiel avec un reste).
class Magasin extends ChangeNotifier {
  Magasin() {
    _construire();
  }

  // ------------------------------------------------------------------
  // Session
  // ------------------------------------------------------------------

  Utilisateur? utilisateur;

  /// Simule « rester connecte » : au prochain demarrage, on saute la connexion.
  bool sessionMemorisee = false;

  bool vibrations = true;
  bool sons = true;

  void connecter(Role role) {
    utilisateur = role == Role.operateur
        ? const Utilisateur(
            nom: 'Andry Rakoto',
            matricule: '10482',
            role: Role.operateur,
          )
        : const Utilisateur(
            nom: 'Miora Rasoa',
            matricule: '10517',
            role: Role.inventoriste,
          );
    sessionMemorisee = true;
    notifyListeners();
  }

  void deconnecter() {
    utilisateur = null;
    sessionMemorisee = false;
    notifyListeners();
  }

  void reglerVibrations(bool valeur) {
    vibrations = valeur;
    notifyListeners();
  }

  void reglerSons(bool valeur) {
    sons = valeur;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Donnees
  // ------------------------------------------------------------------

  final List<Article> articles = [];
  final List<Emplacement> emplacements = [];
  final List<Lot> lots = [];
  final List<Journal> journaux = [];
  final List<Mouvement> mouvements = [];
  final List<Activite> activites = [];

  int _prochainId = 1000;

  /// Chaque role ne voit que ses types de journaux (comme l'application reelle).
  List<Journal> get journauxVisibles {
    final role = utilisateur?.role;
    return journaux.where((journal) {
      if (role == Role.inventoriste) {
        return journal.type == TypeJournal.inventaire;
      }
      return journal.type != TypeJournal.inventaire;
    }).toList()..sort((a, b) => b.id.compareTo(a.id));
  }

  Journal? _derniereOuverte;

  /// A appeler quand l'operateur ouvre un journal : c'est celui qu'on lui
  /// proposera de reprendre.
  void noterOuverture(Journal journal) {
    _derniereOuverte = journal;
  }

  /// L'operation a reprendre : la derniere ouverte si elle est encore a faire,
  /// sinon la plus recente en cours.
  Journal? get operationEnCours {
    final ouvertes = journauxVisibles
        .where((journal) => journal.estOuvrable && !journal.parcoursTermine)
        .toList();
    if (ouvertes.isEmpty) return null;
    final derniere = _derniereOuverte;
    if (derniere != null && ouvertes.contains(derniere)) return derniere;
    return ouvertes.first;
  }

  int compter(TypeJournal type) => journaux
      .where((journal) => journal.type == type && journal.estOuvrable)
      .length;

  Article? articleParCode(String code) {
    for (final article in articles) {
      if (article.codeBarres == code.trim()) return article;
    }
    return null;
  }

  List<String> get familles =>
      {for (final article in articles) article.famille}.toList();

  // ------------------------------------------------------------------
  // Stock : physique, reserve, disponible (en unites de conditionnement)
  // ------------------------------------------------------------------

  List<Lot> lotsArticle(Article article) =>
      lots.where((lot) => lot.article.id == article.id).toList()
        ..sort((a, b) => a.dlc.compareTo(b.dlc));

  List<Lot> lotsEmplacement(Emplacement emplacement) =>
      lots.where((lot) => lot.emplacement.id == emplacement.id).toList();

  int stockPhysique(Article article) =>
      lotsArticle(article).fold(0, (total, lot) => total + lot.unites);

  /// Unites promises a un parcours tant que la sortie n'est pas cloturee.
  int _reserveLot(Lot lot) {
    var total = 0;
    for (final journal in journaux) {
      if (journal.statut == 'CLOTURE') continue;
      for (final etape in journal.parcours ?? const <EtapePicking>[]) {
        if (identical(etape.lot, lot)) total += etape.quantite;
      }
    }
    return total;
  }

  int stockReserve(Article article) =>
      lotsArticle(article).fold(0, (total, lot) => total + _reserveLot(lot));

  int stockDisponible(Article article) =>
      stockPhysique(article) - stockReserve(article);

  bool stockBas(Article article) => stockDisponible(article) <= 10;

  // ------------------------------------------------------------------
  // Sorties : proposition, parcours, prelevement
  // ------------------------------------------------------------------

  /// Premier perime, premier sorti, en retirant ce qui est deja reserve.
  List<Proposition> proposerEmplacements(Commande commande) {
    final propositions = <Proposition>[];
    var restant = commande.quantiteDemandee;

    for (final lot in lotsArticle(commande.article)) {
      if (restant <= 0) break;
      final disponible = lot.unites - _reserveLot(lot);
      if (disponible <= 0) continue;
      final quantite = disponible < restant ? disponible : restant;
      propositions.add(Proposition(lot: lot, quantite: quantite));
      restant -= quantite;
    }

    return propositions;
  }

  /// Ce qui ne pourra pas etre servi (prelevement partiel).
  int resteCommande(Journal journal, Commande commande) {
    final etapes = journal.parcours;
    final servi = etapes == null
        ? proposerEmplacements(commande)
              .fold(0, (total, proposition) => total + proposition.quantite)
        : etapes
              .where((etape) => etape.commande.id == commande.id)
              .fold(0, (total, etape) => total + etape.quantite);
    final reste = commande.quantiteDemandee - servi;
    return reste < 0 ? 0 : reste;
  }

  /// Genere le meilleur parcours : on prend ce qui existe, trie par rack.
  List<EtapePicking> genererParcours(Journal journal) {
    final existant = journal.parcours;
    if (existant != null) return existant;

    final etapes = <EtapePicking>[];
    for (final commande in journal.commandes) {
      for (final proposition in proposerEmplacements(commande)) {
        final etape = EtapePicking(
          id: _prochainId++,
          commande: commande,
          lot: proposition.lot,
          quantite: proposition.quantite,
        );
        etapes.add(etape);
        // Reserve tout de suite : la commande suivante ne voit plus ce stock.
        journal.parcours = etapes;
      }
    }

    etapes.sort((a, b) => a.emplacement.ordre.compareTo(b.emplacement.ordre));
    for (var i = 0; i < etapes.length; i++) {
      etapes[i].ordre = i + 1;
    }

    journal.parcours = etapes;
    _noter(
      TypeActivite.parcours,
      'Parcours généré',
      '${journal.reference} · ${etapes.length} emplacements',
    );
    notifyListeners();
    return etapes;
  }

  void prelever(Journal journal, EtapePicking etape, int quantite) {
    etape.quantitePrelevee += quantite;
    _noter(
      TypeActivite.prelevement,
      etape.article.titre,
      '${etape.article.unites(quantite)} · ${etape.emplacement.code}',
    );
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Entrees : reception
  // ------------------------------------------------------------------

  DetailReception recevoir(
    Journal journal,
    Article article,
    int quantite,
    DateTime dlc,
    DateTime dlv,
  ) {
    DetailReception? detail;
    for (final existant in journal.receptions) {
      if (existant.article.id == article.id &&
          existant.dlc == dlc &&
          existant.dlv == dlv) {
        detail = existant;
      }
    }

    if (detail == null) {
      detail = DetailReception(
        article: article,
        quantite: quantite,
        dlc: dlc,
        dlv: dlv,
      );
      journal.receptions.insert(0, detail);
    } else {
      detail.quantite += quantite;
      journal.receptions
        ..remove(detail)
        ..insert(0, detail);
    }

    _noter(
      TypeActivite.reception,
      article.titre,
      '${article.unites(quantite)} reçus · ${journal.reference}',
    );
    notifyListeners();
    return detail;
  }

  // ------------------------------------------------------------------
  // Inventaires : comptage
  // ------------------------------------------------------------------

  void compterEmplacement(
    Journal journal,
    Emplacement emplacement,
    Article article,
    int quantite,
  ) {
    journal.emplacementsComptes.add(emplacement.id);
    _noter(
      TypeActivite.comptage,
      'Emplacement ${emplacement.code}',
      '${article.nom} · ${article.unites(quantite)} comptés',
    );
    notifyListeners();
  }

  /// L'operateur a fini sa partie : le journal part au controle.
  void terminerParticipation(Journal journal) {
    journal.statut = 'EN ATTENTE';
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Fiche produit : mouvements
  // ------------------------------------------------------------------

  List<Mouvement> mouvementsArticle(Article article, int jours) {
    final limite = DateTime.now().subtract(Duration(days: jours));
    return mouvements
        .where(
          (mouvement) =>
              mouvement.article.id == article.id &&
              mouvement.date.isAfter(limite),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Simule un appel au serveur (pour les indicateurs de chargement).
  Future<void> rafraichir() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    notifyListeners();
  }

  void _noter(TypeActivite type, String titre, String detail) {
    activites.insert(
      0,
      Activite(date: DateTime.now(), type: type, titre: titre, detail: detail),
    );
  }

  // ------------------------------------------------------------------
  // Jeu de donnees fictif
  // ------------------------------------------------------------------

  void _construire() {
    final aujourdhui = DateTime.now();
    DateTime dans(int jours) => DateTime(
      aujourdhui.year,
      aujourdhui.month,
      aujourdhui.day,
    ).add(Duration(days: jours));

    Article article(
      int id,
      String nom,
      String famille,
      String contenance,
      String code,
      String type,
      int pieces,
      String unite, {
      bool photo = true,
    }) {
      final nouveau = Article(
        id: id,
        nom: nom,
        famille: famille,
        contenance: contenance,
        codeBarres: code,
        typeProduit: type,
        piecesParUnite: pieces,
        unite: unite,
        photo: photo ? 'assets/produits/$code.jpg' : null,
      );
      articles.add(nouveau);
      return nouveau;
    }

    final coca33 = article(
      1,
      'Coca-Cola',
      'Coca-Cola',
      '33 cL',
      '5449000000996',
      'Boisson',
      24,
      'pack',
    );
    final coca1 = article(
      2,
      'Coca-Cola',
      'Coca-Cola',
      '1 L',
      '5449000054227',
      'Boisson',
      6,
      'pack',
    );
    final coca15 = article(
      3,
      'Coca-Cola',
      'Coca-Cola',
      '1,5 L',
      '5449000000439',
      'Boisson',
      6,
      'pack',
    );
    final fanta = article(
      4,
      'Fanta Orange',
      'Fanta',
      '33 cL',
      '5449000011527',
      'Boisson',
      24,
      'pack',
    );
    final sprite = article(
      5,
      'Sprite',
      'Sprite',
      '50 cL',
      '5449000110671',
      'Boisson',
      12,
      'pack',
    );
    final schweppes = article(
      6,
      'Schweppes Indian Tonic',
      'Schweppes',
      '15 cL',
      '3124480159113',
      'Boisson',
      24,
      'pack',
    );
    final lait = article(
      7,
      'Lait Candia Viva',
      'Lait Candia',
      '1 L',
      '3176571983008',
      'Alimentaire',
      6,
      'carton',
    );
    final choco = article(
      8,
      'Candia Candy Choco',
      'Lait Candia',
      '1 L',
      '6130433000262',
      'Alimentaire',
      6,
      'carton',
    );
    final laitBio = article(
      9,
      'Lait Candia Bio',
      'Lait Candia',
      '50 cL',
      '3533631837006',
      'Alimentaire',
      12,
      'carton',
    );
    final penne = article(
      10,
      'Panzani Penne Rigate',
      'Pâtes Panzani',
      '500 g',
      '3038350013804',
      'Alimentaire',
      20,
      'carton',
    );
    final spaghetti = article(
      11,
      'Panzani Spaghetti',
      'Pâtes Panzani',
      '500 g',
      '3038350208613',
      'Alimentaire',
      20,
      'carton',
    );
    final coquillettes = article(
      12,
      'Panzani Coquillettes',
      'Pâtes Panzani',
      '1 kg',
      '3038350023001',
      'Alimentaire',
      10,
      'carton',
    );
    final margarine = article(
      13,
      'Margarine de table',
      'Margarine',
      '250 g',
      '6191234500017',
      'Alimentaire',
      24,
      'carton',
      photo: false,
    );
    final couches = article(
      14,
      'Couches bébé T4',
      'Hygiène bébé',
      '30 pièces',
      '6191234500048',
      'Hygiène',
      4,
      'carton',
      photo: false,
    );

    // Entrepot : 4 racks, 3 etages, 4 positions.
    var idEmplacement = 1;
    for (final rack in ['A', 'B', 'C', 'D']) {
      for (var etage = 1; etage <= 3; etage++) {
        for (var position = 1; position <= 4; position++) {
          emplacements.add(
            Emplacement(
              id: idEmplacement++,
              rack: rack,
              etage: etage,
              position: position,
            ),
          );
        }
      }
    }

    Emplacement place(String code) =>
        emplacements.firstWhere((emplacement) => emplacement.code == code);

    void lot(Article article, String code, int unites, int dlc) {
      lots.add(
        Lot(
          article: article,
          emplacement: place(code),
          pieces: unites * article.piecesParUnite,
          dlc: dans(dlc),
          dlv: dans(dlc - 20),
        ),
      );
    }

    lot(coca33, 'A11', 40, 95);
    lot(coca33, 'A12', 60, 180);
    lot(coca1, 'A13', 28, 120);
    lot(coca15, 'A21', 6, 60);
    lot(coca15, 'A22', 45, 210);
    lot(fanta, 'A23', 36, 140);
    lot(sprite, 'A31', 30, 150);
    lot(schweppes, 'A32', 18, 75);
    lot(lait, 'B11', 12, 12);
    lot(lait, 'B12', 50, 85);
    lot(choco, 'B13', 22, 70);
    lot(laitBio, 'B21', 16, 40);
    lot(penne, 'C11', 34, 400);
    lot(spaghetti, 'C12', 26, 380);
    lot(coquillettes, 'C13', 5, 300);
    lot(margarine, 'C21', 14, 55);
    lot(couches, 'D11', 9, 900);

    journaux.addAll([
      Journal(
        id: 31,
        reference: 'SOR-2610-031',
        type: TypeJournal.sortie,
        statut: 'EN COURS',
        date: dans(0),
        tiers: 'Supermarché Score Ankorondrano',
        commandes: [
          Commande(id: 311, article: coca15, quantiteDemandee: 14),
          Commande(id: 312, article: lait, quantiteDemandee: 20),
          Commande(id: 313, article: penne, quantiteDemandee: 10),
          Commande(id: 314, article: coquillettes, quantiteDemandee: 8),
          Commande(id: 315, article: fanta, quantiteDemandee: 12),
        ],
      ),
      Journal(
        id: 30,
        reference: 'SOR-2610-030',
        type: TypeJournal.sortie,
        statut: 'EN COURS',
        date: dans(0),
        tiers: 'Shoprite Analakely',
        commandes: [
          Commande(id: 301, article: coca33, quantiteDemandee: 25),
          Commande(id: 302, article: sprite, quantiteDemandee: 10),
          Commande(id: 303, article: choco, quantiteDemandee: 6),
        ],
      ),
      Journal(
        id: 29,
        reference: 'ENT-2610-014',
        type: TypeJournal.entree,
        statut: 'EN COURS',
        date: dans(0),
        tiers: 'Sofia Distribution',
        receptions: [
          DetailReception(
            article: coca33,
            quantite: 30,
            dlc: dans(200),
            dlv: dans(180),
          ),
          DetailReception(
            article: fanta,
            quantite: 18,
            dlc: dans(190),
            dlv: dans(170),
          ),
        ],
      ),
      Journal(
        id: 28,
        reference: 'ENT-2610-013',
        type: TypeJournal.entree,
        statut: 'MODIFIE',
        date: dans(-1),
        tiers: 'Candia Madagascar',
        receptions: [
          DetailReception(
            article: lait,
            quantite: 40,
            dlc: dans(90),
            dlv: dans(70),
          ),
        ],
      ),
      Journal(
        id: 27,
        reference: 'SOR-2610-029',
        type: TypeJournal.sortie,
        statut: 'CLOTURE',
        date: dans(-1),
        tiers: 'Leader Price Tanjombato',
        commandes: [
          Commande(id: 291, article: coca1, quantiteDemandee: 12),
          Commande(id: 292, article: spaghetti, quantiteDemandee: 8),
        ],
      ),
      Journal(
        id: 26,
        reference: 'ENT-2610-012',
        type: TypeJournal.entree,
        statut: 'AFFECTEE',
        date: dans(-2),
        tiers: 'Panzani Import',
        receptions: [
          DetailReception(
            article: penne,
            quantite: 34,
            dlc: dans(400),
            dlv: dans(380),
          ),
          DetailReception(
            article: spaghetti,
            quantite: 26,
            dlc: dans(380),
            dlv: dans(360),
          ),
        ],
      ),
      Journal(
        id: 25,
        reference: 'SOR-2610-028',
        type: TypeJournal.sortie,
        statut: 'CLOTURE',
        date: dans(-3),
        tiers: 'Jumbo Score Tanjombato',
        commandes: [Commande(id: 281, article: lait, quantiteDemandee: 30)],
      ),
      Journal(
        id: 24,
        reference: 'ENT-2610-011',
        type: TypeJournal.entree,
        statut: 'VALIDE',
        date: dans(-4),
        tiers: 'Sofia Distribution',
        receptions: [
          DetailReception(
            article: sprite,
            quantite: 30,
            dlc: dans(150),
            dlv: dans(130),
          ),
        ],
      ),
      Journal(
        id: 23,
        reference: 'INV-2610-004',
        type: TypeJournal.inventaire,
        statut: 'EN COURS',
        date: dans(0),
        tiers: 'Inventaire tournant d’octobre',
      ),
      Journal(
        id: 22,
        reference: 'INV-2609-003',
        type: TypeJournal.inventaire,
        statut: 'VALIDE',
        date: dans(-21),
        tiers: 'Inventaire mensuel',
      ),
    ]);

    // Historique des mouvements sur trois mois (fiche produit).
    var graine = 7;
    int hasard(int max) {
      graine = (graine * 1103515245 + 12345) & 0x7fffffff;
      return graine % max;
    }

    for (final produit in articles) {
      for (var jour = 88; jour > 0; jour -= 3 + hasard(6)) {
        // Peu de grosses entrees, beaucoup de petites sorties : les deux
        // s'equilibrent a peu pres sur la periode.
        final entree = hasard(10) < 3;
        final date = dans(-jour);
        // Meme format que les journaux (TYPE-AAMM-numero), numero croissant.
        final mois =
            '${(date.year % 100).toString().padLeft(2, '0')}'
            '${date.month.toString().padLeft(2, '0')}';
        final numero = entree
            ? (10 - jour ~/ 9).clamp(1, 10)
            : (27 - jour ~/ 4).clamp(1, 27);
        mouvements.add(
          Mouvement(
            article: produit,
            date: date,
            entree: entree,
            pieces:
                (entree ? 20 + hasard(30) : 6 + hasard(16)) *
                produit.piecesParUnite,
            reference:
                '${entree ? 'ENT' : 'SOR'}-$mois-'
                '${numero.toString().padLeft(3, '0')}',
          ),
        );
      }
    }

    activites.addAll([
      Activite(
        date: aujourdhui.subtract(const Duration(minutes: 18)),
        type: TypeActivite.reception,
        titre: fanta.titre,
        detail: '18 packs reçus · ENT-2610-014',
      ),
      Activite(
        date: aujourdhui.subtract(const Duration(minutes: 42)),
        type: TypeActivite.reception,
        titre: coca33.titre,
        detail: '30 packs reçus · ENT-2610-014',
      ),
      Activite(
        date: aujourdhui.subtract(const Duration(hours: 3)),
        type: TypeActivite.prelevement,
        titre: coca1.titre,
        detail: '12 packs · A13',
      ),
    ]);
  }
}

/// Instance unique de la simulation.
final magasin = Magasin();
