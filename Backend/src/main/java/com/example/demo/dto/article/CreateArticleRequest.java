package com.example.demo.dto.article;

public record CreateArticleRequest(
        String nomArticle,
        String codeBar,
        Long typeProduitId,
        Long typeConditionnementId
) {
}
