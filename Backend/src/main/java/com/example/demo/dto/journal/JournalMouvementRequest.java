package com.example.demo.dto.journal;

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
