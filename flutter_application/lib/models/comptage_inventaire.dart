class ComptageInventaire {
  const ComptageInventaire({
    required this.id,
    required this.detailJournalId,
    required this.articleId,
    required this.nomArticle,
    required this.emplacementId,
    required this.nomEmplacement,
    required this.quantiteComptee,
  });

  final int id;
  final int detailJournalId;
  final int articleId;
  final String nomArticle;
  final int emplacementId;
  final String nomEmplacement;
  final int quantiteComptee;

  factory ComptageInventaire.fromJson(Map<String, dynamic> json) {
    return ComptageInventaire(
      id: (json['comptageInventaireId'] as num).toInt(),
      detailJournalId: (json['detailJournalId'] as num).toInt(),
      articleId: (json['articleId'] as num).toInt(),
      nomArticle: json['nomArticle'] as String,
      emplacementId: (json['emplacementId'] as num).toInt(),
      nomEmplacement: json['nomEmplacement'] as String,
      quantiteComptee: (json['quantiteComptee'] as num).toInt(),
    );
  }
}

class EmplacementInventaire {
  const EmplacementInventaire({
    required this.id,
    required this.nomEmplacement,
    required this.nomRack,
    required this.numeroEtage,
  });

  final int id;
  final String nomEmplacement;
  final String nomRack;
  final int numeroEtage;

  factory EmplacementInventaire.fromJson(Map<String, dynamic> json) {
    return EmplacementInventaire(
      id: (json['id'] as num).toInt(),
      nomEmplacement: json['nomEmplacement'] as String,
      nomRack: json['nomRack'] as String,
      numeroEtage: (json['numeroEtage'] as num).toInt(),
    );
  }

  String get libelle => '$nomRack - $nomEmplacement - niveau $numeroEtage';
}

class StockInventaire {
  const StockInventaire({
    required this.articleId,
    required this.emplacementId,
    required this.quantiteStock,
  });

  final int articleId;
  final int emplacementId;
  final int quantiteStock;

  factory StockInventaire.fromJson(Map<String, dynamic> json) {
    return StockInventaire(
      articleId: (json['articleId'] as num).toInt(),
      emplacementId: (json['emplacementId'] as num).toInt(),
      quantiteStock: (json['quantiteStock'] as num).toInt(),
    );
  }
}

class ArticleInventaire {
  const ArticleInventaire({required this.id, required this.nomArticle});

  final int id;
  final String nomArticle;

  factory ArticleInventaire.fromJson(Map<String, dynamic> json) {
    return ArticleInventaire(
      id: (json['id'] as num).toInt(),
      nomArticle: json['nomArticle'] as String,
    );
  }
}
