package com.example.demo.dto.optimisation;

import java.math.BigDecimal;

public record ParametreSuggestionResponse(
        String cle,
        BigDecimal valeur,
        String description
) {
}
