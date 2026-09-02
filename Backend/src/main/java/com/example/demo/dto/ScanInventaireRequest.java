package com.example.demo.dto;

public record ScanInventaireRequest(
        String codeBarres,
        Long emplacementId,
        Long quantite
) {
}