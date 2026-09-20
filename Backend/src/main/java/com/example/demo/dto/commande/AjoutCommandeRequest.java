package com.example.demo.dto.commande;

import java.time.LocalDate;

//ajout d'une commande (insertion)
public record AjoutCommandeRequest(Long idJournal, Long CommandeId, Long EmplacementId, Long ArticleId,
        Integer quantiteConditionnement, String remarque, boolean isChecked, String matricule, Long id, LocalDate dlc,
        LocalDate dlv) {}