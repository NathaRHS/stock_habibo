package com.example.demo.dto.stock;

import java.time.LocalDateTime;

public record MouvementStockResponse(
        Long mouvementStockId,
        Long detailJournalId,
        Long emplacementId,
        Integer nombreConditionnements,
        Integer quantitePiecesReelle,
        LocalDateTime dateMouvement,
        boolean enReserve) {
}
