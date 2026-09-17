package com.example.demo.dto;

import java.time.LocalDateTime;

public record JournalSortieResponse(
    Long id,
    String reference,
    LocalDateTime dateDebut,
    LocalDateTime dateFin,
    String statut
) {}