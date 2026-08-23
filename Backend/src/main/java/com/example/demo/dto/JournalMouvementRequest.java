package com.example.demo.dto;

import java.util.List;

public record JournalMouvementRequest(
        String reference,
        String urlPieceJointe,
        String nomClient,
        Long fournisseurId,
        Long typeMouvementJournalId,
        Long statutJournalMouvementId
) {
}
