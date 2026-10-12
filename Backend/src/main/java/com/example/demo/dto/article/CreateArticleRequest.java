package com.example.demo.dto.article;

import java.math.BigDecimal;

public record CreateArticleRequest(
        String nomArticle,
        String codeBar,
        Long typeProduitId,
        Long typeConditionnementId,
        // Facultatifs : contenance d'une piece (valeur + unite), a donner ensemble.
        BigDecimal contenanceValeur,
        Long uniteId
) {
}
