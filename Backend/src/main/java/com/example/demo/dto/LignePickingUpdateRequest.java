package com.example.demo.dto;

import com.example.demo.entity.StatutLignePicking;

public record LignePickingUpdateRequest(
        Long commandeId,
        Long emplacementId,
        Long detailJournalSourceId,
        Long articleConditionnementId,
        Integer ordrePassage,
        Integer quantiteConditionnementsAPrelever,
        StatutLignePicking statut) {
}
