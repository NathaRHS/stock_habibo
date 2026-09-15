package com.example.demo.dto;

import java.time.LocalDateTime;

import com.example.demo.entity.StatutPicking;

public record PickingResponse(
        Long id,
        Long journalId,
        String referenceJournal,
        Long userId,
        String matriculeUtilisateur,
        Long rackDepartId,
        String nomRackDepart,
        LocalDateTime dateGenerationPicking,
        LocalDateTime dateDebut,
        LocalDateTime dateFin,
        StatutPicking statut,
        Integer nombreLignes) {
}
