package com.example.demo.dto.journal;

import java.time.LocalDate;

public record DetailJournalResponse(
         Long id,
        Long articleId,
        String nomArticle,
        Integer quantite,
        Long journalId,
        String reference,
        Integer quantiteConditionnement,
        LocalDate dlc,
        LocalDate dlv
        
){
}
