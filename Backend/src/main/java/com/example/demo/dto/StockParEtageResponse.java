package com.example.demo.dto;

public record StockParEtageResponse(
        Long articleId,
        Long etageId,
        Long quantiteStock
) {
}
