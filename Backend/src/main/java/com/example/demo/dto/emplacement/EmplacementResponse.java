package com.example.demo.dto.emplacement;

public record EmplacementResponse(
        Long id,
        String nomEmplacement,
        Long rackId,
        String nomRack,
        Integer numeroEtage,
        Integer ordreDansEtage
) {
}
