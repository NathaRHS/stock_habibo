package com.example.demo.dto;

public record CommandeResponse(Long idCommande,Long idJournal, Long idArticle,String nomArticle, Integer quantiteDemande) {
// commande.getJournalMouvement().getId(),commande.getArticle().getNomArticle(),commande.getArticle().getId(),commande.getRemarque(),commande.getQuantiteDemandee(),commande.getQuantiteReel(),commande.getUser().getMatricule(),commande.getEtat()    
}
