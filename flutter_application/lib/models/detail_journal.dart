class DetailJournal {
  const DetailJournal({
    required this.id,
    required this.articleId,
    required this.nomArticle,
    required this.quantite,
    required this.journalId,
    required this.reference,
    this.dlc,
    this.dlv,
  });

  final int id;
  final int articleId;
  final String nomArticle;
  final int quantite;
  final int journalId;
  final String reference;
  final String? dlc;
  final String? dlv;

  factory DetailJournal.fromJson(Map<String, dynamic> json) {
    return DetailJournal(
      id: (json['id'] as num).toInt(),
      articleId: (json['articleId'] as num).toInt(),
      nomArticle: json['nomArticle'] as String,
      quantite: (json['quantite'] as num).toInt(),
      journalId: (json['journalId'] as num).toInt(),
      reference: json['reference'] as String,
      dlc: json['dlc'] as String?,
      dlv: json['dlv'] as String?,
    );
  }
}
