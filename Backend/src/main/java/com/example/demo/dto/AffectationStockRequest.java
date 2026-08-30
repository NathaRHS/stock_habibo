package com.example.demo.dto;

public record AffectationStockRequest(
        Long detailJournalId,
        Long emplacementId,
        Integer nombreConditionnements) {
}
