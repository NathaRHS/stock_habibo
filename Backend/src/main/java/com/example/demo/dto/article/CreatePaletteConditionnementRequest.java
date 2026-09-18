package com.example.demo.dto.article;

public record CreatePaletteConditionnementRequest(
        Long articleConditionnementId,
        Integer quantiteMaximale) {
}
