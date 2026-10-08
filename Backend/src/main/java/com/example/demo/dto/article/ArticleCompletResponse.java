package com.example.demo.dto.article;

public record ArticleCompletResponse(
        ArticleResponse article,
        ArticleConditionnementResponse conditionnement,
        PaletteConditionnementResponse palette) {
}
