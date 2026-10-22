package com.example.demo.dto.emplacement;

import java.util.List;

public record EmplacementRequestAll(
        String name,
        Integer nombreEtages,
        List<EmplacementNouveau> emplacements
) {
}
