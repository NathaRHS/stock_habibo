package com.example.demo.dto.picking;

import java.time.LocalDate;

import com.example.demo.entity.StatutLignePickingCode;

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
        StatutLignePickingCode statut) {
}
