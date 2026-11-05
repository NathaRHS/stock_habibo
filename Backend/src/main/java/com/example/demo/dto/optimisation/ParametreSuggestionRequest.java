package com.example.demo.dto.optimisation;

import java.math.BigDecimal;

public record ParametreSuggestionRequest(
        String cle,
        BigDecimal valeur
) {
}
