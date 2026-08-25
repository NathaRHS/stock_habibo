package com.example.demo.dto;
public record DetailJournalResponse(
        Long id,
        Long articleId,
        String nomArticle,
        Integer quantite,
        Long journalId,
        String reference,
        Integer quantiteConditionnement
        
){
}
