package com.example.demo.dto.journal;

public record DetailJournalRequest(
        Long articleId,
        Integer quantite
) {
}
