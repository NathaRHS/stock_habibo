package com.example.demo.dto.stock;

// Totaux des mouvements d'une periode : pieces entrees, pieces sorties, nombre de lignes.
public record PeriodeSynthese(Long entrees, Long sorties, Long nombreMouvements) {
}
