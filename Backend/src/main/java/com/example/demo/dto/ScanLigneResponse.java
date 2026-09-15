package com.example.demo.dto;

public record ScanLigneResponse(
        Long prelevementId,
        Long lignePickingId,
        Integer quantiteScannee,
        Integer quantitePreleveeAuTotal,
        Integer quantiteRestante,
        boolean ligneTerminee) {
}