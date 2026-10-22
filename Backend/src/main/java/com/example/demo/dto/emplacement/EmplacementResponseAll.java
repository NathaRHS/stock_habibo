package com.example.demo.dto.emplacement;

import java.util.List;

public record EmplacementResponseAll(
        Long rackId,
        String nomRack,
        Integer nombreEtages,
        List<EmplacementResponse> emplacements
) {
}
