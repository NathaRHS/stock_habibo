package com.example.demo.dto;

public record ArticleConditionnementResponse(
        Long id,
        Long articleId,
        String nomArticle,
        Long typeConditionnementId,
        String nomConditionnement,
        String codeBarres,
        Integer quantitePieceStandard
) {
}
