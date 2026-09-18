package com.example.demo.dto.inventaire;

import java.time.LocalDateTime;

public record ComptageInventaireResponse(
        Long comptageInventaireId,
        Long detailJournalId,
        Long articleId,
        String nomArticle,
        Long emplacementId,
        String nomEmplacement,
        Integer quantiteComptee,
        LocalDateTime dateComptage) {
}
