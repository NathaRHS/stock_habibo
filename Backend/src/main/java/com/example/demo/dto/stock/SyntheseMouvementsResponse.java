package com.example.demo.dto.stock;

// La periode demandee et la periode precedente de meme duree, pour calculer les variations.
public record SyntheseMouvementsResponse(PeriodeSynthese courante, PeriodeSynthese precedente) {
}
