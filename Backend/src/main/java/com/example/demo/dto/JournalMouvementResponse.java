package com.example.demo.dto;

import java.util.List;

public record JournalMouvementResponse(
        Long id,
        String reference,
        String urlPieceJointe,
        String nomClient,
        Long fournisseurId,
        String fournisseur,
        Long typeMouvementJournalId,
        String typeMouvementJournal,
        Short sens,
        Long statutJournalMouvementId,
        String statut,
        List<DetailJournalResponse> details
) {
}
