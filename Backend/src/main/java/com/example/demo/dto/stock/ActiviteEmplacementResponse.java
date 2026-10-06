package com.example.demo.dto.stock;

public record ActiviteEmplacementResponse(
        Long emplacementId,
        Long stockFin,
        Long variation,
        Long nbMouvements) {
}
