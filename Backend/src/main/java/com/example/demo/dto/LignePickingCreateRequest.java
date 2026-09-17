package com.example.demo.dto;

import java.time.LocalDate;

public record LignePickingCreateRequest(
        Long pickingId,
        Long commandeId,
        Long emplacementId,
        LocalDate dlc,
        LocalDate dlv,
        Long articleConditionnementId,
        Integer ordrePassage,
        Integer quantiteConditionnementsAPrelever) {
}
