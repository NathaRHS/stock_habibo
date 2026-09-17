class LignePicking {
  const LignePicking({
    required this.id,
    required this.pickingId,
    required this.commandeId,
    required this.nomArticle,
    required this.emplacementId,
    required this.nomEmplacement,
    required this.dlc,
    required this.dlv,
    required this.articleConditionnementId,
    required this.ordrePassage,
    required this.quantiteConditionnementsAPrelever,
    required this.quantitePiecesAPrelever,
    required this.statut,
  });

  final int id;
  final int pickingId;
  final int commandeId;
  final String nomArticle;
  final int emplacementId;
  final String nomEmplacement;
  final DateTime dlc;
  final DateTime dlv;
  final int articleConditionnementId;
  final int ordrePassage;
  final int quantiteConditionnementsAPrelever;
  final int quantitePiecesAPrelever;
  final String statut;

  factory LignePicking.fromJson(Map<String, dynamic> json) {
    return LignePicking(
      id: (json['id'] as num).toInt(),
      pickingId: (json['pickingId'] as num).toInt(),
      commandeId: (json['commandeId'] as num).toInt(),
      nomArticle: json['nomArticle'] as String,
      emplacementId: (json['emplacementId'] as num).toInt(),
      nomEmplacement: json['nomEmplacement'] as String,
      dlc: DateTime.parse(json['dlc'] as String),
      dlv: DateTime.parse(json['dlv'] as String),
      articleConditionnementId: (json['articleConditionnementId'] as num)
          .toInt(),
      ordrePassage: (json['ordrePassage'] as num).toInt(),
      quantiteConditionnementsAPrelever:
          (json['quantiteConditionnementsAPrelever'] as num).toInt(),
      quantitePiecesAPrelever: (json['quantitePiecesAPrelever'] as num).toInt(),
      statut: json['statut'] as String,
    );
  }

  LignePicking copierAvec({String? statut}) {
    return LignePicking(
      id: id,
      pickingId: pickingId,
      commandeId: commandeId,
      nomArticle: nomArticle,
      emplacementId: emplacementId,
      nomEmplacement: nomEmplacement,
      dlc: dlc,
      dlv: dlv,
      articleConditionnementId: articleConditionnementId,
      ordrePassage: ordrePassage,
      quantiteConditionnementsAPrelever: quantiteConditionnementsAPrelever,
      quantitePiecesAPrelever: quantitePiecesAPrelever,
      statut: statut ?? this.statut,
    );
  }
}
