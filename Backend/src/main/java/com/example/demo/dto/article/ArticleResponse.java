package com.example.demo.dto.article;

import java.math.BigDecimal;

public record ArticleResponse(
        Long id,
        String codeBar,
        String nomArticle,
        Long typeProduitId,
        String typeProduit,
        String photoUrl,
        Long familleId,
        String nomFamille,
        BigDecimal contenanceValeur,
        Long uniteId,
        String nomUnite
) {
}
