class JournalMouvement {
  const JournalMouvement({
    required this.id,
    required this.reference,
    required this.typeMouvementJournal,
    required this.sens,
    required this.statut,
    this.nombreProduits = 0,
    this.urlPieceJointe,
    this.nomClient,
    this.fournisseur,
  });

  final int id;
  final String reference;
  final String? urlPieceJointe;
  final String? nomClient;
  final String? fournisseur;
  final String typeMouvementJournal;
  final int sens;
  final String statut;
  final int nombreProduits;

  /// Type en majuscules, sans espaces autour : ENTREE, SORTIE, INVENTAIRE.
  String get type => typeMouvementJournal.trim().toUpperCase();

  /// Statut en majuscules, tirets bas remplacés par des espaces : EN COURS, VALIDE…
  String get statutNormalise =>
      statut.trim().toUpperCase().replaceAll('_', ' ');

  /// Une session ne s'ouvre que tant qu'elle est en cours ou à corriger.
  bool get estOuvrable =>
      statutNormalise == 'EN COURS' || statutNormalise == 'MODIFIE';

  bool get estValide =>
      statutNormalise == 'VALIDE' || statutNormalise == 'AFFECTEE';

  factory JournalMouvement.fromJson(Map<String, dynamic> json) {
    return JournalMouvement(
      id: (json['id'] as num).toInt(),
      reference: json['reference'] as String,
      urlPieceJointe: json['urlPieceJointe'] as String?,
      nomClient: json['nomClient'] as String?,
      fournisseur: json['fournisseur'] as String?,
      typeMouvementJournal: json['typeMouvementJournal'] as String,
      sens: (json['sens'] as num).toInt(),
      statut: json['statut'] as String,
      nombreProduits: (json['details'] as List?)?.length ?? 0,
    );
  }
}
