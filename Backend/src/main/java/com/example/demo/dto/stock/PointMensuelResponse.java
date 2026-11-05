package com.example.demo.dto.stock;

// Pieces entrees et sorties d'un mois (1 = janvier ... 12 = decembre).
public record PointMensuelResponse(Integer mois, Long entrees, Long sorties) {
}
