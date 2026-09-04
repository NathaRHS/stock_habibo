package com.example.demo.dto;

public record ScanInventaireRequest(
        String codeBarres,
        Long emplacementId,
        Long quantite
) {
}


/*

        codeBarres:3664083000103
        emplacementId:1
        quantite:150

*/