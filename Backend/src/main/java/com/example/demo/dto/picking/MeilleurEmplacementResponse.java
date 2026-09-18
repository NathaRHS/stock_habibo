package com.example.demo.dto.picking;

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
        LocalDate dlc,
        LocalDate dlv,
        Integer ordre,
        Integer ordreEmplacement) {
}
