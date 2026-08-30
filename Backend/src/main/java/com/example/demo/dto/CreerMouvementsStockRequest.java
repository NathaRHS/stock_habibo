package com.example.demo.dto;

import java.util.List;

public record CreerMouvementsStockRequest(
        List<AffectationStockRequest> affectations) {
}
