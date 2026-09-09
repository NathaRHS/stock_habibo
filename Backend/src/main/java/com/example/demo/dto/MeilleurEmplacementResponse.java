package com.example.demo.dto;

import java.time.LocalDate;

public record MeilleurEmplacementResponse(
        Long emplacementId,
        String nomEmplacement,
        Long rackId,
        String nomRack,
        Integer numeroEtage,
        Long commandeId,
        Integer quantiteDisponible,
        Integer quantiteAPrelever,
        LocalDate dlc) {
}