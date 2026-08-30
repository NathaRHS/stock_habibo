package com.example.demo.dto;

public record PaletteConditionnementResponse(
        Long id,
        Long articleConditionnementId,
        Integer quantiteMaximale) {
}
