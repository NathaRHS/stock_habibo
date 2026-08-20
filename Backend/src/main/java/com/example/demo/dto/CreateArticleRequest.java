package com.example.demo.dto;

public record CreateArticleRequest(
        String nomArticle,
        String codeBar,
        Long typeProduitId,
        Long typeConditionnementId
) {
}
