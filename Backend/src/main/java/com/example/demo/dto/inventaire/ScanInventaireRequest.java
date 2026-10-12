package com.example.demo.dto.inventaire;

public record ScanInventaireRequest(
        String codeBarres,
        Long emplacementId,
        Long quantite,
        Integer quantiteConditionnement
) {
}
