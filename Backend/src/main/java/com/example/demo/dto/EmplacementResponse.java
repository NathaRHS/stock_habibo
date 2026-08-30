package com.example.demo.dto;

public record EmplacementResponse(
        Long id,
        String nomEmplacement,
        Long rackId,
        String nomRack,
        Integer numeroEtage
) {
}
