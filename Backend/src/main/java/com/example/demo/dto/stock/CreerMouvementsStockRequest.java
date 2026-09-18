package com.example.demo.dto.stock;

import java.util.List;

public record CreerMouvementsStockRequest(
        List<AffectationStockRequest> affectations) {
}
