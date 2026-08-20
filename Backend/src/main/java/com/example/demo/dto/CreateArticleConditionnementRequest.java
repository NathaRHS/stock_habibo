package com.example.demo.dto;

public record CreateArticleConditionnementRequest(
        Long articleId,
        Long typeConditionnementId,
        String codeBarres,
        Integer quantitePieceStandard
) {
}
