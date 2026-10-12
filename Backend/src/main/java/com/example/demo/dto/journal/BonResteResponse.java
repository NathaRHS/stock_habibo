package com.example.demo.dto.journal;

/**
 * Le bon de reste cree a la validation d'une sortie : un seul bon regroupe tous
 * les produits qui n'ont pas pu etre servis.
 */
public record BonResteResponse(
        Long id,
        String reference,
        int nombreProduits) {
}
