package com.example.demo.dto;

public record CreatePaletteConditionnementRequest(
        Long articleConditionnementId,
        Integer quantiteMaximale) {
}
