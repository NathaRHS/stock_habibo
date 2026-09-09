package com.example.demo.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record PrelevementResponse(
        Long prelevementId,
        Long commandeId,
        Long articleId,
        String nomArticle,
        Long emplacementId,
        String nomEmplacement,
        Integer nombreConditionnementsPreleves,
        Integer quantitePiecesPrelevees,
        String statut,
        LocalDateTime datePrelevement,
        LocalDate dlc,
        LocalDate dlv) {
}