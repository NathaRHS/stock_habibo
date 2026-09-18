package com.example.demo.dto.emplacement;

public record EmplacementRequest(
        String nomEmplacement,
        Long rackId,
        Integer numeroEtage
) {
}
