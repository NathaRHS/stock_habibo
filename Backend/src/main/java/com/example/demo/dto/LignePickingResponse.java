package com.example.demo.dto;

import java.time.LocalDate;

import com.example.demo.entity.StatutLignePicking;

public record LignePickingResponse(
        Long id,
        Long pickingId,
        Long commandeId,
        String nomArticle,
        Long emplacementId,
        String nomEmplacement,
        LocalDate dlc,
        LocalDate dlv,
        Long articleConditionnementId,
        Integer ordrePassage,
        Integer quantiteConditionnementsAPrelever,
        Integer quantitePiecesAPrelever,
        StatutLignePicking statut) {
}
