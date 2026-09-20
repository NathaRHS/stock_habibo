package com.example.demo.dto.stock;

public record AffectationStockRequest(
        Long detailJournalId,
        Long emplacementId,
        Integer nombreConditionnements) {
}
