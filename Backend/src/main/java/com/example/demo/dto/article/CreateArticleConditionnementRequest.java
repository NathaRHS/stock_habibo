package com.example.demo.dto.article;

public record CreateArticleConditionnementRequest(
        Long articleId,
        Long typeConditionnementId,
        String codeBarres,
        Integer quantitePieceStandard
) {
}
