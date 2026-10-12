package com.example.demo.dto.article;

/**
 * Creation complete d'un article : identite, conditionnement et palette
 * envoyes ensemble, pour que tout soit cree ou rien.
 */
public record CreateArticleCompletRequest(
        ArticleInfo article,
        ConditionnementInfo conditionnement,
        PaletteInfo palette) {

    public record ArticleInfo(
            String nomArticle,
            String codeBar,
            Long typeProduitId,
            Long typeConditionnementId,
            // Facultatifs : contenance d'une piece (valeur + unite), a donner ensemble.
            java.math.BigDecimal contenanceValeur,
            Long uniteId) {
    }

    // L'article n'existe pas encore : son identifiant est ajoute par le service.
    public record ConditionnementInfo(
            Long typeConditionnementId,
            String codeBarres,
            Integer quantitePieceStandard) {
    }

    // Le conditionnement n'existe pas encore : son identifiant est ajoute par le service.
    public record PaletteInfo(
            Integer quantiteMaximale) {
    }
}
