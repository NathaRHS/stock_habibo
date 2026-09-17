package com.example.demo.dto;

import java.time.LocalDate;

public record AjoutCommandeRequest(Long idJournal, Long CommandeId, Long EmplacementId, Long ArticleId,
        Integer quantiteConditionnement, String remarque, boolean isChecked, String matricule, Long id, LocalDate dlc,
        LocalDate dlv) {

}
