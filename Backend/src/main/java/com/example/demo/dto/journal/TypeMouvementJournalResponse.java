package com.example.demo.dto.journal;

public record TypeMouvementJournalResponse(
        Long id,
        String nomTypeMouvement,
        Short sens
) {
}
