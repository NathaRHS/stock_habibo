class Commande {
  const Commande({
    required this.idCommande,
    required this.idJournal,
    required this.idArticle,
    required this.nomArticle,
    required this.quantiteDemande,
  });

  final int idCommande;
  final int idJournal;
  final int idArticle;
  final String nomArticle;
  final int quantiteDemande;

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      idCommande: (json['idCommande'] as num).toInt(),
      idJournal: (json['idJournal'] as num).toInt(),
      idArticle: (json['idArticle'] as num).toInt(),
      nomArticle: json['nomArticle'] as String,
      quantiteDemande: (json['quantiteDemande'] as num).toInt(),
    );
  }
}