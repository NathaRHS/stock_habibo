package com.example.demo.dto.stock;

import java.time.LocalDateTime;

/**
 * Une ligne de la liste de base de l'entrepot. L'application en deduit le stock
 * par emplacement, les totaux d'un rack et le detail au clic.
 *
 * typeMouvement vaut SOLDE_INITIAL pour la ligne qui resume le stock d'un
 * (emplacement, article) avant la periode ; id et journalReference y sont vides.
 */
public record ActiviteEmplacementResponse(
        Long id,
        Long emplacementId,
        Long articleId,
        String nomArticle,
        LocalDateTime date,
        String typeMouvement,
        Long quantite,
        String journalReference,
        String matricule) {
}
