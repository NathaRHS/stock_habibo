package com.example.demo.projection;

public interface EmplacementCandidatProjection {

    Long getEmplacementId();

    String getNomEmplacement();

    Long getRackId();

    String getNomRack();

    Integer getOrdreRack();

    Integer getNumeroEtage();

    Integer getOrdreDansEtage();

    Long getArticlePresentId();

    Long getQuantitePiecesPresentes();

    Integer getQuantitePieceStandard();

    Integer getCapaciteMaxConditionnements();
}