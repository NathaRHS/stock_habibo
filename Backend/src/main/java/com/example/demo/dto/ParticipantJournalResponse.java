package com.example.demo.dto;

import java.time.LocalDateTime;

import com.example.demo.entity.StatutParticipation;

public record ParticipantJournalResponse(
        Long participationId,
        Long userId,
        String username,
        String matricule,
        StatutParticipation statut,
        LocalDateTime dateDebut,
        LocalDateTime dateFin) {
}
