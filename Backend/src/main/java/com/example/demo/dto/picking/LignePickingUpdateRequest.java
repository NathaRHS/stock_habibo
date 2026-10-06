package com.example.demo.dto.picking;

import com.example.demo.entity.StatutLignePickingCode;

public record LignePickingUpdateRequest(
        Long commandeId,
        Long emplacementId,
        Long detailJournalSourceId,
        Long articleConditionnementId,
        Integer ordrePassage,
        Integer quantiteConditionnementsAPrelever,
        StatutLignePickingCode statut) {
}
