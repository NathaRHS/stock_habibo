package com.example.demo.dto;
import java.util.List;

import com.example.demo.entity.JournalMouvement;

public record DetailJournalResponse(
        Long id,
        Long articleId,
        String nomArticle,
        Integer quantite,
        Long journalId,
        String reference
        
){
}
