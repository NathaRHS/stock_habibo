package com.example.demo.dto.journaluser;

import java.time.LocalDateTime;

/**
 * Une ligne du journal d'activite, deja mise en forme pour l'affichage.
 * "utilisateur" sert a l'avatar, "texte" est la phrase complete.
 */
public record ActiviteResponse(
        Long id,
        Long userId,
        String utilisateur,
        String matricule,
        String type,
        String libelleType,
        String cibleType,
        Long cibleId,
        String details,
        String texte,
        LocalDateTime date) {
}
