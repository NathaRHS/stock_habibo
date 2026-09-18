package com.example.demo.dto.stock;

public record StockParEmplacementResponse(
        Long articleId,
        Long emplacementId,
        Long quantiteStock) {
}
