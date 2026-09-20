package com.example.demo.dto.commande;

import java.util.List;

public record CommandeResponseAll(List<CommandeResponse> commandes) {
// commande.getJournalMouvement().getId(),commande.getArticle().getNomArticle(),commande.getArticle().getId(),commande.getRemarque(),commande.getQuantiteDemandee(),commande.getQuantiteReel(),commande.getUser().getMatricule(),commande.getEtat()    
}
