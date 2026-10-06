package com.example.demo.dto.picking;

import java.time.LocalDateTime;

import com.example.demo.entity.StatutPickingCode;

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
        StatutPickingCode statut,
        Integer nombreLignes) {
}
